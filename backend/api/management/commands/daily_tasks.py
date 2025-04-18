from django.core.management.base import BaseCommand
from django.conf import settings
from datetime import datetime, timedelta
import pymongo
from pymongo import MongoClient
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class Command(BaseCommand):
    help = 'Perform daily tasks: delete invoices for regular shops, process premium shop billing, and send reminders'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            dest='dry_run',
            help='Run without making actual changes',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        # Connect to MongoDB
        client = MongoClient(settings.MONGODB_URI)
        db = client[settings.MONGODB_DB]
        
        # Collections
        shops_collection = db["shops"]
        invoices_collection = db["invoices"]
        users_collection = db["users"]
        branches_collection = db["branches"]
        
        # Current time in Bangladesh
        now = datetime.now()
        today_midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
        yesterday_midnight = today_midnight - timedelta(days=1)
        
        self.stdout.write(self.style.SUCCESS(f'Running daily tasks at {now.strftime("%Y-%m-%d %H:%M:%S")}'))
        
        # 1. Delete regular shop invoice records
        self._delete_regular_shop_invoices(shops_collection, invoices_collection, dry_run)
        
        # 2. Process premium shop billing
        self._process_premium_shop_billing(shops_collection, branches_collection, users_collection, dry_run)
        
        # 3. Send low balance reminders for premium shops
        self._send_low_balance_reminders(shops_collection, users_collection, dry_run)
        
        # 4. Downgrade expired premium shops
        self._downgrade_expired_premium_shops(shops_collection, dry_run)
        
        # 5. Delete data for long-expired premium shops (30 days after downgrade)
        self._delete_long_expired_premium_data(shops_collection, invoices_collection, dry_run)
        
        self.stdout.write(self.style.SUCCESS('Daily tasks completed successfully'))

    def _delete_regular_shop_invoices(self, shops_collection, invoices_collection, dry_run):
        """Delete all invoices from regular (non-premium) shops"""
        # Get all non-premium shop IDs
        regular_shops = list(shops_collection.find({"is_premium": {"$ne": True}}))
        regular_shop_ids = [shop["shop_id"] for shop in regular_shops]
        
        if not regular_shop_ids:
            self.stdout.write(self.style.WARNING('No regular shops found'))
            return
        
        # Count invoices to be deleted
        invoice_count = invoices_collection.count_documents({"shop_id": {"$in": regular_shop_ids}})
        
        self.stdout.write(f'Found {invoice_count} invoices from {len(regular_shop_ids)} regular shops to delete')
        
        if not dry_run and invoice_count > 0:
            # Delete invoices
            result = invoices_collection.delete_many({"shop_id": {"$in": regular_shop_ids}})
            self.stdout.write(self.style.SUCCESS(f'Deleted {result.deleted_count} invoices from regular shops'))
        elif invoice_count > 0:
            self.stdout.write(self.style.WARNING(f'[DRY RUN] Would delete {invoice_count} invoices from regular shops'))

    def _process_premium_shop_billing(self, shops_collection, branches_collection, users_collection, dry_run):
        """Process daily billing for premium shops"""
        # Get all premium shops
        premium_shops = list(shops_collection.find({"is_premium": True}))
        
        if not premium_shops:
            self.stdout.write(self.style.WARNING('No premium shops found'))
            return
        
        self.stdout.write(f'Processing billing for {len(premium_shops)} premium shops')
        
        for shop in premium_shops:
            shop_id = shop["shop_id"]
            shop_name = shop["name"]
            current_balance = shop.get("balance", 0)
            
            # Count branches (minimum 1)
            branch_count = branches_collection.count_documents({"shop_id": shop_id})
            branch_count = max(1, branch_count)
            
            # Daily rate: 5 BDT per branch
            daily_rate = 5.0 * branch_count
            
            # Calculate new balance after billing
            new_balance = current_balance - daily_rate
            
            # Update shop with new balance
            if not dry_run:
                shops_collection.update_one(
                    {"shop_id": shop_id},
                    {"$set": {
                        "balance": new_balance,
                        "updated_at": datetime.now()
                    }}
                )
                self.stdout.write(f'Billed shop "{shop_name}" ({shop_id}) {daily_rate} BDT for {branch_count} branches. New balance: {new_balance} BDT')
            else:
                self.stdout.write(f'[DRY RUN] Would bill shop "{shop_name}" ({shop_id}) {daily_rate} BDT for {branch_count} branches. New balance would be: {new_balance} BDT')
            
            # Check if balance is 0 or negative
            if new_balance <= 0 and not dry_run:
                # Downgrade shop to regular
                shops_collection.update_one(
                    {"shop_id": shop_id},
                    {"$set": {
                        "is_premium": False,
                        "premium_downgraded_at": datetime.now(),
                        "updated_at": datetime.now()
                    }}
                )
                
                # Send email to shop owner
                self._send_downgrade_notification(shop, users_collection)
                
                self.stdout.write(self.style.WARNING(f'Shop "{shop_name}" ({shop_id}) downgraded to regular due to insufficient balance'))
            elif new_balance <= 0:
                self.stdout.write(self.style.WARNING(f'[DRY RUN] Would downgrade shop "{shop_name}" ({shop_id}) to regular due to insufficient balance'))

    def _send_low_balance_reminders(self, shops_collection, users_collection, dry_run):
        """Send reminder emails to shops with low premium balance"""
        # Get premium shops with balance < 30 BDT
        low_balance_shops = list(shops_collection.find({
            "is_premium": True,
            "balance": {"$lt": 30}
        }))
        
        if not low_balance_shops:
            self.stdout.write('No shops with low balance found')
            return
        
        self.stdout.write(f'Found {len(low_balance_shops)} shops with low balance')
        
        for shop in low_balance_shops:
            shop_id = shop["shop_id"]
            shop_name = shop["name"]
            balance = shop.get("balance", 0)
            
            # Find shop owner
            owner = users_collection.find_one({
                "shop_id": shop_id,
                "role": "owner"
            })
            
            if not owner:
                self.stdout.write(self.style.WARNING(f'Could not find owner for shop "{shop_name}" ({shop_id})'))
                continue
            
            if not dry_run:
                # Send email reminder
                self._send_low_balance_email(shop, owner, balance)
                self.stdout.write(f'Sent low balance reminder to {owner["email"]} for shop "{shop_name}" (Balance: {balance} BDT)')
            else:
                self.stdout.write(f'[DRY RUN] Would send low balance reminder to {owner["email"]} for shop "{shop_name}" (Balance: {balance} BDT)')

    def _downgrade_expired_premium_shops(self, shops_collection, dry_run):
        """Downgrade premium shops with expired premium_until date"""
        now = datetime.now()
        
        # Get premium shops with expired premium_until date
        expired_shops = list(shops_collection.find({
            "is_premium": True,
            "premium_until": {"$lt": now}
        }))
        
        if not expired_shops:
            self.stdout.write('No shops with expired premium found')
            return
        
        self.stdout.write(f'Found {len(expired_shops)} shops with expired premium')
        
        for shop in expired_shops:
            shop_id = shop["shop_id"]
            shop_name = shop["name"]
            
            if not dry_run:
                # Downgrade shop to regular
                shops_collection.update_one(
                    {"shop_id": shop_id},
                    {"$set": {
                        "is_premium": False,
                        "premium_downgraded_at": now,
                        "updated_at": now
                    }}
                )
                self.stdout.write(f'Downgraded shop "{shop_name}" ({shop_id}) to regular due to expired premium')
            else:
                self.stdout.write(f'[DRY RUN] Would downgrade shop "{shop_name}" ({shop_id}) to regular due to expired premium')

    def _delete_long_expired_premium_data(self, shops_collection, invoices_collection, dry_run):
        """Delete data from shops that were downgraded from premium more than 30 days ago"""
        now = datetime.now()
        thirty_days_ago = now - timedelta(days=30)
        
        # Get shops that were downgraded more than 30 days ago
        long_expired_shops = list(shops_collection.find({
            "is_premium": False,
            "premium_downgraded_at": {"$lt": thirty_days_ago},
            "premium_downgraded_at": {"$ne": None}
        }))
        
        if not long_expired_shops:
            self.stdout.write('No shops with long-expired premium found')
            return
        
        self.stdout.write(f'Found {len(long_expired_shops)} shops with premium expired for more than 30 days')
        
        for shop in long_expired_shops:
            shop_id = shop["shop_id"]
            shop_name = shop["name"]
            
            # Count invoices to be deleted
            invoice_count = invoices_collection.count_documents({"shop_id": shop_id})
            
            if not dry_run:
                # Delete all invoices and other premium data
                if invoice_count > 0:
                    invoices_collection.delete_many({"shop_id": shop_id})
                
                # Reset premium downgrade date
                shops_collection.update_one(
                    {"shop_id": shop_id},
                    {"$set": {
                        "premium_downgraded_at": None,
                        "updated_at": now
                    }}
                )
                
                self.stdout.write(f'Deleted {invoice_count} invoices from formerly premium shop "{shop_name}" ({shop_id})')
            else:
                self.stdout.write(f'[DRY RUN] Would delete {invoice_count} invoices from formerly premium shop "{shop_name}" ({shop_id})')

    def _send_low_balance_email(self, shop, owner, balance):
        """Send low balance reminder email"""
        sender_email = "shoptrack.gnvox@gmail.com"
        receiver_email = owner["email"]
        
        # Create message container
        msg = MIMEMultipart()
        msg['From'] = sender_email
        msg['To'] = receiver_email
        msg['Subject'] = f"Low Balance Alert - ShopTrack Premium"
        
        # Email content
        body = f"""
        <html>
        <body>
            <h2>Low Balance Alert</h2>
            <p>Dear {owner["name"]},</p>
            <p>Your ShopTrack Premium shop <b>{shop["name"]}</b> (Shop ID: {shop["shop_id"]}) has a low balance.</p>
            <p><strong>Current Balance: {balance} BDT</strong></p>
            <p>Please recharge your account to continue enjoying Premium features. If your balance reaches 0, your shop will be downgraded to Regular and you may lose access to premium features and historical data.</p>
            <p>Thank you for using ShopTrack!</p>
            <p>Best regards,<br>ShopTrack Team</p>
        </body>
        </html>
        """
        
        # Attach HTML content
        msg.attach(MIMEText(body, 'html'))
        
        try:
            # Connect to Gmail SMTP server
            server = smtplib.SMTP('smtp.gmail.com', 587)
            server.starttls()
            
            # Login to sender email (You'll need app password if 2FA is enabled)
            server.login(sender_email, settings.EMAIL_PASSWORD)
            
            # Send email
            server.send_message(msg)
            
            # Close connection
            server.quit()
            return True
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error sending email: {e}"))
            return False

    def _send_downgrade_notification(self, shop, users_collection):
        """Send notification when shop is downgraded from premium"""
        # Find shop owner
        owner = users_collection.find_one({
            "shop_id": shop["shop_id"],
            "role": "owner"
        })
        
        if not owner:
            self.stdout.write(self.style.WARNING(f'Could not find owner for shop "{shop["name"]}" ({shop["shop_id"]})'))
            return False
        
        sender_email = "shoptrack.gnvox@gmail.com"
        receiver_email = owner["email"]
        
        # Create message container
        msg = MIMEMultipart()
        msg['From'] = sender_email
        msg['To'] = receiver_email
        msg['Subject'] = f"Premium Service Downgraded - ShopTrack"
        
        # Email content
        body = f"""
        <html>
        <body>
            <h2>Premium Service Downgraded</h2>
            <p>Dear {owner["name"]},</p>
            <p>Your ShopTrack Premium shop <b>{shop["name"]}</b> (Shop ID: {shop["shop_id"]}) has been downgraded to Regular due to insufficient balance.</p>
            <p>Your historical data will be preserved for 30 days. After that period, all historical data will be deleted.</p>
            <p>To restore Premium features and prevent data loss, please recharge your account as soon as possible.</p>
            <p>Thank you for using ShopTrack!</p>
            <p>Best regards,<br>ShopTrack Team</p>
        </body>
        </html>
        """
        
        # Attach HTML content
        msg.attach(MIMEText(body, 'html'))
        
        try:
            # Connect to Gmail SMTP server
            server = smtplib.SMTP('smtp.gmail.com', 587)
            server.starttls()
            
            # Login to sender email
            server.login(sender_email, settings.EMAIL_PASSWORD)
            
            # Send email
            server.send_message(msg)
            
            # Close connection
            server.quit()
            return True
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error sending email: {e}"))
            return False 