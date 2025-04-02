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
        "updated_at": datetime
    }

class User:
    """Schema for User collection in MongoDB"""
    schema = {
        "shop_id": str,  # References the shop this user belongs to
        "name": str,
        "email": str,
        "password": str,  # This will be hashed
        "role": str,  # "admin" or "seller"
        "designation": str,  # Only for sellers
        "seller_id": str,  # Only for sellers
        "created_at": datetime,
        "updated_at": datetime,
        "created_by": str  # Email of the admin who created this user
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
        "created_by": str  # Email of the user who created this product
    }

# These models are not used directly with Django's ORM
# We'll use PyMongo to interact with MongoDB