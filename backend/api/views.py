# Add these imports at the top of your views.py file
from bson.objectid import ObjectId
from django.http import JsonResponse
from datetime import datetime, date
from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import hashlib
import jwt
import os
import base64
import uuid
from django.conf import settings
import json
import random
import string
import re

from datetime import datetime, timedelta


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

# Directory for storing uploaded images
UPLOAD_DIR = os.path.join(settings.BASE_DIR, 'uploads')
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

def save_image(image):
    """Save an uploaded image and return its URL"""
    if not image:
        return None
        
    # Create unique filename
    ext = image.name.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    
    # Save file
    filepath = os.path.join(UPLOAD_DIR, filename)
    with open(filepath, 'wb+') as destination:
        for chunk in image.chunks():
            destination.write(chunk)
    
    # Return relative URL
    return f"/uploads/{filename}"

def save_base64_image(base64_string):
    """Save a base64 encoded image and return its URL"""
    if not base64_string:
        return None
    
    try:
        # Extract the base64 data
        if ',' in base64_string:
            format_data, base64_data = base64_string.split(',', 1)
        else:
            base64_data = base64_string
            
        # Determine file extension from the header
        file_ext = 'jpg'  # Default to jpg
        if 'image/png' in base64_string:
            file_ext = 'png'
        elif 'image/gif' in base64_string:
            file_ext = 'gif'
            
        # Create unique filename
        filename = f"{uuid.uuid4()}.{file_ext}"
        
        # Convert base64 to binary
        image_data = base64.b64decode(base64_data)
        
        # Save the file
        filepath = os.path.join(UPLOAD_DIR, filename)
        with open(filepath, 'wb') as f:
            f.write(image_data)
            
        # Return relative URL
        return f"/uploads/{filename}"
    except Exception as e:
        print(f"Error saving base64 image: {e}")
        return None

def hash_password(password):
    """Create a SHA-256 hash of the password"""
    return hashlib.sha256(password.encode()).hexdigest()


