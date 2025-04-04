# Add these imports at the top of your views.py file
from bson.objectid import ObjectId
from django.http import JsonResponse
from datetime import datetime
from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import hashlib
import jwt
import os
from django.conf import settings

# Import all necessary collections from db.py
from .db import (
    shops_collection, 
    users_collection, 
    products_collection, 
    generate_shop_id,
    invoices_collection,
    NextInvoiceNumberView,
    SaveInvoiceView,
    GenerateInvoiceView,
    PendingInvoicesView, 
    InvoiceHistoryView,
    InvoiceDetailView,
    SearchProductsView
)

# Import all necessary serializers
from .serializers import (
    ShopRegistrationSerializer,
    UserLoginSerializer,
    SalesPersonRegistrationSerializer,
    AdminRegistrationSerializer,
    ProductSerializer,
    UpdateProductPriceSerializer
)

# Secret key for JWT
JWT_SECRET = os.getenv('SECRET_KEY', '1XRG32NbM@nuva7022')

def hash_password(password):
    """Create a SHA-256 hash of the password"""
    return hashlib.sha256(password.encode()).hexdigest()



class ShopRegistrationView(APIView):
    def post(self, request):
        serializer = ShopRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            # Get validated data
            data = serializer.validated_data

            # Check if email already exists
            if users_collection.find_one({"email": data['email']}):
                return Response(
                    {"error": "Email already registered"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Generate unique shop ID
            shop_id = generate_shop_id()

            # Create shop document
            shop_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "address": data['address'],
                "owner_name": data['owner_name'],
                "license_number": data['license_number'],
                "created_at": datetime.now(),
                "updated_at": datetime.now()
            }
            shops_collection.insert_one(shop_data)

            # Create admin user for this shop
            user_data = {
                "shop_id": shop_id,
                "name": data['owner_name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "admin",
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": data['email'] # Self-created
            }
            users_collection.insert_one(user_data)

            return Response({
                "message": "Shop registered successfully",
                "shop_id": shop_id
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserLoginView(APIView):
    def post(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data

            # Find user by shop_id and email
            user = users_collection.find_one({
                "shop_id": data['shop_id'],
                "email": data['email']
            })

            if not user:
                return Response(
                    {"error": "Invalid shop ID or email"},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            # Check password
            if user['password'] != hash_password(data['password']):
                return Response(
                    {"error": "Invalid password"},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            # Get shop details
            shop = shops_collection.find_one({"shop_id": data['shop_id']})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Create JWT token (expires in 24 hours)
            payload = {
                "user_id": str(user['_id']),
                "email": user['email'],
                "shop_id": user['shop_id'],
                "role": user['role'],
                "exp": datetime.now().timestamp() + (24 * 60 * 60) # 24 hours
            }
            token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")

            return Response({
                "token": token,
                "user": {
                    "name": user['name'],
                    "email": user['email'],
                    "role": user['role'],
                    "shop_id": user['shop_id'],
                    "shop_name": shop['name']
                }
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SalesPersonRegistrationView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Check if user is admin
            if payload['role'] != 'admin':
                return Response(
                    {"error": "Only admins can register sales persons"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get shop_id from token
            shop_id = payload['shop_id']
            admin_email = payload['email']
        except jwt.ExpiredSignatureError:
            return Response(
                {"error": "Token expired"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except jwt.InvalidTokenError:
            return Response(
                {"error": "Invalid token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Validate request data
        serializer = SalesPersonRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data

            # Check if email already exists
            if users_collection.find_one({"email": data['email']}):
                return Response(
                    {"error": "Email already registered"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create sales person user
            user_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "seller",
                "designation": data['designation'],
                "seller_id": data['seller_id'],
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": admin_email
            }
            users_collection.insert_one(user_data)

            return Response({
                "message": "Sales person registered successfully"
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AdminRegistrationView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Check if user is admin
            if payload['role'] != 'admin':
                return Response(
                    {"error": "Only admins can register other admins"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get shop_id from token
            shop_id = payload['shop_id']
            admin_email = payload['email']
        except jwt.ExpiredSignatureError:
            return Response(
                {"error": "Token expired"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except jwt.InvalidTokenError:
            return Response(
                {"error": "Invalid token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Validate request data
        serializer = AdminRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data

            # Check if email already exists
            if users_collection.find_one({"email": data['email']}):
                return Response(
                    {"error": "Email already registered"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create admin user
            user_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "admin",
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": admin_email
            }
            users_collection.insert_one(user_data)

            return Response({
                "message": "Admin registered successfully"
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VerifyTokenView(APIView):
    def get(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            return Response({
                "valid": True,
                "user": {
                    "email": payload['email'],
                    "role": payload['role'],
                    "shop_id": payload['shop_id']
                }
            })
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response({"valid": False})

class ProductView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Validate request data
        serializer = ProductSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data

            # Check if product already exists in this shop
            existing_product = products_collection.find_one({
                "shop_id": shop_id,
                "name": data['name']
            })

            if existing_product:
                # Update existing product
                products_collection.update_one(
                    {"_id": existing_product['_id']},
                    {"$set": {
                        "quantity": existing_product['quantity'] + data['quantity'],
                        "buying_price": data['buying_price'],
                        "selling_price": data['selling_price'],
                        "updated_at": datetime.now()
                    }}
                )

                return Response({
                    "message": "Product updated successfully",
                    "product_id": str(existing_product['_id'])
                }, status=status.HTTP_200_OK)
            else:
                # Create new product
                product_data = {
                    "shop_id": shop_id,
                    "name": data['name'],
                    "quantity": data['quantity'],
                    "buying_price": data['buying_price'],
                    "selling_price": data['selling_price'],
                    "created_at": datetime.now(),
                    "updated_at": datetime.now(),
                    "created_by": user_email
                }

                result = products_collection.insert_one(product_data)

                return Response({
                    "message": "Product added successfully",
                    "product_id": str(result.inserted_id)
                }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def get(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Get all products for this shop
        products = list(products_collection.find({"shop_id": shop_id}))

        # Convert ObjectId to string for JSON serialization
        for product in products:
            product['_id'] = str(product['_id'])

        return Response(products)

class UpdateProductPriceView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Check if user is admin
            if payload['role'] != 'admin':
                return Response(
                    {"error": "Only admins can update product prices"},
                    status=status.HTTP_403_FORBIDDEN
                )
            shop_id = payload['shop_id']
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Validate request data
        serializer = UpdateProductPriceSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data

            from bson.objectid import ObjectId
            # Update product price
            result = products_collection.update_one(
                {"_id": ObjectId(data['product_id']), "shop_id": shop_id},
                {"$set": {
                    "selling_price": data['selling_price'],
                    "updated_at": datetime.now()
                }}
            )

            if result.modified_count == 0:
                return Response(
                    {"error": "Product not found or not updated"},
                    status=status.HTTP_404_NOT_FOUND
                )

            return Response({
                "message": "Product price updated successfully"
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProductPriceListView(APIView):
    def get(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Get shop details
        shop = shops_collection.find_one({"shop_id": shop_id})
        if not shop:
            return Response(
                {"error": "Shop not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get all products for this shop with only needed fields
        products = list(products_collection.find(
            {"shop_id": shop_id},
            {"name": 1, "selling_price": 1, "quantity": 1}
        ))

        # Convert ObjectId to string for JSON serialization
        for product in products:
            product['_id'] = str(product['_id'])

        # Add shop information
        result = {
            "shop_name": shop['name'],
            "shop_address": shop['address'],
            "shop_id": shop_id,
            "products": products,
            "generated_at": datetime.now().isoformat()
        }

        return Response(result)