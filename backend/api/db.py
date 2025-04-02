# api/db.py
import pymongo
from django.conf import settings
import random
import string

# MongoDB connection
client = pymongo.MongoClient(settings.MONGODB_URI)
db = client[settings.MONGODB_DB]

# Collections
shops_collection = db["shops"]
users_collection = db["users"]
products_collection = db["products"]

def generate_shop_id():
    """Generate a unique 8-digit shop ID"""
    while True:
        # Generate random 8-digit number
        shop_id = ''.join(random.choices(string.digits, k=8))
        
        # Check if it already exists
        if not shops_collection.find_one({"shop_id": shop_id}):
            return shop_id