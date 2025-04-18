from django.core.management.base import BaseCommand
from django.conf import settings
from datetime import datetime
import pymongo
from pymongo import MongoClient
import random
import string

class Command(BaseCommand):
    help = 'Add a new premium recharge transaction'

    def add_arguments(self, parser):
        parser.add_argument('amount', type=float, help='Amount to recharge in BDT')
        
        # Optional transaction ID (will be generated if not provided)
        parser.add_argument(
            '--txn-id',
            dest='transaction_id',
            help='Specify a transaction ID (will be generated if not provided)'
        )

    def handle(self, *args, **options):
        amount = options['amount']
        transaction_id = options['transaction_id']
        
        # Generate a transaction ID if not provided
        if not transaction_id:
            # Generate a random 12-character transaction ID
            transaction_id = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))
        
        # Connect to MongoDB
        client = MongoClient(settings.MONGODB_URI)
        db = client[settings.MONGODB_DB]
        
        # Get premium_recharges collection
        premium_recharges_collection = db["premium_recharges"]
        
        # Check if transaction ID already exists
        existing_transaction = premium_recharges_collection.find_one({"transaction_id": transaction_id})
        if existing_transaction:
            self.stdout.write(self.style.ERROR(f'Transaction ID {transaction_id} already exists'))
            return
        
        # Create new transaction
        transaction = {
            "transaction_id": transaction_id,
            "amount": amount,
            "created_at": datetime.now(),
            "used": False,
            "used_by_shop_id": None,
            "used_at": None
        }
        
        # Insert transaction
        result = premium_recharges_collection.insert_one(transaction)
        
        if result.inserted_id:
            self.stdout.write(self.style.SUCCESS(f'Successfully added premium transaction:'))
            self.stdout.write(f'Transaction ID: {transaction_id}')
            self.stdout.write(f'Amount: {amount} BDT')
            self.stdout.write(f'Created at: {transaction["created_at"].strftime("%Y-%m-%d %H:%M:%S")}')
            self.stdout.write(f'Used: {transaction["used"]}')
        else:
            self.stdout.write(self.style.ERROR(f'Failed to add premium transaction')) 