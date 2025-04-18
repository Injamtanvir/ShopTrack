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
    premium_recharges_collection,
    recharge_history_collection,
    branches_collection,
    returned_products_collection,
    generate_branch_id,
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


# Function to generate OTP
def generate_otp():
    """Generate a 6-digit OTP"""
    return ''.join(random.choices(string.digits, k=6))


# Function to send email with OTP
def send_otp_email(email, otp, shop_name=None, shop_id=None, user_name=None, role=None):
    """Send OTP email for verification"""
    sender_email = "shoptrack.gnvox@gmail.com"
    
    # Create message container
    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = email
    
    if shop_id and shop_name and user_name and role:
        # New user added to shop
        msg['Subject'] = f"Welcome to {shop_name} on ShopTrack"
        
        # Email content
        body = f"""
        <html>
        <body>
            <h2>Welcome to ShopTrack!</h2>
            <p>Dear {user_name},</p>
            <p>You have been added to <b>{shop_name}</b> (Shop ID: {shop_id}) as a <b>{role}</b>.</p>
            <p>Please use the following details to login:</p>
            <ul>
                <li>Shop ID: <b>{shop_id}</b></li>
                <li>Email: <b>{email}</b></li>
            </ul>
            <p>To verify your email, please use the following OTP:</p>
            <h3 style="background-color: #f2f2f2; padding: 10px; text-align: center;">{otp}</h3>
            <p>This OTP is valid for 30 minutes.</p>
            <p>Best regards,<br>ShopTrack Team</p>
        </body>
        </html>
        """
    else:
        # Regular OTP verification email
        msg['Subject'] = "ShopTrack Email Verification"
        
        # Email content
        body = f"""
        <html>
        <body>
            <h2>Email Verification</h2>
            <p>Thank you for registering with ShopTrack.</p>
            <p>Your OTP for email verification is:</p>
            <h3 style="background-color: #f2f2f2; padding: 10px; text-align: center;">{otp}</h3>
            <p>This OTP is valid for 30 minutes.</p>
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
        # Replace with your actual password or app password
        server.login(sender_email, os.getenv('EMAIL_PASSWORD', 'password'))
        
        # Send email
        server.send_message(msg)
        
        # Close connection
        server.quit()
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False


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
            
            # Generate OTP for email verification
            otp = generate_otp()
            otp_expiry = datetime.now() + timedelta(minutes=30)

            # Create shop document with premium fields (defaults to not premium)
            shop_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "address": data['address'],
                "owner_name": data['owner_name'],
                "license_number": data['license_number'],
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "is_premium": False,
                "balance": 0.0,
                "premium_until": None,
                "logo_url": None,
                "branches": [],
                "premium_downgraded_at": None
            }
            shops_collection.insert_one(shop_data)

            # Create owner user for this shop
            user_data = {
                "shop_id": shop_id,
                "name": data['owner_name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "owner",  # Changed from "admin" to "owner"
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
                "created_by": data['email'],  # Self-created
                "branch_id": None,
                "email_verified": False,
                "otp": otp,
                "otp_expiry": otp_expiry
            }
            users_collection.insert_one(user_data)
            
            # Send verification email with OTP
            send_otp_email(data['email'], otp)

            return Response({
                "message": "Shop registered successfully. Please verify your email with the OTP sent.",
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
                
                # Check if email is verified
                if not user.get('email_verified', False):
                    # Generate new OTP if needed
                    new_otp = generate_otp()
                    otp_expiry = datetime.now() + timedelta(minutes=30)
                    
                    # Update user with new OTP
                    users_collection.update_one(
                        {"_id": user['_id']},
                        {"$set": {
                            "otp": new_otp,
                            "otp_expiry": otp_expiry
                        }}
                    )
                    
                    # Send new OTP email
                    send_otp_email(user['email'], new_otp)
                    
                    return Response(
                        {
                            "error": "Email not verified",
                            "email": user['email'],
                            "require_verification": True,
                            "message": "Please verify your email with the OTP sent."
                        },
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
                        "designation": user.get('designation', 'Not Assigned'),
                        "seller_id": user.get('seller_id', 'Not Assigned'),
                        "is_premium": shop.get('is_premium', False),
                        "branch_id": user.get('branch_id', None)
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
            # Token is valid, return user info
            return Response({
                "valid": True,
                "user_id": payload.get('user_id'),
                "email": payload.get('email'),
                "shop_id": payload.get('shop_id'),
                "role": payload.get('role')
            })
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response({
                "valid": False,
                "error": "Invalid or expired token"
            }, status=status.HTTP_401_UNAUTHORIZED)


class VerifyEmailView(APIView):
    def post(self, request):
        """Verify user email with OTP"""
        try:
            data = request.data
            email = data.get('email')
            otp = data.get('otp')
            
            if not email or not otp:
                return Response(
                    {"error": "Email and OTP are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Find the user by email
            user = users_collection.find_one({"email": email})
            
            if not user:
                return Response(
                    {"error": "User not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if email is already verified
            if user.get('email_verified', False):
                return Response(
                    {"message": "Email already verified. Please login."},
                    status=status.HTTP_200_OK
                )
            
            # Check if OTP matches
            if user.get('otp') != otp:
                return Response(
                    {"error": "Invalid OTP"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if OTP is expired
            if datetime.now() > user.get('otp_expiry', datetime.now()):
                # Generate new OTP
                new_otp = generate_otp()
                otp_expiry = datetime.now() + timedelta(minutes=30)
                
                # Update user with new OTP
                users_collection.update_one(
                    {"email": email},
                    {"$set": {
                        "otp": new_otp,
                        "otp_expiry": otp_expiry
                    }}
                )
                
                # Send new OTP email
                send_otp_email(email, new_otp)
                
                return Response(
                    {"error": "OTP expired. A new OTP has been sent to your email."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Verify the email
            users_collection.update_one(
                {"email": email},
                {"$set": {
                    "email_verified": True,
                    "otp": None,
                    "otp_expiry": None
                }}
            )
            
            return Response(
                {"message": "Email verified successfully. You can now login."},
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def get(self, request):
        """Resend OTP for email verification"""
        try:
            email = request.query_params.get('email')
            
            if not email:
                return Response(
                    {"error": "Email is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Find the user by email
            user = users_collection.find_one({"email": email})
            
            if not user:
                return Response(
                    {"error": "User not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if email is already verified
            if user.get('email_verified', False):
                return Response(
                    {"message": "Email already verified. Please login."},
                    status=status.HTTP_200_OK
                )
            
            # Generate new OTP
            new_otp = generate_otp()
            otp_expiry = datetime.now() + timedelta(minutes=30)
            
            # Update user with new OTP
            users_collection.update_one(
                {"email": email},
                {"$set": {
                    "otp": new_otp,
                    "otp_expiry": otp_expiry
                }}
            )
            
            # Send new OTP email
            send_otp_email(email, new_otp)
            
            return Response(
                {"message": "A new OTP has been sent to your email."},
                status=status.HTTP_200_OK
            )
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class PremiumStatusView(APIView):
    def get(self, request, shop_id):
        """Get premium status of a shop"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get shop details
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Get premium status and details
            is_premium = shop.get('is_premium', False)
            balance = shop.get('balance', 0.0)
            premium_until = shop.get('premium_until')
            
            if premium_until:
                premium_until = premium_until.strftime('%Y-%m-%d %H:%M:%S')
            
            # Count branches
            branch_count = branches_collection.count_documents({"shop_id": shop_id})
            
            # Calculate daily billing
            daily_rate = 5.0  # Base rate in BDT
            daily_billing = daily_rate * max(1, branch_count)  # Minimum 1 branch
            
            # Days remaining with current balance
            days_remaining = int(balance / daily_billing) if daily_billing > 0 else 0
            
            return Response({
                "is_premium": is_premium,
                "balance": balance,
                "premium_until": premium_until,
                "branch_count": branch_count,
                "daily_billing": daily_billing,
                "days_remaining": days_remaining,
                "logo_url": shop.get('logo_url')
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PremiumSubscribeView(APIView):
    def post(self, request):
        """Subscribe to premium using a transaction ID"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            user_email = payload['email']
            shop_id = payload['shop_id']
            
            # Get data from request
            data = request.data
            transaction_id = data.get('transaction_id')
            
            if not transaction_id:
                return Response(
                    {"error": "Transaction ID is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if transaction exists and is not used
            transaction = premium_recharges_collection.find_one({
                "transaction_id": transaction_id,
                "used": False
            })
            
            if not transaction:
                return Response(
                    {"error": "Invalid or already used transaction ID"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get shop details
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update transaction as used
            premium_recharges_collection.update_one(
                {"_id": transaction['_id']},
                {"$set": {
                    "used": True,
                    "used_by_shop_id": shop_id,
                    "used_at": datetime.now()
                }}
            )
            
            # Get amount from transaction
            amount = transaction.get('amount', 0.0)
            
            # Update shop balance and premium status
            previous_balance = shop.get('balance', 0.0)
            new_balance = previous_balance + amount
            
            # Set premium status and expiry
            # Premium until is set based on daily billing (5 BDT per day per branch)
            # Default to 1 branch if no branches yet
            branch_count = branches_collection.count_documents({"shop_id": shop_id})
            daily_rate = 5.0 * max(1, branch_count)
            days_added = int(amount / daily_rate) if daily_rate > 0 else 0
            
            # If already premium, extend the premium_until date
            if shop.get('is_premium', False) and shop.get('premium_until'):
                premium_until = max(
                    shop['premium_until'],
                    datetime.now()
                ) + timedelta(days=days_added)
            else:
                premium_until = datetime.now() + timedelta(days=days_added)
            
            # Update shop
            shops_collection.update_one(
                {"shop_id": shop_id},
                {"$set": {
                    "is_premium": True,
                    "balance": new_balance,
                    "premium_until": premium_until,
                    "premium_downgraded_at": None,
                    "updated_at": datetime.now()
                }}
            )
            
            # Record recharge history
            recharge_history = {
                "shop_id": shop_id,
                "transaction_id": transaction_id,
                "amount": amount,
                "recharged_at": datetime.now(),
                "previous_balance": previous_balance,
                "new_balance": new_balance
            }
            recharge_history_collection.insert_one(recharge_history)
            
            return Response({
                "message": "Successfully subscribed to premium",
                "amount_added": amount,
                "new_balance": new_balance,
                "premium_until": premium_until.strftime('%Y-%m-%d %H:%M:%S'),
                "is_premium": True
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class RechargeHistoryView(APIView):
    def get(self, request, shop_id):
        """Get recharge history for a shop"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get recharge history
            history = list(recharge_history_collection.find(
                {"shop_id": shop_id}
            ).sort("recharged_at", -1))
            
            # Convert ObjectId to string for serialization
            for item in history:
                item['_id'] = str(item['_id'])
                if 'recharged_at' in item:
                    item['recharged_at'] = item['recharged_at'].strftime('%Y-%m-%d %H:%M:%S')
            
            return Response(history)
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class BranchesView(APIView):
    def get(self, request, shop_id):
        """Get all branches for a shop"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if shop exists
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if shop is premium
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Premium subscription required for branch management"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get all branches for the shop
            branches = list(branches_collection.find({"shop_id": shop_id}))
            
            # For each branch, get the manager details and count of users
            for branch in branches:
                branch['_id'] = str(branch['_id'])
                if 'created_at' in branch:
                    branch['created_at'] = branch['created_at'].strftime('%Y-%m-%d %H:%M:%S')
                if 'updated_at' in branch:
                    branch['updated_at'] = branch['updated_at'].strftime('%Y-%m-%d %H:%M:%S')
                
                # Get manager details if available
                if branch.get('manager_id'):
                    manager = users_collection.find_one({"_id": ObjectId(branch['manager_id'])})
                    if manager:
                        branch['manager'] = {
                            "name": manager.get('name'),
                            "email": manager.get('email'),
                            "role": manager.get('role')
                        }
                
                # Count users in this branch
                branch['user_count'] = users_collection.count_documents({
                    "shop_id": shop_id,
                    "branch_id": branch.get('branch_id')
                })
            
            return Response(branches)
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CreateBranchView(APIView):
    def post(self, request):
        """Create a new branch for a shop"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            user_email = payload['email']
            shop_id = payload['shop_id']
            role = payload['role']
            
            # Only owners can create branches
            if role != 'owner':
                return Response(
                    {"error": "Only shop owners can create branches"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get data from request
            data = request.data
            branch_name = data.get('name')
            branch_address = data.get('address')
            manager_email = data.get('manager_email')
            
            if not branch_name or not branch_address:
                return Response(
                    {"error": "Branch name and address are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if shop exists and is premium
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Premium subscription required for branch management"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Generate unique branch ID
            branch_id = generate_branch_id(shop_id)
            
            # Find manager if specified
            manager_id = None
            if manager_email:
                manager = users_collection.find_one({
                    "shop_id": shop_id,
                    "email": manager_email,
                    "role": { "$in": ["admin", "owner"] }  # Manager must be admin or owner
                })
                
                if manager:
                    manager_id = str(manager['_id'])
            
            # Create branch
            branch_data = {
                "branch_id": branch_id,
                "shop_id": shop_id,
                "name": branch_name,
                "address": branch_address,
                "manager_id": manager_id,
                "created_at": datetime.now(),
                "updated_at": datetime.now()
            }
            branches_collection.insert_one(branch_data)
            
            # If manager specified, assign them to this branch
            if manager_id:
                users_collection.update_one(
                    {"_id": ObjectId(manager_id)},
                    {"$set": {
                        "branch_id": branch_id,
                        "updated_at": datetime.now()
                    }}
                )
            
            # Update shop with new branch count for billing
            branch_count = branches_collection.count_documents({"shop_id": shop_id})
            
            # Return response
            return Response({
                "message": "Branch created successfully",
                "branch_id": branch_id,
                "branch_count": branch_count
            }, status=status.HTTP_201_CREATED)
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class BranchDetailView(APIView):
    def get(self, request, branch_id):
        """Get branch details and users"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            
            # Get branch details
            branch = branches_collection.find_one({
                "branch_id": branch_id,
                "shop_id": shop_id
            })
            
            if not branch:
                return Response(
                    {"error": "Branch not found or unauthorized access"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Convert ObjectId to string for serialization
            branch['_id'] = str(branch['_id'])
            if 'created_at' in branch:
                branch['created_at'] = branch['created_at'].strftime('%Y-%m-%d %H:%M:%S')
            if 'updated_at' in branch:
                branch['updated_at'] = branch['updated_at'].strftime('%Y-%m-%d %H:%M:%S')
            
            # Get manager details if available
            if branch.get('manager_id'):
                manager = users_collection.find_one({"_id": ObjectId(branch['manager_id'])})
                if manager:
                    branch['manager'] = {
                        "id": str(manager['_id']),
                        "name": manager.get('name'),
                        "email": manager.get('email'),
                        "role": manager.get('role')
                    }
            
            # Get all users in this branch
            users = list(users_collection.find({
                "shop_id": shop_id,
                "branch_id": branch_id
            }))
            
            # Prepare user data for response
            user_data = []
            for user in users:
                user_data.append({
                    "id": str(user['_id']),
                    "name": user.get('name'),
                    "email": user.get('email'),
                    "role": user.get('role'),
                    "designation": user.get('designation')
                })
            
            # Add users to branch data
            branch['users'] = user_data
            
            return Response(branch)
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request, branch_id):
        """Update branch details"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            role = payload['role']
            
            # Only owners can update branches
            if role != 'owner':
                return Response(
                    {"error": "Only shop owners can update branches"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if branch exists and belongs to this shop
            branch = branches_collection.find_one({
                "branch_id": branch_id,
                "shop_id": shop_id
            })
            
            if not branch:
                return Response(
                    {"error": "Branch not found or unauthorized access"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Get data from request
            data = request.data
            updates = {}
            
            if 'name' in data:
                updates['name'] = data['name']
            
            if 'address' in data:
                updates['address'] = data['address']
            
            if 'manager_email' in data:
                # Find the new manager
                manager = users_collection.find_one({
                    "shop_id": shop_id,
                    "email": data['manager_email'],
                    "role": { "$in": ["admin", "owner"] }  # Manager must be admin or owner
                })
                
                if manager:
                    updates['manager_id'] = str(manager['_id'])
                    
                    # Update the manager's branch assignment
                    users_collection.update_one(
                        {"_id": manager['_id']},
                        {"$set": {
                            "branch_id": branch_id,
                            "updated_at": datetime.now()
                        }}
                    )
                    
                    # If there was a previous manager, remove their branch assignment
                    if branch.get('manager_id') and branch['manager_id'] != str(manager['_id']):
                        users_collection.update_one(
                            {"_id": ObjectId(branch['manager_id'])},
                            {"$set": {
                                "branch_id": None,
                                "updated_at": datetime.now()
                            }}
                        )
            
            # Only update if there are changes
            if updates:
                updates['updated_at'] = datetime.now()
                
                branches_collection.update_one(
                    {"_id": branch['_id']},
                    {"$set": updates}
                )
                
                return Response({
                    "message": "Branch updated successfully"
                })
            else:
                return Response({
                    "message": "No changes to update"
                })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, branch_id):
        """Delete a branch"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            role = payload['role']
            
            # Only owners can delete branches
            if role != 'owner':
                return Response(
                    {"error": "Only shop owners can delete branches"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if branch exists and belongs to this shop
            branch = branches_collection.find_one({
                "branch_id": branch_id,
                "shop_id": shop_id
            })
            
            if not branch:
                return Response(
                    {"error": "Branch not found or unauthorized access"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if there are users in this branch
            user_count = users_collection.count_documents({
                "shop_id": shop_id,
                "branch_id": branch_id
            })
            
            if user_count > 0:
                return Response(
                    {"error": "Cannot delete branch with users. Please reassign all users first."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Delete the branch
            branches_collection.delete_one({"_id": branch['_id']})
            
            return Response({
                "message": "Branch deleted successfully"
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AssignUserToBranchView(APIView):
    def post(self, request):
        """Assign a user to a branch"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            role = payload['role']
            
            # Only owners and admins can assign users to branches
            if role not in ['owner', 'admin']:
                return Response(
                    {"error": "Only shop owners and admins can assign users to branches"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get data from request
            data = request.data
            user_email = data.get('user_email')
            branch_id = data.get('branch_id')
            
            if not user_email:
                return Response(
                    {"error": "User email is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Find the user
            user = users_collection.find_one({
                "shop_id": shop_id,
                "email": user_email
            })
            
            if not user:
                return Response(
                    {"error": "User not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # If branch_id is None, remove branch assignment
            if branch_id is None:
                users_collection.update_one(
                    {"_id": user['_id']},
                    {"$set": {
                        "branch_id": None,
                        "updated_at": datetime.now()
                    }}
                )
                
                return Response({
                    "message": f"User {user_email} removed from branch"
                })
            
            # Find the branch
            branch = branches_collection.find_one({
                "branch_id": branch_id,
                "shop_id": shop_id
            })
            
            if not branch:
                return Response(
                    {"error": "Branch not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update user with branch assignment
            users_collection.update_one(
                {"_id": user['_id']},
                {"$set": {
                    "branch_id": branch_id,
                    "updated_at": datetime.now()
                }}
            )
            
            return Response({
                "message": f"User {user_email} assigned to branch {branch['name']}"
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ReturnProductView(APIView):
    def post(self, request):
        """Process a product return (Premium feature)"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            
            # Check if shop is premium
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Product return is a premium feature"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get data from request
            data = request.data
            invoice_id = data.get('invoice_id')
            product_id = data.get('product_id')
            quantity = data.get('quantity')
            return_reason = data.get('return_reason', 'Not specified')
            branch_id = data.get('branch_id')
            
            if not invoice_id or not product_id or not quantity:
                return Response(
                    {"error": "Invoice ID, product ID, and quantity are required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if invoice exists
            invoice = invoices_collection.find_one({
                "_id": ObjectId(invoice_id),
                "shop_id": shop_id,
                "status": "completed"
            })
            
            if not invoice:
                return Response(
                    {"error": "Completed invoice not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Find the product in the invoice
            invoice_item = None
            for item in invoice.get('items', []):
                if item.get('product_id') == product_id:
                    invoice_item = item
                    break
            
            if not invoice_item:
                return Response(
                    {"error": "Product not found in the invoice"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if return quantity is valid
            return_quantity = int(quantity)
            if return_quantity <= 0:
                return Response(
                    {"error": "Return quantity must be positive"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if return_quantity > invoice_item.get('quantity', 0):
                return Response(
                    {"error": f"Cannot return more than purchased quantity ({invoice_item.get('quantity')})"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get the product
            product = products_collection.find_one({
                "_id": ObjectId(product_id),
                "shop_id": shop_id
            })
            
            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Create return record
            return_data = {
                "shop_id": shop_id,
                "branch_id": branch_id,
                "product_id": product_id,
                "invoice_id": invoice_id,
                "quantity": return_quantity,
                "selling_price": invoice_item.get('price'),
                "return_reason": return_reason,
                "returned_at": datetime.now(),
                "processed_by": user_email
            }
            returned_products_collection.insert_one(return_data)
            
            # Update product quantity
            products_collection.update_one(
                {"_id": ObjectId(product_id)},
                {"$inc": {
                    "quantity": return_quantity
                },
                "$set": {
                    "updated_at": datetime.now()
                }}
            )
            
            return Response({
                "message": f"Successfully processed return of {return_quantity} item(s)",
                "product_name": product.get('name'),
                "return_id": str(return_data.get('_id')),
                "new_quantity": product.get('quantity') + return_quantity
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ReturnedProductsView(APIView):
    def get(self, request, shop_id):
        """Get all returned products for a shop (Premium feature)"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if shop is premium
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Product return history is a premium feature"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get query parameters
            branch_id = request.query_params.get('branch_id')
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            
            # Build query
            query = {"shop_id": shop_id}
            
            if branch_id:
                query["branch_id"] = branch_id
            
            if start_date:
                try:
                    start_datetime = datetime.strptime(start_date, '%Y-%m-%d')
                    query["returned_at"] = {"$gte": start_datetime}
                except ValueError:
                    return Response(
                        {"error": "Invalid start_date format. Use YYYY-MM-DD"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            if end_date:
                try:
                    end_datetime = datetime.strptime(end_date, '%Y-%m-%d')
                    end_datetime = end_datetime.replace(hour=23, minute=59, second=59)
                    
                    if "returned_at" in query:
                        query["returned_at"]["$lte"] = end_datetime
                    else:
                        query["returned_at"] = {"$lte": end_datetime}
                except ValueError:
                    return Response(
                        {"error": "Invalid end_date format. Use YYYY-MM-DD"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Get returned products
            returned_products = list(returned_products_collection.find(query).sort("returned_at", -1))
            
            # Enhance returned products with additional details
            results = []
            for item in returned_products:
                item['_id'] = str(item['_id'])
                if 'returned_at' in item:
                    item['returned_at'] = item['returned_at'].strftime('%Y-%m-%d %H:%M:%S')
                
                # Get product name
                product = products_collection.find_one({"_id": ObjectId(item.get('product_id'))})
                if product:
                    item['product_name'] = product.get('name')
                
                # Get branch name if applicable
                if item.get('branch_id'):
                    branch = branches_collection.find_one({"branch_id": item.get('branch_id')})
                    if branch:
                        item['branch_name'] = branch.get('name')
                
                results.append(item)
            
            return Response(results)
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PremiumSalesAnalyticsView(APIView):
    def get(self, request, shop_id):
        """Get sales analytics for a premium shop"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if shop is premium
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Sales analytics is a premium feature"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get query parameters
            branch_id = request.query_params.get('branch_id')
            period = request.query_params.get('period', 'daily')  # daily, monthly, yearly
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            
            # Build query for completed invoices
            query = {
                "shop_id": shop_id,
                "status": "completed"
            }
            
            if branch_id:
                query["branch_id"] = branch_id
            
            # Set date range based on period if no explicit dates provided
            if not start_date and not end_date:
                if period == 'daily':
                    # Default to today
                    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
                    query["date"] = {"$gte": today.strftime('%Y-%m-%d')}
                elif period == 'monthly':
                    # Default to current month
                    first_day = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
                    query["date"] = {"$gte": first_day.strftime('%Y-%m-%d')}
                elif period == 'yearly':
                    # Default to current year
                    first_day = datetime.now().replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
                    query["date"] = {"$gte": first_day.strftime('%Y-%m-%d')}
            else:
                # Use provided date range
                if start_date:
                    query["date"] = {"$gte": start_date}
                if end_date:
                    if "date" in query:
                        query["date"]["$lte"] = end_date
                    else:
                        query["date"] = {"$lte": end_date}
            
            # Get invoices
            invoices = list(invoices_collection.find(query))
            
            # Process invoices for analytics
            sales_data = {}
            
            if period == 'daily':
                # Group by hours for daily view
                for invoice in invoices:
                    try:
                        invoice_date = datetime.strptime(invoice['date'], '%Y-%m-%d')
                        invoice_time = invoice.get('time', '00:00')
                        hour = invoice_time.split(':')[0]
                        if hour not in sales_data:
                            sales_data[hour] = {
                                'sales': 0,
                                'count': 0,
                                'profit': 0
                            }
                        
                        sales_data[hour]['sales'] += invoice['total_amount']
                        sales_data[hour]['count'] += 1
                        
                        # Calculate profit if buying prices available
                        profit = 0
                        for item in invoice.get('items', []):
                            product = products_collection.find_one({"_id": ObjectId(item.get('product_id'))})
                            if product:
                                item_profit = (float(item.get('price', 0)) - float(product.get('buying_price', 0))) * int(item.get('quantity', 0))
                                profit += item_profit
                        
                        sales_data[hour]['profit'] += profit
                    except Exception as e:
                        print(f"Error processing invoice {invoice.get('_id')}: {e}")
            
            elif period == 'monthly':
                # Group by days for monthly view
                for invoice in invoices:
                    try:
                        invoice_date = datetime.strptime(invoice['date'], '%Y-%m-%d')
                        day = invoice_date.day
                        
                        if day not in sales_data:
                            sales_data[day] = {
                                'sales': 0,
                                'count': 0,
                                'profit': 0
                            }
                        
                        sales_data[day]['sales'] += invoice['total_amount']
                        sales_data[day]['count'] += 1
                        
                        # Calculate profit
                        profit = 0
                        for item in invoice.get('items', []):
                            product = products_collection.find_one({"_id": ObjectId(item.get('product_id'))})
                            if product:
                                item_profit = (float(item.get('price', 0)) - float(product.get('buying_price', 0))) * int(item.get('quantity', 0))
                                profit += item_profit
                        
                        sales_data[day]['profit'] += profit
                    except Exception as e:
                        print(f"Error processing invoice {invoice.get('_id')}: {e}")
            
            elif period == 'yearly':
                # Group by months for yearly view
                for invoice in invoices:
                    try:
                        invoice_date = datetime.strptime(invoice['date'], '%Y-%m-%d')
                        month = invoice_date.month
                        
                        if month not in sales_data:
                            sales_data[month] = {
                                'sales': 0,
                                'count': 0,
                                'profit': 0,
                                'month_name': invoice_date.strftime('%B')
                            }
                        
                        sales_data[month]['sales'] += invoice['total_amount']
                        sales_data[month]['count'] += 1
                        
                        # Calculate profit
                        profit = 0
                        for item in invoice.get('items', []):
                            product = products_collection.find_one({"_id": ObjectId(item.get('product_id'))})
                            if product:
                                item_profit = (float(item.get('price', 0)) - float(product.get('buying_price', 0))) * int(item.get('quantity', 0))
                                profit += item_profit
                        
                        sales_data[month]['profit'] += profit
                    except Exception as e:
                        print(f"Error processing invoice {invoice.get('_id')}: {e}")
            
            # Convert to list for response
            results = []
            for key, value in sales_data.items():
                item = {'period': key}
                item.update(value)
                results.append(item)
            
            # Sort by period
            results.sort(key=lambda x: int(x['period']))
            
            # Calculate totals
            total_sales = sum(item['sales'] for item in results)
            total_count = sum(item['count'] for item in results)
            total_profit = sum(item['profit'] for item in results)
            
            return Response({
                'period': period,
                'data': results,
                'totals': {
                    'sales': total_sales,
                    'count': total_count,
                    'profit': total_profit
                }
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProductProfitAnalyticsView(APIView):
    def get(self, request, shop_id):
        """Get product-specific profit analytics for a premium shop"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if shop is premium
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Product profit analytics is a premium feature"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get query parameters
            branch_id = request.query_params.get('branch_id')
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            product_id = request.query_params.get('product_id')
            limit = int(request.query_params.get('limit', 10))
            
            # Build query for completed invoices
            query = {
                "shop_id": shop_id,
                "status": "completed"
            }
            
            if branch_id:
                query["branch_id"] = branch_id
            
            # Use provided date range
            if start_date:
                query["date"] = {"$gte": start_date}
            if end_date:
                if "date" in query:
                    query["date"]["$lte"] = end_date
                else:
                    query["date"] = {"$lte": end_date}
            
            # Get invoices
            invoices = list(invoices_collection.find(query))
            
            # Process invoices for product analytics
            product_data = {}
            
            for invoice in invoices:
                for item in invoice.get('items', []):
                    item_product_id = item.get('product_id')
                    
                    # Skip if not the requested product
                    if product_id and item_product_id != product_id:
                        continue
                    
                    # Get product details
                    product = products_collection.find_one({"_id": ObjectId(item_product_id)})
                    if not product:
                        continue
                    
                    if item_product_id not in product_data:
                        product_data[item_product_id] = {
                            'name': product.get('name', 'Unknown Product'),
                            'sales_count': 0,
                            'sales_amount': 0,
                            'buying_amount': 0,
                            'profit': 0
                        }
                    
                    quantity = int(item.get('quantity', 0))
                    selling_price = float(item.get('price', 0))
                    buying_price = float(product.get('buying_price', 0))
                    
                    product_data[item_product_id]['sales_count'] += quantity
                    product_data[item_product_id]['sales_amount'] += quantity * selling_price
                    product_data[item_product_id]['buying_amount'] += quantity * buying_price
                    product_data[item_product_id]['profit'] += quantity * (selling_price - buying_price)
            
            # Convert to list for response
            results = []
            for product_id, data in product_data.items():
                item = {'product_id': product_id}
                item.update(data)
                
                # Calculate profit margin percentage
                if item['sales_amount'] > 0:
                    item['profit_margin'] = (item['profit'] / item['sales_amount']) * 100
                else:
                    item['profit_margin'] = 0
                
                results.append(item)
            
            # Sort by profit and limit results
            results.sort(key=lambda x: x['profit'], reverse=True)
            results = results[:limit]
            
            # Calculate totals
            total_sales_count = sum(item['sales_count'] for item in results)
            total_sales_amount = sum(item['sales_amount'] for item in results)
            total_buying_amount = sum(item['buying_amount'] for item in results)
            total_profit = sum(item['profit'] for item in results)
            
            # Avoid division by zero
            profit_margin = 0
            if total_sales_amount > 0:
                profit_margin = (total_profit / total_sales_amount) * 100
            
            return Response({
                'products': results,
                'totals': {
                    'sales_count': total_sales_count,
                    'sales_amount': total_sales_amount,
                    'buying_amount': total_buying_amount,
                    'profit': total_profit,
                    'profit_margin': profit_margin
                }
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ShopSettingsView(APIView):
    def get(self, request, shop_id):
        """Get shop settings"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get shop details
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Prepare shop settings
            settings = {
                "shop_id": shop.get('shop_id'),
                "name": shop.get('name'),
                "address": shop.get('address'),
                "owner_name": shop.get('owner_name'),
                "license_number": shop.get('license_number'),
                "is_premium": shop.get('is_premium', False),
                "logo_url": shop.get('logo_url'),
                "created_at": shop.get('created_at').strftime('%Y-%m-%d %H:%M:%S') if shop.get('created_at') else None,
                "updated_at": shop.get('updated_at').strftime('%Y-%m-%d %H:%M:%S') if shop.get('updated_at') else None
            }
            
            # If premium, include premium settings
            if shop.get('is_premium', False):
                settings.update({
                    "balance": shop.get('balance', 0.0),
                    "premium_until": shop.get('premium_until').strftime('%Y-%m-%d %H:%M:%S') if shop.get('premium_until') else None,
                    "branch_count": branches_collection.count_documents({"shop_id": shop_id})
                })
            
            return Response(settings)
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request, shop_id):
        """Update shop settings"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            role = payload['role']
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Only owners can update shop settings
            if role != 'owner':
                return Response(
                    {"error": "Only shop owners can update shop settings"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get shop details
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Get data from request
            data = request.data
            updates = {}
            
            # Allow updating basic shop details
            if 'name' in data:
                updates['name'] = data['name']
            
            if 'address' in data:
                updates['address'] = data['address']
            
            if 'license_number' in data:
                updates['license_number'] = data['license_number']
            
            # Update shop record
            if updates:
                updates['updated_at'] = datetime.now()
                
                shops_collection.update_one(
                    {"shop_id": shop_id},
                    {"$set": updates}
                )
                
                return Response({
                    "message": "Shop settings updated successfully"
                })
            else:
                return Response({
                    "message": "No changes to update"
                })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class UploadShopLogoView(APIView):
    def post(self, request, shop_id):
        """Upload shop logo (Premium feature)"""
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            role = payload['role']
            
            # Check if the shop ID in the request matches the shop ID in the token
            if shop_id != payload['shop_id']:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Only owners can upload shop logo
            if role != 'owner':
                return Response(
                    {"error": "Only shop owners can upload shop logo"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get shop details
            shop = shops_collection.find_one({"shop_id": shop_id})
            if not shop:
                return Response(
                    {"error": "Shop not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if shop is premium
            if not shop.get('is_premium', False):
                return Response(
                    {"error": "Shop logo upload is a premium feature"},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get logo URL from request
            data = request.data
            logo_url = data.get('logo_url')
            
            if not logo_url:
                return Response(
                    {"error": "Logo URL is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Update shop record with logo URL
            shops_collection.update_one(
                {"shop_id": shop_id},
                {"$set": {
                    "logo_url": logo_url,
                    "updated_at": datetime.now()
                }}
            )
            
            return Response({
                "message": "Shop logo updated successfully",
                "logo_url": logo_url
            })
            
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


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