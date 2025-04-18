from django.db import models
from datetime import datetime

# These are not actual Django models, just schema representations
# The actual data will be stored in MongoDB

class Shop:
    """Schema for Shop collection in MongoDB"""
    schema = {
        "shop_id": str,  # Unique 8-digit ID
        "name": str,
        "address": str,
        "owner_name": str,
        "license_number": str,
        "created_at": datetime,
        "updated_at": datetime,
        "is_premium": bool,  # Whether this shop is premium
        "balance": float,  # Balance for premium shops
        "premium_until": datetime,  # When premium status expires
        "logo_url": str,  # URL to shop logo (for premium shops)
        "branches": list,  # List of branch details for premium shops
        "premium_downgraded_at": datetime,  # When the shop was downgraded from premium
    }

class User:
    """Schema for User collection in MongoDB"""
    schema = {
        "shop_id": str,  # References the shop this user belongs to
        "name": str,
        "email": str,
        "password": str,  # This will be hashed
        "role": str,  # "owner", "admin" or "seller"
        "designation": str,  # Only for sellers
        "seller_id": str,  # Only for sellers
        "created_at": datetime,
        "updated_at": datetime,
        "created_by": str,  # Email of the admin who created this user
        "branch_id": str,  # Branch ID (only for premium shops with branches)
        "email_verified": bool,  # Whether email is verified
        "otp": str,  # OTP for email verification
        "otp_expiry": datetime  # OTP expiry time
    }
    
class Product:
    """Schema for Product collection in MongoDB"""
    schema = {
        "shop_id": str,  # References the shop this product belongs to
        "name": str,
        "quantity": int,
        "buying_price": float,
        "selling_price": float,
        "created_at": datetime,
        "updated_at": datetime,
        "created_by": str,  # Email of the user who created this product
        "branch_id": str,  # Branch ID (for premium shops with branches)
        "price_history": list,  # List of historical prices
        "is_available": bool  # Whether the product is available
    }

class PremiumRecharge:
    """Schema for Premium Recharge Transactions in MongoDB"""
    schema = {
        "transaction_id": str,  # Unique transaction ID
        "amount": float,  # Recharge amount in BDT
        "created_at": datetime,
        "used": bool,  # Whether this transaction has been used
        "used_by_shop_id": str,  # Shop ID that used this transaction
        "used_at": datetime  # When this transaction was used
    }

class RechargeHistory:
    """Schema for Premium Shop Recharge History in MongoDB"""
    schema = {
        "shop_id": str,  # Shop ID that made the recharge
        "transaction_id": str,  # Transaction ID used
        "amount": float,  # Amount recharged
        "recharged_at": datetime,  # When the recharge was made
        "previous_balance": float,  # Previous balance before recharge
        "new_balance": float  # New balance after recharge
    }

class Branch:
    """Schema for Shop Branches in MongoDB (for premium shops)"""
    schema = {
        "branch_id": str,  # Unique branch ID
        "shop_id": str,  # Parent shop ID
        "name": str,  # Branch name
        "address": str,  # Branch address
        "manager_id": str,  # User ID of branch manager
        "created_at": datetime,
        "updated_at": datetime
    }

class ReturnedProduct:
    """Schema for Returned Products in MongoDB (for premium shops)"""
    schema = {
        "shop_id": str,  # Shop ID
        "branch_id": str,  # Branch ID if applicable
        "product_id": str,  # Product ID
        "invoice_id": str,  # Original invoice ID
        "quantity": int,  # Quantity returned
        "selling_price": float,  # Original selling price
        "return_reason": str,  # Reason for return
        "returned_at": datetime,  # When the product was returned
        "processed_by": str  # Email of user who processed the return
    }

# These models are not used directly with Django's ORM
# We'll use PyMongo to interact with MongoDB