# Simple test endpoint to verify API connectivity
def test_api_view(request):
    """Simple test endpoint to verify API connectivity"""
    return JsonResponse({
        "status": "success",
        "message": "API is working!",
        "request_path": request.path,
        "app_info": "ShopTrack Backend API"
    })


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
                "owner_phone": data['owner_phone'],
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
                "role": "owner",
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
        try:
            print("Login attempt received:", request.data)
            serializer = UserLoginSerializer(data=request.data)
            if serializer.is_valid():
                data = serializer.validated_data

                # Find user by shop_id and email
                user = users_collection.find_one({
                    "shop_id": data['shop_id'],
                    "email": data['email']
                })

                if not user:
                    print(f"User not found for shop_id: {data['shop_id']}, email: {data['email']}")
                    return Response(
                        {"error": "Invalid shop ID or email"},
                        status=status.HTTP_401_UNAUTHORIZED
                    )

                # Check password
                if user['password'] != hash_password(data['password']):
                    print("Invalid password")
                    return Response(
                        {"error": "Invalid password"},
                        status=status.HTTP_401_UNAUTHORIZED
                    )

                # Get shop details
                shop = shops_collection.find_one({"shop_id": data['shop_id']})
                if not shop:
                    print(f"Shop not found for shop_id: {data['shop_id']}")
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

                print("Login successful")
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
            else:
                print("Validation errors:", serializer.errors)
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print("Login error:", str(e))
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SalesPersonRegistrationView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Check if user is manager or owner
            if payload['role'] != 'manager' and payload['role'] != 'owner':
                return Response(
                    {"error": "Only managers and owners can register sales persons"},
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
                
            # Handle image upload (from file or base64)
            image_url = None
            if 'image' in request.FILES:
                image_url = save_image(request.FILES['image'])
            elif 'image_base64' in request.data and request.data['image_base64']:
                image_url = save_base64_image(request.data['image_base64'])

            # Format date of birth
            date_of_birth = data['date_of_birth']
            if isinstance(date_of_birth, str):
                try:
                    date_of_birth = datetime.fromisoformat(date_of_birth.replace('Z', '+00:00'))
                except ValueError:
                    # Try more format options
                    try:
                        date_of_birth = datetime.strptime(date_of_birth, '%Y-%m-%d')
                    except ValueError:
                        pass
            # Convert date object to datetime object if needed
            elif isinstance(date_of_birth, date) and not isinstance(date_of_birth, datetime):
                date_of_birth = datetime.combine(date_of_birth, datetime.min.time())

            # Create sales person user
            user_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "seller",
                "designation": data['designation'],
                "employee_id": data['employee_id'],
                "image_url": image_url,
                "id_number": data['id_number'],
                "date_of_birth": date_of_birth,
                "address": data['address'],
                "phone_number": data['phone_number'],
                "salary": data['salary'],
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": admin_email
            }
            users_collection.insert_one(user_data)


            return Response({
                "message": "Sales person registered successfully"
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Add this class to your views.py file
class DeleteInvoiceView(APIView):
    def delete(self, request, invoice_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            role = payload.get('role', '')
            
            # Only admins can delete invoices
            if role != 'manager':
                return Response(
                    {"error": "Only managers can delete invoices"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Get the invoice
            invoice = invoices_collection.find_one({"_id": ObjectId(invoice_id)})
            
            if not invoice:
                return Response(
                    {"error": "Invoice not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
                
            # Check if the shop ID in the invoice matches the shop ID in the token
            if invoice['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            # Check if the invoice is already completed
            if invoice['status'] == 'completed':
                return Response(
                    {"error": "Cannot delete completed invoices"},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            # Delete the invoice
            result = invoices_collection.delete_one({"_id": ObjectId(invoice_id)})
            
            if result.deleted_count == 0:
                return Response(
                    {"error": "Failed to delete invoice"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            return Response({
                "message": "Invoice deleted successfully"
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class DeleteProductView(APIView):
    def delete(self, request, product_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            role = payload.get('role', '')
            
            # Only admins can delete products
            if role != 'manager':
                return Response(
                    {"error": "Only managers can delete products"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Get the product
            product = products_collection.find_one({"_id": ObjectId(product_id)})
            
            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
                
            # Check if the product belongs to this shop
            if product['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            # Delete the product
            result = products_collection.delete_one({"_id": ObjectId(product_id)})
            
            if result.deleted_count == 0:
                return Response(
                    {"error": "Failed to delete product"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            return Response({
                "message": "Product deleted successfully"
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TodayStatsView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if user belongs to this shop
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Get today's date range (start of today to now)
            today_start = datetime.combine(datetime.today(), datetime.min.time())
            now = datetime.now()
            
            # Query invoices generated today and are completed
            today_invoices = list(invoices_collection.find({
                "shop_id": shop_id,
                "status": "completed",
                "created_at": {"$gte": today_start, "$lte": now}
            }))
            
            # Calculate stats
            total_sales = len(today_invoices)
            # total_revenue = sum(invoice.get('total_amount', 0) for invoice in today_invoices)
            # In TodayStatsView class in views.py
            total_revenue = sum(invoice.get('total_amount', 0) for invoice in today_invoices)

            return Response({
                "total_sales": total_sales,
                "total_revenue": total_revenue,
                "date": today_start.strftime('%Y-%m-%d')
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class TodayInvoicesView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if user belongs to this shop
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Get today's date range (start of today to now)
            today_start = datetime.combine(datetime.today(), datetime.min.time())
            now = datetime.now()
            
            # Query invoices generated today and are completed
            today_invoices = list(invoices_collection.find({
                "shop_id": shop_id,
                "status": "completed",
                "created_at": {"$gte": today_start, "$lte": now}
            }).sort("created_at", -1))  # Sort by most recent first
            
            # Convert ObjectId to string for JSON serialization
            for invoice in today_invoices:
                invoice['_id'] = str(invoice['_id'])
            
            return Response(today_invoices)
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AdminRegistrationView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Check if user is admin or owner
            if payload['role'] != 'manager' and payload['role'] != 'owner':
                return Response(
                    {"error": "Only managers and owners can register other managers"},
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
                
            # Handle image upload (from file or base64)
            image_url = None
            if 'image' in request.FILES:
                image_url = save_image(request.FILES['image'])
            elif 'image_base64' in request.data and request.data['image_base64']:
                image_url = save_base64_image(request.data['image_base64'])
                
            # Format date of birth
            date_of_birth = data['date_of_birth']
            if isinstance(date_of_birth, str):
                try:
                    date_of_birth = datetime.fromisoformat(date_of_birth.replace('Z', '+00:00'))
                except ValueError:
                    # Try more format options
                    try:
                        date_of_birth = datetime.strptime(date_of_birth, '%Y-%m-%d')
                    except ValueError:
                        pass
            # Convert date object to datetime object if needed
            elif isinstance(date_of_birth, date) and not isinstance(date_of_birth, datetime):
                date_of_birth = datetime.combine(date_of_birth, datetime.min.time())

            # Create admin user
            user_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "manager",
                "designation": data['designation'],
                "employee_id": data['employee_id'],
                "image_url": image_url,
                "id_number": data['id_number'],
                "date_of_birth": date_of_birth,
                "address": data['address'],
                "phone_number": data['phone_number'],
                "salary": data['salary'],
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": admin_email
            }
            users_collection.insert_one(user_data)


            return Response({
                "message": "Manager registered successfully"
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
            if payload['role'] != 'manager':
                return Response(
                    {"error": "Only managers can update product prices"},
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


class ShopUsersView(APIView):
    def get(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            role = payload.get('role', '')
            
            # Only owners and admins can view all users
            if role not in ['owner', 'manager']:
                return Response(
                    {"error": "Only owners and managers can view all users"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        try:
            # Get all users for this shop
            users = list(users_collection.find({"shop_id": shop_id}))
            
            # Remove password and convert ObjectId to string
            for user in users:
                user['_id'] = str(user['_id'])
                if 'password' in user:
                    del user['password']
            
            return Response(users)
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class DeleteUserView(APIView):
    def delete(self, request, user_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            role = payload.get('role', '')
            user_email = payload['email']
            
            # Only owners can delete users
            if role != 'owner':
                return Response(
                    {"error": "Only owners can delete users"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        try:
            # Get the user to be deleted
            user = users_collection.find_one({"_id": ObjectId(user_id)})
            
            if not user:
                return Response(
                    {"error": "User not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
                
            # Check if the user belongs to this shop
            if user['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            # Prevent owners from being deleted
            if user['role'] == 'owner':
                return Response(
                    {"error": "Owners cannot be deleted"},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            # Delete the user
            result = users_collection.delete_one({"_id": ObjectId(user_id)})
            
            if result.deleted_count == 0:
                return Response(
                    {"error": "Failed to delete user"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            return Response({"message": "User deleted successfully"})
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# New API endpoints for user and shop information
class UserInfoView(APIView):
    def get(self, request, user_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return Response({"error": "Authorization token is required"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return Response({"error": "Token has expired"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({"error": "Invalid token"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        # Only allow access to own info or if admin/owner
        requesting_user = users_collection.find_one({"_id": ObjectId(payload["user_id"])})
        if not requesting_user:
            return Response({"error": "User not found"}, 
                           status=status.HTTP_404_NOT_FOUND)
            
        if requesting_user['role'] not in ['owner', 'manager'] and str(requesting_user['_id']) != user_id:
            return Response({"error": "You don't have permission to access this user's information"}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        # Get user info
        user_info = users_collection.find_one(
            {"_id": ObjectId(user_id)},
            {"additional_info": 1, "employee_id": 1, "email": 1, "name": 1, "role": 1}
        )
        
        if not user_info:
            return Response({"error": "User not found"}, 
                           status=status.HTTP_404_NOT_FOUND)
        
        # Combine default info with additional info
        result = user_info.get("additional_info", {})
        
        # Add core user fields
        if "employee_id" in user_info:
            result["userId"] = user_info["employee_id"]
        if "email" in user_info:
            result["email"] = user_info["email"]
        if "name" in user_info:
            result["name"] = user_info["name"]
        if "role" in user_info:
            result["designation"] = user_info["role"].upper()
        
        return Response(result)
    
    def post(self, request, user_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return Response({"error": "Authorization token is required"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return Response({"error": "Token has expired"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({"error": "Invalid token"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        # Only allow access to own info or if admin/owner
        requesting_user = users_collection.find_one({"_id": ObjectId(payload["user_id"])})
        if not requesting_user:
            return Response({"error": "User not found"}, 
                           status=status.HTTP_404_NOT_FOUND)
            
        if requesting_user['role'] not in ['owner', 'manager'] and str(requesting_user['_id']) != user_id:
            return Response({"error": "You don't have permission to update this user's information"}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        # Get data from request
        data = request.data
        
        # Update user additional info
        result = users_collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {"additional_info": data, "updated_at": datetime.now()}}
        )
        
        if result.matched_count == 0:
            return Response({"error": "User not found"}, 
                           status=status.HTTP_404_NOT_FOUND)
        
        return Response({"message": "User information updated successfully"}, 
                       status=status.HTTP_200_OK)


class ShopInfoView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return Response({"error": "Authorization token is required"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return Response({"error": "Token has expired"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({"error": "Invalid token"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        # Check if user belongs to the shop
        if payload["shop_id"] != shop_id:
            return Response({"error": "You don't have permission to access this shop's information"}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        # Get shop info
        shop_info = shops_collection.find_one(
            {"shop_id": shop_id},
            {"additional_info": 1, "name": 1, "address": 1, "created_at": 1}
        )
        
        if not shop_info:
            return Response({"error": "Shop not found"}, 
                           status=status.HTTP_404_NOT_FOUND)
        
        # Combine default info with additional info
        result = shop_info.get("additional_info", {})
        
        # Add core shop fields
        result["shopName"] = shop_info.get("name", "")
        result["shopAddress"] = shop_info.get("address", "")
        
        # Format registration date if available
        if "created_at" in shop_info and shop_info["created_at"]:
            try:
                result["registrationDate"] = shop_info["created_at"].strftime('%Y-%m-%d')
            except:
                pass
        
        return Response(result)
    
    def post(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return Response({"error": "Authorization token is required"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return Response({"error": "Token has expired"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({"error": "Invalid token"}, 
                           status=status.HTTP_401_UNAUTHORIZED)
        
        # Check if user belongs to the shop and has owner/manager permissions
        if payload["shop_id"] != shop_id:
            return Response({"error": "You don't have permission to update this shop's information"}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        # Only owner or manager can update shop info
        user = users_collection.find_one({"_id": ObjectId(payload["user_id"])})
        if not user or user['role'] not in ['owner', 'manager']:
            return Response({"error": "Only shop owners and managers can update shop information"}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        # Get data from request
        data = request.data
        
        # Update shop additional info
        result = shops_collection.update_one(
            {"shop_id": shop_id},
            {"$set": {"additional_info": data, "updated_at": datetime.now()}}
        )
        
        if result.matched_count == 0:
            return Response({"error": "Shop not found"}, 
                           status=status.HTTP_404_NOT_FOUND)
        
        return Response({"message": "Shop information updated successfully"}, 
                       status=status.HTTP_200_OK)