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
import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from datetime import datetime, timedelta


# Import all necessary collections from db.py
from .db import (
    shops_collection,
    users_collection,
    products_collection,
    generate_shop_id,
    invoices_collection,
    otp_collection,
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
    UpdateProductPriceSerializer,
    SendOTPSerializer,
    VerifyOTPSerializer
)


# Secret key for JWT
JWT_SECRET = os.getenv('SECRET_KEY', '1XRG32NbM@nuva7022')

# Email settings - replace with your actual email configuration
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', 587))
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', 'your-email@gmail.com')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', 'your-app-password')
EMAIL_USE_TLS = True


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
            email = data['email']
            
            # Check if email already exists
            if users_collection.find_one({"email": email}):
                return Response(
                    {"error": "Email already registered"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if test_mode is enabled to bypass OTP verification
            test_mode = request.data.get('test_mode', False)
            
            # Check if OTP was verified (unless in test mode)
            if not test_mode:
                otp_record = otp_collection.find_one({"email": email})
                if not otp_record or not otp_record.get("verified", False):
                    return Response(
                        {"error": "Email not verified. Please verify your email with OTP first."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            else:
                print(f"Test mode enabled for {email}. Bypassing OTP verification.")
                # Create a mock OTP record for test mode if needed
                otp_collection.update_one(
                    {"email": email},
                    {"$set": {
                        "otp": "123456",
                        "verified": True,
                        "created_at": datetime.now(),
                        "test_mode": True
                    }},
                    upsert=True
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
            
            # Add mobile number and NID if provided
            if 'mobile_number' in data:
                shop_data['mobile_number'] = data['mobile_number']
            if 'nid_number' in data:
                shop_data['nid_number'] = data['nid_number']
                
            shops_collection.insert_one(shop_data)

            # Create owner user for this shop (changed from admin to owner)
            user_data = {
                "shop_id": shop_id,
                "name": data['owner_name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "owner",  # Changed from "admin" to "owner"
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": data['email']  # Self-created
            }
            
            # Add mobile number and NID if provided
            if 'mobile_number' in data:
                user_data['mobile_number'] = data['mobile_number']
            if 'nid_number' in data:
                user_data['nid_number'] = data['nid_number']
                
            users_collection.insert_one(user_data)

            # Remove OTP record after successful registration
            otp_collection.delete_one({"email": email})

            return Response({
                "message": "Shop registered successfully",
                "shop_id": shop_id
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# Update this section in your views.py file
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
                        "shop_name": shop['name'],
                        "designation": user.get('designation', 'Not Assigned'),  # Add this line
                        "seller_id": user.get('seller_id', 'Not Assigned')       # Add this line
                    }
                })
            else:
                print("Validation errors:", serializer.errors)
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print("Login error:", str(e))
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)




# class UserLoginView(APIView):
#     def post(self, request):
#         try:
#             print("Login attempt received:", request.data)
#             serializer = UserLoginSerializer(data=request.data)
#             if serializer.is_valid():
#                 data = serializer.validated_data

#                 # Find user by shop_id and email
#                 user = users_collection.find_one({
#                     "shop_id": data['shop_id'],
#                     "email": data['email']
#                 })

#                 if not user:
#                     print(f"User not found for shop_id: {data['shop_id']}, email: {data['email']}")
#                     return Response(
#                         {"error": "Invalid shop ID or email"},
#                         status=status.HTTP_401_UNAUTHORIZED
#                     )

#                 # Check password
#                 if user['password'] != hash_password(data['password']):
#                     print("Invalid password")
#                     return Response(
#                         {"error": "Invalid password"},
#                         status=status.HTTP_401_UNAUTHORIZED
#                     )

#                 # Get shop details
#                 shop = shops_collection.find_one({"shop_id": data['shop_id']})
#                 if not shop:
#                     print(f"Shop not found for shop_id: {data['shop_id']}")
#                     return Response(
#                         {"error": "Shop not found"},
#                         status=status.HTTP_404_NOT_FOUND
#                     )

#                 # Create JWT token (expires in 24 hours)
#                 payload = {
#                     "user_id": str(user['_id']),
#                     "email": user['email'],
#                     "shop_id": user['shop_id'],
#                     "role": user['role'],
#                     "exp": datetime.now().timestamp() + (24 * 60 * 60) # 24 hours
#                 }
#                 token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")

#                 print("Login successful")
#                 return Response({
#                     "token": token,
#                     "user": {
#                         "name": user['name'],
#                         "email": user['email'],
#                         "role": user['role'],
#                         "shop_id": user['shop_id'],
#                         "shop_name": shop['name'],

#                         "designation": user.get('designation', 'Not Assigned'),  # Add this line
#                         "seller_id": user.get('seller_id', 'Not Assigned')    
#                     }
#                 })
#             else:
#                 print("Validation errors:", serializer.errors)
#                 return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
#         except Exception as e:
#             print("Login error:", str(e))
#             return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ShopUsersView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if user belongs to this shop and is owner
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            user_role = payload.get('role', '')
            if user_role != 'owner':
                return Response(
                    {"error": "Only shop owners can view all users"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Get all users for this shop
            shop_users = list(users_collection.find({"shop_id": shop_id}))
            
            # Convert ObjectId to string for JSON serialization
            for user in shop_users:
                user['_id'] = str(user['_id'])
                # Remove password for security
                if 'password' in user:
                    del user['password']
                
            return Response(shop_users)
            
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
            user_role = payload.get('role', '')
            
            # Only owners can delete users
            if user_role != 'owner':
                return Response(
                    {"error": "Only shop owners can delete users"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Get the user to be deleted
            user_to_delete = users_collection.find_one({"_id": ObjectId(user_id)})
            
            if not user_to_delete:
                return Response(
                    {"error": "User not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
                
            # Check if the user belongs to the same shop as the owner
            if user_to_delete['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            # Check if trying to delete an owner
            if user_to_delete.get('role') == 'owner':
                return Response(
                    {"error": "Cannot delete shop owner"},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            # Delete the user
            result = users_collection.delete_one({"_id": ObjectId(user_id)})
            
            if result.deleted_count == 0:
                return Response(
                    {"error": "Failed to delete user"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            return Response({
                "message": "User deleted successfully"
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )




class SalesPersonRegistrationView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if user is admin or owner (updated to include owner)
            # if payload['role'] not in ['admin', 'owner']:
            #     return Response(
            #         {"error": "Only admins and owners can register sales persons"},
            #         status=status.HTTP_403_FORBIDDEN
            #     )
            
            # In SalesPersonRegistrationView in views.py
            # Check if user is admin or owner (updated to include owner)
            if payload['role'] not in ['admin', 'owner']:
                return Response(
                    {"error": "Only admins and owners can register sales persons"},
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
        
        # Rest of the function remains the same...




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
            if role != 'admin':
                return Response(
                    {"error": "Only admins can delete invoices"},
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
            if role != 'admin':
                return Response(
                    {"error": "Only admins can delete products"},
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
            
            # Check if user is admin or owner (updated to include owner)
            if payload['role'] not in ['admin', 'owner']:
                return Response(
                    {"error": "Only admins and owners can register other admins"},
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
        
        # Rest of the function remains the same...






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




class PublicInvoiceView(APIView):
    def get(self, request):
        # Get query parameters
        shop_id = request.GET.get('shop_id')
        invoice_number = request.GET.get('invoice_number')
        
        # Validate parameters
        if not shop_id or not invoice_number:
            return Response(
                {"error": "Shop ID and Invoice Number are required"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            # Find the invoice
            invoice = invoices_collection.find_one({
                "shop_id": shop_id,
                "invoice_number": invoice_number,
                "status": "completed"  # Only show completed invoices
            })
            
            if not invoice:
                return Response(
                    {"error": "Invoice not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
                
            # Convert ObjectId to string for JSON serialization
            invoice['_id'] = str(invoice['_id'])
            
            # Return the invoice data
            return Response(invoice)
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

def generate_otp():
    """Generate a 6-digit OTP"""
    return ''.join(random.choices(string.digits, k=6))

def send_email_otp(email, otp):
    """Send OTP via email"""
    try:
        msg = MIMEMultipart()
        msg['From'] = EMAIL_HOST_USER
        msg['To'] = email
        msg['Subject'] = 'ShopTrack - OTP Verification'
        
        body = f"""
        <html>
        <body>
            <h3>ShopTrack Verification Code</h3>
            <p>Your OTP verification code is: <strong>{otp}</strong></p>
            <p>This code will expire in 15 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
            <p>Thank you,<br>
            ShopTrack Team</p>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(body, 'html'))
        
        server = smtplib.SMTP(EMAIL_HOST, EMAIL_PORT)
        server.starttls()
        server.login(EMAIL_HOST_USER, EMAIL_HOST_PASSWORD)
        server.send_message(msg)
        server.quit()
        
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False

class SendOTPView(APIView):
    def post(self, request):
        """Generate and send OTP via email"""
        serializer = SendOTPSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            mobile_number = serializer.validated_data.get('mobile_number')
            
            # Check if the email exists
            if users_collection.find_one({"email": email}):
                return Response(
                    {"error": "Email already registered. Please login instead."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Generate OTP
            otp = generate_otp()
            
            # Store OTP in database (replace if exists)
            otp_data = {
                "otp": otp,
                "verified": False,
                "created_at": datetime.now(),
            }
            
            # Add mobile number if provided
            if mobile_number:
                otp_data["mobile_number"] = mobile_number
                
            otp_collection.update_one(
                {"email": email},
                {"$set": otp_data},
                upsert=True
            )
            
            # Send OTP via email
            if not send_email_otp(email, otp):
                return Response(
                    {"error": "Failed to send OTP. Please try again later."},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            
            return Response({"message": "OTP sent successfully"})
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VerifyOTPView(APIView):
    def post(self, request):
        """Verify OTP and mark as verified"""
        serializer = VerifyOTPSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            otp = serializer.validated_data['otp']
            
            # Find OTP record
            otp_record = otp_collection.find_one({"email": email})
            
            if not otp_record:
                return Response(
                    {"error": "No OTP found for this email. Please request a new OTP."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if OTP is expired (it should be auto-removed by TTL index,
            # but double check in case of database delays)
            otp_time = otp_record.get("created_at")
            if otp_time and (datetime.now() - otp_time).total_seconds() > 900:  # 15 minutes
                return Response(
                    {"error": "OTP expired. Please request a new OTP."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if OTP matches
            if otp_record.get("otp") != otp:
                return Response(
                    {"error": "Invalid OTP. Please try again."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Mark OTP as verified
            otp_collection.update_one(
                {"email": email},
                {"$set": {"verified": True}}
            )
            
            return Response({"message": "OTP verified successfully"})
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)