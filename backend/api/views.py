from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime
import hashlib
# import jwt
import jwt
import os
from django.conf import settings
from .db import shops_collection, users_collection, generate_shop_id

from .serializers import (
    ShopRegistrationSerializer, 
    UserLoginSerializer,
    SalesPersonRegistrationSerializer,
    AdminRegistrationSerializer
)
from .db import shops_collection, users_collection, generate_shop_id

# Secret key for JWT
# JWT_SECRET = os.getenv('SECRET_KEY', 'your-secret-key')
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
                "created_by": data['email']  # Self-created
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
                "exp": datetime.now().timestamp() + (24 * 60 * 60)  # 24 hours
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