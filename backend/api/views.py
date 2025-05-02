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
import bcrypt
from bson.errors import InvalidId
from django.views.decorators.csrf import csrf_exempt
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from pymongo import ASCENDING, DESCENDING

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
    SearchProductsView,
    db,
    sales_collection
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

            # Allow both managers and owners to delete invoices
            if role not in ['manager', 'owner']:
                return Response(
                    {"error": "Only managers and owners can delete invoices"},
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

            # Restore product quantities for each item in the invoice
            for item in invoice['items']:
                product_id = item['product_id']
                quantity = int(item['quantity'])

                # Get current product to verify on_hold count
                product = products_collection.find_one({"_id": ObjectId(product_id)})
                if not product:
                    continue

                # Only reduce on_hold by what's available (to avoid negative values)
                on_hold_update = min(quantity, product.get('quantity_on_hold', 0))

                # Restore the product quantity and reduce on_hold
                products_collection.update_one(
                    {"_id": ObjectId(product_id)},
                    {
                        "$inc": {
                            "quantity": quantity,
                            "quantity_on_hold": -on_hold_update
                        }
                    }
                )

            # Delete the invoice
            result = invoices_collection.delete_one({"_id": ObjectId(invoice_id)})

            if result.deleted_count == 0:
                return Response(
                    {"error": "Failed to delete invoice"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            return Response({
                "message": "Invoice deleted successfully, product quantities restored"
            })

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# Helper function to validate MongoDB ObjectId
def is_valid_object_id(id_to_check):
    """Check if a string can be converted to a valid MongoDB ObjectId."""
    if not id_to_check:
        return False
    try:
        ObjectId(id_to_check)
        return True
    except (InvalidId, TypeError):
        return False


class DeleteProductView(APIView):
    def delete(self, request, product_id):
        # Better logging at entry point
        print(f"DeleteProductView: Received delete request for product ID {product_id}")
        
        # Ensure this view always returns JSON, not HTML
        try:
            # Verify JWT token from headers
            token = request.headers.get('Authorization', '').replace('Bearer ', '')
            try:
                payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
                shop_id = payload['shop_id']
                user_email = payload['email']
                role = payload.get('role', '')
                
                print(f"DeleteProductView: User {user_email} with role {role} attempting to delete product {product_id}")

                # Allow both managers and owners to delete products
                if role not in ['manager', 'owner']:
                    print(f"DeleteProductView: User {user_email} with role {role} not authorized to delete products")
                    return Response(
                        {"error": "Only managers or owners can delete products"},
                        status=status.HTTP_403_FORBIDDEN
                    )
                
                print(f"DeleteProductView: User {user_email} with role {role} is authorized to delete products")

            except (jwt.ExpiredSignatureError, jwt.InvalidTokenError) as e:
                print(f"DeleteProductView: Token validation error - {str(e)}")
                return Response(
                    {"error": "Invalid or expired token"},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            except Exception as e:
                print(f"DeleteProductView: Unexpected error during token validation - {str(e)}")
                return Response(
                    {"error": f"Authentication error: {str(e)}"},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            try:
                print(f"DeleteProductView: Attempting to delete product {product_id} by user {user_email} with role {role}")
                
                # Clean the product_id to ensure no unexpected characters
                cleaned_product_id = product_id.strip().replace('"', '').replace("'", '')
                if product_id != cleaned_product_id:
                    print(f"DeleteProductView: Cleaned product ID from '{product_id}' to '{cleaned_product_id}'")
                    product_id = cleaned_product_id
                
                # First attempt - try with ObjectId
                product = None
                delete_id = None
                try:
                    object_id = ObjectId(product_id)
                    product = products_collection.find_one({"_id": object_id})
                    if product:
                        print(f"DeleteProductView: Found product with ObjectId: {product.get('name', 'Unknown')}")
                        delete_id = object_id
                except InvalidId:
                    print(f"DeleteProductView: Product ID {product_id} is not a valid ObjectId format")
                except Exception as e:
                    print(f"DeleteProductView: Error when searching with ObjectId: {str(e)}")
                
                # Second attempt - try with string ID
                if not product:
                    try:
                        product = products_collection.find_one({"_id": product_id})
                        if product:
                            print(f"DeleteProductView: Found product with string ID: {product.get('name', 'Unknown')}")
                            delete_id = product_id
                    except Exception as e:
                        print(f"DeleteProductView: Error when searching with string ID: {str(e)}")
                
                # Third attempt - try looking up by name in this shop
                if not product:
                    try:
                        # Try searching by shop_id and looking for product ID in other fields
                        shop_products = list(products_collection.find({"shop_id": shop_id}))
                        print(f"DeleteProductView: Found {len(shop_products)} products for shop {shop_id}")
                        
                        for p in shop_products:
                            # Check if any field matches the product_id
                            if (str(p.get('_id', '')) == product_id or 
                                p.get('id', '') == product_id or 
                                p.get('product_id', '') == product_id):
                                product = p
                                delete_id = p['_id']
                                print(f"DeleteProductView: Found product by field comparison: {product.get('name', 'Unknown')}")
                                break
                    except Exception as e:
                        print(f"DeleteProductView: Error during shop products search: {str(e)}")

                # If product is still not found, return error
                if not product:
                    print(f"DeleteProductView: Product not found with ID: {product_id}")
                    return Response(
                        {"error": f"Product not found with ID: {product_id}"},
                        status=status.HTTP_404_NOT_FOUND
                    )

                # Check if the product belongs to this shop
                if product.get('shop_id') != shop_id:
                    print(f"DeleteProductView: Unauthorized - Product belongs to shop {product.get('shop_id')}, not {shop_id}")
                    return Response(
                        {"error": "Unauthorized access - product belongs to a different shop"},
                        status=status.HTTP_403_FORBIDDEN
                    )

                # Store product info for response
                product_name = product.get('name', 'Unknown Product')
                
                # Delete the product
                print(f"DeleteProductView: Deleting product with ID type {type(delete_id).__name__}: {delete_id}")
                deletion_successful = False
                try:
                    result = products_collection.delete_one({"_id": delete_id})
                    print(f"DeleteProductView: Product deletion result: {result.deleted_count} document(s) deleted")
                    if result.deleted_count > 0:
                        deletion_successful = True
                except Exception as e:
                    print(f"DeleteProductView: Error during product deletion: {str(e)}")
                    # Try with string ID if ObjectId failed
                    if isinstance(delete_id, ObjectId):
                        try:
                            str_id = str(delete_id)
                            result = products_collection.delete_one({"_id": str_id})
                            print(f"DeleteProductView: Fallback deletion with string ID: {result.deleted_count} document(s) deleted")
                            if result.deleted_count > 0:
                                deletion_successful = True
                        except Exception as nested_e:
                            print(f"DeleteProductView: Error during fallback deletion: {str(nested_e)}")
                
                # If product wasn't deleted, try deleting by matching against various fields
                if not deletion_successful:
                    try:
                        print(f"DeleteProductView: Attempting advanced deletion for product {product_id}")
                        # Create a more comprehensive query to match the product
                        query = {
                            "$or": [
                                {"_id": product_id},
                                {"_id": ObjectId(product_id) if is_valid_object_id(product_id) else "invalid_id"},
                                {"id": product_id},
                                {"product_id": product_id},
                                {"name": product.get('name')}
                            ]
                        }
                        # Also ensure we're only deleting from the correct shop
                        query["shop_id"] = shop_id
                        
                        result = products_collection.delete_one(query)
                        print(f"DeleteProductView: Advanced deletion result: {result.deleted_count} document(s) deleted")
                        if result.deleted_count > 0:
                            deletion_successful = True
                    except Exception as e:
                        print(f"DeleteProductView: Error during advanced deletion: {str(e)}")
                
                # Convert product_id to string for related collections
                product_id_str = str(delete_id) if isinstance(delete_id, ObjectId) else product_id
                
                # Delete batches - try both string and ObjectId formats
                batches_deleted = 0
                try:
                    # Try with string ID
                    batch_result = batches_collection.delete_many({"product_id": product_id_str})
                    batches_deleted += batch_result.deleted_count
                    print(f"DeleteProductView: Deleted {batch_result.deleted_count} batches with string product_id")
                    
                    # Try with ObjectId if possible
                    try:
                        if is_valid_object_id(product_id_str):
                            obj_id = ObjectId(product_id_str)
                            batch_result = batches_collection.delete_many({"product_id": obj_id})
                            batches_deleted += batch_result.deleted_count
                            print(f"DeleteProductView: Deleted {batch_result.deleted_count} batches with ObjectId product_id")
                    except (InvalidId, Exception) as e:
                        print(f"DeleteProductView: Skip ObjectId batch deletion: {str(e)}")
                except Exception as e:
                    print(f"DeleteProductView: Error deleting batches: {str(e)}")
                
                # Delete sales records - try both formats
                sales_deleted = 0
                try:
                    # Try with string ID
                    sales_result = sales_collection.delete_many({"product_id": product_id_str})
                    sales_deleted += sales_result.deleted_count
                    print(f"DeleteProductView: Deleted {sales_result.deleted_count} sales with string product_id")
                    
                    # Try with ObjectId if possible
                    try:
                        if is_valid_object_id(product_id_str):
                            obj_id = ObjectId(product_id_str)
                            sales_result = sales_collection.delete_many({"product_id": obj_id})
                            sales_deleted += sales_result.deleted_count
                            print(f"DeleteProductView: Deleted {sales_result.deleted_count} sales with ObjectId product_id")
                    except (InvalidId, Exception) as e:
                        print(f"DeleteProductView: Skip ObjectId sales deletion: {str(e)}")
                except Exception as e:
                    print(f"DeleteProductView: Error deleting sales: {str(e)}")
                
                # Delete price history
                price_history_deleted = 0
                try:
                    # Try with string ID
                    ph_result = price_history_collection.delete_many({"product_id": product_id_str})
                    price_history_deleted += ph_result.deleted_count
                    print(f"DeleteProductView: Deleted {ph_result.deleted_count} price history records with string product_id")
                    
                    # Try with ObjectId if possible
                    try:
                        if is_valid_object_id(product_id_str):
                            obj_id = ObjectId(product_id_str)
                            ph_result = price_history_collection.delete_many({"product_id": obj_id})
                            price_history_deleted += ph_result.deleted_count
                            print(f"DeleteProductView: Deleted {ph_result.deleted_count} price history records with ObjectId product_id")
                    except (InvalidId, Exception) as e:
                        print(f"DeleteProductView: Skip ObjectId price history deletion: {str(e)}")
                except Exception as e:
                    print(f"DeleteProductView: Error deleting price history: {str(e)}")

                # If nothing was successfully deleted, still consider it successful if we found the product
                # (This suggests the product existed but had no related records)
                if product and not deletion_successful and batches_deleted == 0 and sales_deleted == 0 and price_history_deleted == 0:
                    print(f"DeleteProductView: No records were deleted, but product was found. Considering deletion successful.")
                    
                return Response({
                    "message": f"Product '{product_name}' and related data deleted successfully",
                    "batches_deleted": batches_deleted,
                    "sales_deleted": sales_deleted,
                    "price_history_deleted": price_history_deleted
                })

            except Exception as e:
                error_message = f"Error deleting product: {str(e)}"
                print(f"DeleteProductView: {error_message}")
                import traceback
                print(traceback.format_exc())
                return Response(
                    {"error": error_message},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
        except Exception as outer_e:
            print(f"DeleteProductView: Unhandled exception: {str(outer_e)}")
            import traceback
            print(traceback.format_exc())
            # Always return a JSON response, even for unexpected errors
            return Response(
                {"error": f"Unexpected error: {str(outer_e)}"},
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

            # Query pending invoices
            pending_invoices = list(invoices_collection.find({
                "shop_id": shop_id,
                "status": "pending"
            }))

            # Calculate stats
            total_sales = len(today_invoices)
            total_revenue = sum(invoice.get('total_amount', 0) for invoice in today_invoices)
            pending_count = len(pending_invoices)
            pending_amount = sum(invoice.get('total_amount', 0) for invoice in pending_invoices)

            return Response({
                "total_sales": total_sales,
                "total_revenue": total_revenue,
                "pending_invoices": pending_count,
                "pending_amount": pending_amount,
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
            user_id = payload.get('user_id', None)
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
                # Update existing product quantities
                # Get all batches for this product to recalculate total quantity correctly
                all_batches = list(batches_collection.find({"product_id": str(existing_product['_id'])}))
                current_quantity = sum(int(batch.get('quantity', 0)) for batch in all_batches)
                new_quantity = current_quantity + data['quantity']
                
                # Calculate available quantity (total - on_hold)
                current_on_hold = existing_product.get('quantity_on_hold', 0)
                new_available = new_quantity - current_on_hold
                
                products_collection.update_one(
                    {"_id": existing_product['_id']},
                    {"$set": {
                        "quantity": new_quantity,
                        "available_quantity": new_available,
                        "buying_price": data['buying_price'],
                        "selling_price": data['selling_price'],
                        "updated_at": datetime.now()
                    }}
                )

                # Also add a new batch record for the added quantity
                batch_data = {
                    "product_id": str(existing_product['_id']),
                    "product_name": data['name'],
                    "purchase_date": datetime.now(),
                    "quantity_purchased": data['quantity'],
                    "quantity": data['quantity'],
                    "remaining": data['quantity'],
                    "cost_price": data['buying_price'],
                    "selling_price": data['selling_price'],
                    "shop_id": shop_id,
                    "added_by": user_email,
                    "added_by_id": user_id,
                    "added_at": datetime.now(),
                    "created_at": datetime.now(),
                    "is_initial_batch": False  # Not an initial batch since product exists
                }
                batch_result = batches_collection.insert_one(batch_data)
                
                # Recalculate product quantity after batch addition
                all_batches = list(batches_collection.find({"product_id": str(existing_product['_id'])}))
                total_quantity = sum(int(batch.get('quantity', 0)) for batch in all_batches)
                
                # Update with recalculated total to ensure consistency
                products_collection.update_one(
                    {"_id": existing_product['_id']},
                    {"$set": {
                        "quantity": total_quantity,
                        "available_quantity": total_quantity - current_on_hold
                    }}
                )
                
                return Response({
                    "message": "Product updated successfully",
                    "product_id": str(existing_product['_id']),
                    "batch_id": str(batch_result.inserted_id),
                    "total_quantity": total_quantity
                }, status=status.HTTP_200_OK)
            else:
                # Create new product
                product_data = {
                    "shop_id": shop_id,
                    "name": data['name'],
                    "quantity": data['quantity'],
                    "available_quantity": data['quantity'],  # Initialize available quantity
                    "quantity_on_hold": 0,  # Initialize on_hold quantity
                    "buying_price": data['buying_price'],
                    "selling_price": data['selling_price'],
                    "created_at": datetime.now(),
                    "updated_at": datetime.now(),
                    "created_by": user_email
                }

                result = products_collection.insert_one(product_data)
                product_id = str(result.inserted_id)

                # Always add a new batch record for the initial product quantity
                batch_data = {
                    "product_id": product_id,
                    "product_name": data['name'],
                    "purchase_date": datetime.now(),
                    "quantity_purchased": data['quantity'],
                    "quantity": data['quantity'],
                    "remaining": data['quantity'],
                    "cost_price": data['buying_price'],
                    "selling_price": data['selling_price'],
                    "shop_id": shop_id,
                    "added_by": user_email,
                    "added_by_id": user_id,
                    "added_at": datetime.now(),
                    "created_at": datetime.now(),
                    "is_initial_batch": True  # Mark this as an initial batch
                }
                batch_result = batches_collection.insert_one(batch_data)

                return Response({
                    "message": "Product added successfully",
                    "product_id": product_id,
                    "batch_id": str(batch_result.inserted_id)
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

        # Convert ObjectIds to strings for JSON serialization
        for product in products:
            product['_id'] = str(product['_id'])

        return Response(products)


class UpdateProductPriceView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Check if user is manager or owner
            if payload['role'] not in ['manager', 'owner']:
                return Response(
                    {"error": "Only managers and owners can update product prices"},
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

        # Add fields from the user document
        result["email"] = user_info.get("email", "")
        result["name"] = user_info.get("name", "")
        result["role"] = user_info.get("role", "")
        result["userId"] = user_info.get("employee_id", "")

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

        # Only allow updating own info or if owner
        requesting_user = users_collection.find_one({"_id": ObjectId(payload["user_id"])})

        if not requesting_user:
            return Response({"error": "User not found"}, 
                           status=status.HTTP_404_NOT_FOUND)

        # Check if the requesting user is the owner and is updating their own info
        is_owner_updating_self = requesting_user['role'] == 'owner' and str(requesting_user['_id']) == user_id

        # Only allow owner to update their own info or managers to update any user info
        if not (is_owner_updating_self or requesting_user['role'] == 'manager'):
            return Response({"error": "You don't have permission to update this user's information"}, 
                           status=status.HTTP_403_FORBIDDEN)

        # Get user to update
        user = users_collection.find_one({"_id": ObjectId(user_id)})
        if not user:
            return Response({"error": "User not found"}, 
                           status=status.HTTP_404_NOT_FOUND)

        # Get data from request
        data = request.data

        # Allow owners to update their own info regardless if it's already set
        # For regular users, check if info is already set
        user_has_info = "additional_info" in user and user["additional_info"] and "id_number" in user["additional_info"]
        if user_has_info and not is_owner_updating_self:
            return Response({"error": "User information can only be set once"}, 
                           status=status.HTTP_400_BAD_REQUEST)

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

        # Get the user
        user = users_collection.find_one({"_id": ObjectId(payload["user_id"])})

        # Check if the requesting user is the owner
        is_owner = user and user['role'] == 'owner'

        # Only owner or manager can update shop info
        if not user or user['role'] not in ['owner', 'manager']:
            return Response({"error": "Only shop owners and managers can update shop information"}, 
                           status=status.HTTP_403_FORBIDDEN)

        # Get shop to update
        shop = shops_collection.find_one({"shop_id": shop_id})
        if not shop:
            return Response({"error": "Shop not found"}, 
                           status=status.HTTP_404_NOT_FOUND)

        # Get data from request
        data = request.data

        # Check if shop info is already set
        shop_has_info = "additional_info" in shop and shop["additional_info"] and "shopCategory" in shop["additional_info"]

        # Allow owners to update shop info regardless if it's already set
        # For managers, check if info is already set
        if shop_has_info and not is_owner:
            return Response({"error": "Shop information can only be set once"}, 
                           status=status.HTTP_400_BAD_REQUEST)

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

class ImageUploadView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request):
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

        # Check if an image file is included in the request
        if 'image' not in request.FILES:
            return Response({"error": "No image file found in request"}, 
                           status=status.HTTP_400_BAD_REQUEST)

        image_file = request.FILES['image']

        # Check file extension and type
        valid_extensions = ['jpg', 'jpeg', 'png', 'gif']
        ext = image_file.name.split('.')[-1].lower()

        if ext not in valid_extensions:
            return Response({"error": "Invalid file extension. Allowed extensions: jpg, jpeg, png, gif"}, 
                           status=status.HTTP_400_BAD_REQUEST)

        # Create unique filename
        filename = f"{uuid.uuid4()}.{ext}"

        # Ensure the media directory exists
        media_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'media', 'uploads')
        os.makedirs(media_dir, exist_ok=True)

        # Save the file
        file_path = os.path.join(media_dir, filename)
        with open(file_path, 'wb+') as destination:
            for chunk in image_file.chunks():
                destination.write(chunk)

        # Generate URL for the image (get base URL from request or settings)
        base_url = request.build_absolute_uri('/').rstrip('/')
        image_url = f"{base_url}/media/uploads/{filename}"

        # Return the URL
        return Response({"imageUrl": image_url}, status=status.HTTP_200_OK)

# Database collections
batches_collection = db["batches"]
price_history_collection = db["price_history"]

# Create necessary indexes
batches_collection.create_index([("productId", ASCENDING)])
batches_collection.create_index([("purchaseDate", ASCENDING)])

# New classes for batch management
class BatchView(APIView):
    def get(self, request, product_id=None):
        # This is to handle the double slash issue in URL
        if product_id is None:
            return Response(
                {"error": "Product ID is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Rest of the code will be handled by BatchHistoryView
        return BatchHistoryView().get(request, product_id)

    def post(self, request, product_id):
        # Verify JWT token
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            user_id = payload.get('user_id', 'unknown')

            # Check if product exists
            product = products_collection.find_one({"_id": ObjectId(product_id)})
            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Extract batch data from request
            batch_data = request.data.copy()

            # Add required fields if not provided
            if 'shop_id' not in batch_data:
                batch_data['shop_id'] = shop_id
            if 'added_by' not in batch_data:
                batch_data['added_by'] = user_email
            if 'product_id' not in batch_data:
                batch_data['product_id'] = product_id
            if 'product_name' not in batch_data and 'name' in product:
                batch_data['product_name'] = product['name']
            
            # Add timestamp for batch creation
            batch_data['created_at'] = datetime.utcnow().isoformat()

            # Set default values for tracking
            if 'is_initial_batch' not in batch_data:
                batch_data['is_initial_batch'] = False
                
            # Ensure we have quantity and remaining values properly set
            quantity = int(batch_data.get('quantity', 0))
            
            # Set quantity_purchased if only quantity is provided
            if 'quantity_purchased' not in batch_data and 'quantity' in batch_data:
                batch_data['quantity_purchased'] = quantity
            
            # Set remaining to be equal to quantity if not specified
            if 'remaining' not in batch_data:
                batch_data['remaining'] = quantity

            # Insert the batch into batches collection
            batch_id = batches_collection.insert_one(batch_data).inserted_id
            
            # Get all batches for this product to recalculate total quantity
            all_batches = list(batches_collection.find({"product_id": product_id}))
            total_quantity = sum(int(batch.get('quantity', 0)) for batch in all_batches)
            
            # Also update the product's total quantity and available quantity
            current_quantity = int(product.get('quantity', 0))
            current_available = int(product.get('available_quantity', 0))
            current_on_hold = int(product.get('quantity_on_hold', 0))
            
            # Set the quantities to match the total from all batches
            new_quantity = total_quantity
            new_available = total_quantity - current_on_hold
            
            # Update product with new quantities
            products_collection.update_one(
                {"_id": ObjectId(product_id)},
                {
                    "$set": {
                        "quantity": new_quantity,
                        "available_quantity": new_available,
                        "updated_at": datetime.utcnow().isoformat()
                    }
                }
            )

            return Response(
                {
                    "batch_id": str(batch_id),
                    "message": "Batch added successfully",
                    "product_quantity_updated": {
                        "previous": current_quantity,
                        "new_total": new_quantity,
                        "all_batches_sum": total_quantity
                    }
                },
                status=status.HTTP_201_CREATED
            )

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

class BatchHistoryView(APIView):
    def get(self, request, product_id):
        # Verify JWT token
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']

        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            # Get the product
            try:
                product = products_collection.find_one({"_id": ObjectId(product_id)})
            except InvalidId:
                return Response(
                    {"error": "Invalid product ID format"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Check if product belongs to this shop
            if product['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get all batches for this product
            batches = list(batches_collection.find(
                {"product_id": product_id}
            ).sort("purchase_date", -1))  # Sort by purchase date, newest first

            # If no batches were found but the product exists, create a "virtual" initial batch
            # This handles cases where a product was created but no batch was recorded
            if not batches:
                print(f"No batches found for product {product_id}, creating virtual initial batch")
                virtual_batch = {
                    "_id": f"virtual_{product_id}",  # Create a virtual ID
                    "product_id": product_id,
                    "product_name": product.get('name', 'Unknown Product'),
                    "purchase_date": product.get('created_at', datetime.now().isoformat()),
                    "quantity_purchased": product.get('quantity', 0),
                    "quantity": product.get('quantity', 0),
                    "remaining": product.get('quantity', 0) - product.get('quantity_on_hold', 0),
                    "cost_price": product.get('buying_price', 0),
                    "selling_price": product.get('selling_price', 0),
                    "shop_id": shop_id,
                    "added_by": "System (Virtual Batch)",
                    "added_at": product.get('created_at', datetime.now().isoformat()),
                    "created_at": product.get('created_at', datetime.now().isoformat()),
                    "is_initial_batch": True,
                    "is_virtual": True
                }
                batches = [virtual_batch]
                
                # Also create a real batch with this data for future consistency
                virtual_batch_copy = virtual_batch.copy()
                virtual_batch_copy.pop('_id', None)  # Remove the virtual ID
                virtual_batch_copy.pop('is_virtual', None)  # Remove the virtual flag
                batches_collection.insert_one(virtual_batch_copy)
                print(f"Created real initial batch for product {product_id}")
            
            # Calculate total quantity from all batches
            total_quantity_from_batches = sum(int(batch.get('quantity', 0)) for batch in batches)
            
            # Check if the product quantity matches the sum of all batches
            product_quantity = product.get('quantity', 0)
            if product_quantity != total_quantity_from_batches:
                print(f"Warning: Product {product_id} quantity ({product_quantity}) doesn't match batch total ({total_quantity_from_batches})")
                
                # Update the product with the correct quantity
                quantity_on_hold = product.get('quantity_on_hold', 0)
                products_collection.update_one(
                    {"_id": ObjectId(product_id)},
                    {"$set": {
                        "quantity": total_quantity_from_batches,
                        "available_quantity": total_quantity_from_batches - quantity_on_hold,
                        "updated_at": datetime.now().isoformat()
                    }}
                )
                print(f"Updated product {product_id} quantity to match batch total: {total_quantity_from_batches}")
                
                # Also update the product object for this response
                product['quantity'] = total_quantity_from_batches
                product['available_quantity'] = total_quantity_from_batches - quantity_on_hold
            
            formatted_batches = []
            
            for batch in batches:
                try:
                    # Ensure all fields are present for frontend compatibility
                    formatted_batch = {
                        "_id": str(batch["_id"]),
                        "product_id": batch["product_id"],
                        "product_name": batch.get("product_name", product.get('name', 'Unknown Product')),
                        "quantity_purchased": batch.get("quantity_purchased", batch.get("quantity", 0)),
                        "remaining": batch.get("remaining", 0),
                        "cost_price": batch.get("cost_price", 0),
                        "purchase_date": batch.get("purchase_date", "").strftime("%Y-%m-%d") if isinstance(batch.get("purchase_date"), datetime) else batch.get("purchase_date", ""),
                        "shop_id": batch.get("shop_id", shop_id),
                        "created_at": batch.get("created_at", "").strftime("%Y-%m-%d") if isinstance(batch.get("created_at"), datetime) else batch.get("created_at", ""),
                        "selling_price": batch.get("selling_price", product.get("selling_price", 0)),
                        "is_initial_batch": batch.get("is_initial_batch", False),
                        "is_virtual": batch.get("is_virtual", False)
                    }
                    formatted_batches.append(formatted_batch)
                except Exception as e:
                    print(f"Error formatting batch {batch.get('_id', 'unknown')}: {e}")
                    # Attempt to include the batch anyway with a fallback structure
                    formatted_batches.append({
                        "_id": str(batch.get("_id", f"error_{len(formatted_batches)}")),
                        "product_id": product_id,
                        "product_name": product.get('name', 'Unknown Product'),
                        "quantity_purchased": batch.get("quantity", 0),
                        "remaining": batch.get("remaining", 0),
                        "cost_price": product.get("buying_price", 0),
                        "purchase_date": batch.get("purchase_date", datetime.now().strftime("%Y-%m-%d")),
                        "created_at": batch.get("created_at", datetime.now().strftime("%Y-%m-%d")),
                        "selling_price": product.get("selling_price", 0),
                        "is_initial_batch": True,
                        "error_in_formatting": True
                    })

            # Sort batches - initial batch first, then by date (oldest to newest)
            formatted_batches.sort(key=lambda x: (not x.get('is_initial_batch', False), x.get('purchase_date', '')))

            return Response(formatted_batches)

        except Exception as e:
            print(f"Error getting batch history: {e}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ProfitReportView(APIView):
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

            # Check permissions - only owner/manager can see profit reports
            role = payload.get('role', '')
            if role not in ['owner', 'manager']:
                return Response(
                    {"error": "Insufficient permissions"},
                    status=status.HTTP_403_FORBIDDEN
                )
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            # Get optional date range parameters
            start_date_str = request.query_params.get('start_date')
            end_date_str = request.query_params.get('end_date')

            match_query = {}

            if start_date_str or end_date_str:
                match_query["sale_date"] = {}

                if start_date_str:
                    start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
                    match_query["sale_date"]["$gte"] = start_date

                if end_date_str:
                    end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
                    # Set to end of day
                    end_date = datetime.combine(end_date, datetime.max.time())
                    match_query["sale_date"]["$lte"] = end_date

            # Get product lookup
            products = list(products_collection.find({"shop_id": shop_id}, {"_id": 1, "name": 1}))
            product_lookup = {str(product['_id']): product['name'] for product in products}

            # Get profit data overall
            pipeline = [
                {"$match": match_query},
                {"$group": {
                    "_id": None,
                    "totalSales": {"$sum": "$quantity"},
                    "totalRevenue": {"$sum": {"$multiply": ["$sale_price", "$quantity"]}},
                    "totalCost": {"$sum": {"$multiply": ["$cost_price", "$quantity"]}},
                    "totalProfit": {"$sum": "$profit"}
                }}
            ]

            overall_result = list(sales_collection.aggregate(pipeline))

            # Get profit data by product
            product_pipeline = [
                {"$match": match_query},
                {"$group": {
                    "_id": "$product_id",
                    "totalSales": {"$sum": "$quantity"},
                    "totalRevenue": {"$sum": {"$multiply": ["$sale_price", "$quantity"]}},
                    "totalCost": {"$sum": {"$multiply": ["$cost_price", "$quantity"]}},
                    "totalProfit": {"$sum": "$profit"}
                }}
            ]

            by_product_result = list(sales_collection.aggregate(product_pipeline))

            # Add product names
            for item in by_product_result:
                product_id = item['_id']
                item['product_name'] = product_lookup.get(product_id, 'Unknown Product')

            # Prepare response
            response_data = {
                "overall": overall_result[0] if overall_result else {
                    "totalSales": 0,
                    "totalRevenue": 0,
                    "totalCost": 0,
                    "totalProfit": 0
                },
                "by_product": by_product_result
            }

            return Response(response_data)

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class SaveInvoiceView(APIView):
    def post(self, request):
        try:
            # Verify JWT token
            token = request.headers.get('Authorization', '').replace('Bearer ', '')
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']

            data = request.data

            # Check if invoice with this number already exists - case insensitive check
            invoice_number = data.get('invoice_number', '').strip()
            if not invoice_number:
                return Response(
                    {"error": "Invoice number is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Use regex for case-insensitive search
            existing_invoice = invoices_collection.find_one({
                "shop_id": shop_id,
                "invoice_number": {"$regex": f"^{re.escape(invoice_number)}$", "$options": "i"}
            })

            if existing_invoice:
                # Generate a unique invoice number by appending a suffix
                next_num = 1
                base_invoice_number = invoice_number
                while existing_invoice:
                    invoice_number = f"{base_invoice_number}-{next_num}"
                    existing_invoice = invoices_collection.find_one({
                        "shop_id": shop_id,
                        "invoice_number": {"$regex": f"^{re.escape(invoice_number)}$", "$options": "i"}
                    })
                    next_num += 1

                # Update the invoice number in the data
                data['invoice_number'] = invoice_number

            # Ensure required fields exist
            required_fields = ['invoice_number', 'customer_name', 'items', 'total_amount']
            for field in required_fields:
                if field not in data:
                    return Response(
                        {"error": f"Missing required field: {field}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Safely get the final_amount with a default based on total_amount
            total_amount = float(data['total_amount'])
            discount_amount = float(data.get('discount_amount', 0))
            final_amount = total_amount - discount_amount

            if 'final_amount' in data and data['final_amount'] is not None:
                try:
                    final_amount = float(data['final_amount'])
                except (ValueError, TypeError):
                    # If there's a problem converting final_amount, use calculated value
                    pass

            # Create invoice document
            invoice_data = {
                "shop_id": shop_id,
                "invoice_number": invoice_number,
                "customer_name": data['customer_name'],
                "customer_address": data.get('customer_address', ''),
                "customer_phone": data.get('customer_phone', ''),
                "items": data['items'],
                "total_amount": total_amount,
                "discount_amount": discount_amount,
                "final_amount": final_amount,
                "status": "pending",
                "created_by": user_email,
                "created_at": datetime.now(),
                "updated_at": datetime.now()
            }

            # Update product quantities and on_hold values
            for item in data['items']:
                product_id = item['product_id']
                quantity = int(item['quantity'])

                # Decrease available quantity and increase on_hold
                result = products_collection.update_one(
                    {
                        "_id": ObjectId(product_id),
                        "quantity": {"$gte": quantity}  # Ensure sufficient quantity
                    },
                    {
                        "$inc": {
                            "quantity": -quantity,
                            "quantity_on_hold": quantity
                        }
                    }
                )

                if result.modified_count == 0:
                    # Rollback previous product updates if any
                    for prev_item in data['items'][:data['items'].index(item)]:
                        products_collection.update_one(
                            {"_id": ObjectId(prev_item['product_id'])},
                            {
                                "$inc": {
                                    "quantity": prev_item['quantity'],
                                    "quantity_on_hold": -prev_item['quantity']
                                }
                            }
                        )
                    return Response(
                        {"error": f"Insufficient quantity for product ID: {product_id}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Save the invoice
            result = invoices_collection.insert_one(invoice_data)

            return Response({
                "message": "Invoice saved successfully",
                "invoice_id": str(result.inserted_id),
                "invoice_number": invoice_number
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class GenerateInvoiceView(APIView):
    def post(self, request, invoice_id):
        try:
            # Verify JWT token
            token = request.headers.get('Authorization', '').replace('Bearer ', '')
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']

            # Get the pending invoice
            invoice = invoices_collection.find_one({"_id": ObjectId(invoice_id)})
            if not invoice:
                return Response(
                    {"error": "Invoice not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Check if invoice belongs to this shop
            if invoice['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Check if invoice is already completed
            if invoice['status'] == 'completed':
                return Response(
                    {"error": "Invoice is already completed"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Update invoice status to completed
            invoices_collection.update_one(
                {"_id": ObjectId(invoice_id)},
                {
                    "$set": {
                        "status": "completed",
                        "completed_by": user_email,
                        "completed_at": datetime.now(),
                        "updated_at": datetime.now()
                    }
                }
            )

            # Record sales and update product quantities
            for item in invoice['items']:
                product_id = item['product_id']
                quantity = int(item['quantity'])
                unit_price = float(item.get('unit_price', item.get('selling_price', 0)))
                total = float(item.get('total', quantity * unit_price))

                # Get product details for cost calculation
                product = products_collection.find_one({"_id": ObjectId(product_id)})
                if not product:
                    continue

                # Calculate profit
                cost_price = float(product.get('buying_price', 0))
                profit = (unit_price - cost_price) * quantity

                # Record the sale
                sale_data = {
                    "shop_id": shop_id,
                    "invoice_id": str(invoice_id),
                    "product_id": product_id,
                    "quantity": quantity,
                    "sale_price": unit_price,
                    "cost_price": cost_price,
                    "total_amount": total,
                    "profit": profit,
                    "sale_date": datetime.now(),
                    "created_by": user_email
                }
                sales_collection.insert_one(sale_data)

                # Get current on_hold quantity to avoid negative values
                on_hold = product.get('quantity_on_hold', 0)
                on_hold_update = min(quantity, on_hold)  # Ensure we don't reduce below zero

                # Update product quantity (remove from on_hold)
                products_collection.update_one(
                    {"_id": ObjectId(product_id)},
                    {"$inc": {"quantity_on_hold": -on_hold_update}}
                )

                # FIFO inventory management: deduct quantities from the oldest batches first
                remaining_to_deduct = quantity
                # Get batches ordered by date (oldest first)
                batches = list(batches_collection.find(
                    {"product_id": product_id, "remaining": {"$gt": 0}}
                ).sort("purchase_date", 1))  # Sort by purchase date, oldest first
                
                for batch in batches:
                    if remaining_to_deduct <= 0:
                        break
                    
                    batch_id = batch["_id"]
                    batch_remaining = batch.get("remaining", 0)
                    
                    if batch_remaining > 0:
                        # Calculate how much to deduct from this batch
                        deduct_from_batch = min(batch_remaining, remaining_to_deduct)
                        
                        # Update the batch
                        batches_collection.update_one(
                            {"_id": batch_id},
                            {"$inc": {"remaining": -deduct_from_batch}}
                        )
                        
                        # Adjust remaining to deduct
                        remaining_to_deduct -= deduct_from_batch

            return Response({
                "message": "Invoice generated successfully",
                "invoice_id": str(invoice_id)
            })

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class PriceHistoryView(APIView):
    def get(self, request, product_id=None):
        # If no product_id, return bad request
        if product_id is None:
            return Response(
                {"error": "Product ID is required for GET requests"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Verify JWT token
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            # Get the product
            try:
                product = products_collection.find_one({"_id": ObjectId(product_id)})
            except InvalidId:
                return Response(
                    {"error": "Invalid product ID format"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Check if product belongs to this shop
            if product['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get price history for this product
            price_history = list(price_history_collection.find(
                {"product_id": product_id}
            ).sort("change_date", -1))  # Sort by date, newest first

            # Format the response
            formatted_history = []
            for entry in price_history:
                formatted_entry = {
                    "id": str(entry["_id"]),
                    "old_price": entry["old_price"],
                    "new_price": entry["new_price"],
                    "changed_by": entry["changed_by"],
                    "change_date": entry["change_date"].strftime("%Y-%m-%d %H:%M:%S") if isinstance(entry["change_date"], datetime) else entry["change_date"]
                }
                formatted_history.append(formatted_entry)

            return Response(formatted_history)

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def post(self, request):
        # Verify JWT token
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            user_id = payload.get('user_id', 'unknown')
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            data = request.data

            # Validate required fields
            required_fields = ['product_id', 'old_price', 'new_price']
            for field in required_fields:
                if field not in data:
                    return Response(
                        {"error": f"Missing required field: {field}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Parse fields
            try:
                product_id = data['product_id']
                old_price = float(data['old_price'])
                new_price = float(data['new_price'])
            except (ValueError, KeyError, TypeError):
                return Response(
                    {"error": "Invalid price format"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Verify product exists and belongs to this shop
            try:
                product = products_collection.find_one({"_id": ObjectId(product_id)})
                if not product:
                    return Response(
                        {"error": "Product not found"},
                        status=status.HTTP_404_NOT_FOUND
                    )

                if product['shop_id'] != shop_id:
                    return Response(
                        {"error": "Unauthorized access to this product"},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except InvalidId:
                return Response(
                    {"error": "Invalid product ID format"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Parse change date
            changed_at = datetime.now()
            if 'changed_at' in data:
                try:
                    changed_at = datetime.fromisoformat(data['changed_at'].replace('Z', '+00:00'))
                except (ValueError, TypeError):
                    # Keep default changed_at time
                    pass

            # Add shop_id if missing
            if 'shop_id' not in data:
                data['shop_id'] = shop_id

            # Add user info if missing
            if 'changed_by' not in data:
                data['changed_by'] = user_email

            if 'changed_by_id' not in data:
                data['changed_by_id'] = user_id

            # Create price history document
            price_history_entry = {
                "product_id": product_id,
                "old_price": old_price,
                "new_price": new_price,
                "changed_by": data.get('changed_by', user_email),
                "changed_by_id": data.get('changed_by_id', user_id),
                "change_date": changed_at,
                "shop_id": data.get('shop_id', shop_id)
            }

            # Insert into price history
            result = price_history_collection.insert_one(price_history_entry)

            # Update product price only if it's not already at the new price
            if product.get('selling_price') != new_price:
                products_collection.update_one(
                    {"_id": ObjectId(product_id)},
                    {"$set": {"selling_price": new_price}}
                )

            return Response({
                "message": "Price history recorded successfully",
                "id": str(result.inserted_id)
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            print(f"Error recording price history: {e}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# New classes for offline sync
class OfflineBatchSyncView(APIView):
    def post(self, request):
        # Verify JWT token
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            user_id = payload.get('user_id', 'unknown')
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            # Get batches data from request
            batches = request.data.get('batches', [])
            if not batches or not isinstance(batches, list):
                return Response(
                    {"error": "No valid batches data provided"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            results = {
                "success": [],
                "failed": []
            }

            # Process each batch
            for batch_data in batches:
                try:
                    # Validate batch data
                    if not batch_data.get('product_id'):
                        results['failed'].append({
                            "data": batch_data,
                            "error": "Missing product_id"
                        })
                        continue

                    product_id = batch_data['product_id']

                    # Check if product exists and belongs to this shop
                    try:
                        product = products_collection.find_one({"_id": ObjectId(product_id)})
                        if not product:
                            results['failed'].append({
                                "data": batch_data,
                                "error": "Product not found"
                            })
                            continue

                        if product['shop_id'] != shop_id:
                            results['failed'].append({
                                "data": batch_data,
                                "error": "Unauthorized access to this product"
                            })
                            continue
                    except InvalidId:
                        results['failed'].append({
                            "data": batch_data,
                            "error": "Invalid product ID format"
                        })
                        continue

                    # Parse and validate the quantity and cost price
                    try:
                        quantity = int(batch_data['quantity'])
                        cost_price = float(batch_data['cost_price'])
                    except (ValueError, KeyError, TypeError):
                        results['failed'].append({
                            "data": batch_data,
                            "error": "Invalid quantity or cost_price format"
                        })
                        continue

                    # Parse purchase date
                    try:
                        if 'purchase_date' in batch_data:
                            purchase_date = datetime.strptime(batch_data['purchase_date'], '%Y-%m-%d')
                        else:
                            purchase_date = datetime.now()
                    except ValueError:
                        purchase_date = datetime.now()

                    # Add shop_id if missing
                    if 'shop_id' not in batch_data:
                        batch_data['shop_id'] = shop_id

                    # Add creation info if missing
                    if 'added_by' not in batch_data:
                        batch_data['added_by'] = user_email

                    if 'added_by_id' not in batch_data:
                        batch_data['added_by_id'] = user_id

                    if 'added_at' not in batch_data:
                        batch_data['added_at'] = datetime.now()

                    if 'created_at' not in batch_data:
                        batch_data['created_at'] = datetime.now()

                    # Add product name if missing
                    if 'product_name' not in batch_data:
                        batch_data['product_name'] = product.get('name', 'Unknown Product')

                    # Add remaining quantity if missing
                    if 'remaining' not in batch_data:
                        batch_data['remaining'] = quantity

                    # Insert batch into database
                    result = batches_collection.insert_one(batch_data)

                    # Update product quantity
                    # Get all batches for this product to calculate accurate total
                    all_batches = list(batches_collection.find({"product_id": product_id}))
                    total_quantity = sum(int(batch.get('quantity', 0)) for batch in all_batches)
                    
                    # Get current product details to calculate available quantity
                    product_details = products_collection.find_one({"_id": ObjectId(product_id)})
                    quantity_on_hold = product_details.get('quantity_on_hold', 0) if product_details else 0
                    
                    # Update product with recalculated quantities
                    products_collection.update_one(
                        {"_id": ObjectId(product_id)},
                        {
                            "$set": {
                                "quantity": total_quantity,
                                "available_quantity": total_quantity - quantity_on_hold,
                                "updated_at": datetime.now()
                            }
                        }
                    )

                    # If new selling price is provided, update it and log in price history
                    if 'new_selling_price' in batch_data and batch_data['new_selling_price']:
                        try:
                            new_selling_price = float(batch_data['new_selling_price'])
                            old_selling_price = product.get('selling_price', 0)

                            if new_selling_price != old_selling_price:
                                # Update product selling price
                                products_collection.update_one(
                                    {"_id": ObjectId(product_id)},
                                    {"$set": {"selling_price": new_selling_price}}
                                )

                                # Log price change
                                price_history_collection.insert_one({
                                    "product_id": product_id,
                                    "old_price": old_selling_price,
                                    "new_price": new_selling_price,
                                    "changed_by": user_email,
                                    "changed_by_id": user_id,
                                    "change_date": datetime.now(),
                                    "shop_id": shop_id
                                })
                        except ValueError:
                            # If there's an error with the selling price, just continue 
                            # with the batch addition
                            pass

                    # Add to success list
                    results['success'].append({
                        "data": batch_data,
                        "id": str(result.inserted_id)
                    })

                except Exception as e:
                    print(f"Error processing batch: {e}")
                    results['failed'].append({
                        "data": batch_data,
                        "error": str(e)
                    })

            return Response(results)

        except Exception as e:
            print(f"Error in offline batch sync: {e}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class OfflinePriceChangesSyncView(APIView):
    def post(self, request):
        # Verify JWT token
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            user_id = payload.get('user_id', 'unknown')
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            # Get price changes data from request
            price_changes = request.data.get('price_changes', [])
            if not price_changes or not isinstance(price_changes, list):
                return Response(
                    {"error": "No valid price changes data provided"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            results = {
                "success": [],
                "failed": []
            }

            # Process each price change
            for price_data in price_changes:
                try:
                    # Validate price change data
                    if not price_data.get('product_id'):
                        results['failed'].append({
                            "data": price_data,
                            "error": "Missing product_id"
                        })
                        continue

                    product_id = price_data['product_id']

                    # Parse price values
                    try:
                        old_price = float(price_data['old_price'])
                        new_price = float(price_data['new_price'])
                    except (ValueError, KeyError, TypeError):
                        results['failed'].append({
                            "data": price_data,
                            "error": "Invalid price format"
                        })
                        continue

                    # Check if product exists and belongs to this shop
                    try:
                        product = products_collection.find_one({"_id": ObjectId(product_id)})
                        if not product:
                            results['failed'].append({
                                "data": price_data,
                                "error": "Product not found"
                            })
                            continue

                        if product['shop_id'] != shop_id:
                            results['failed'].append({
                                "data": price_data,
                                "error": "Unauthorized access to this product"
                            })
                            continue
                    except InvalidId:
                        results['failed'].append({
                            "data": price_data,
                            "error": "Invalid product ID format"
                        })
                        continue

                    # Parse change date
                    changed_at = datetime.now()
                    if 'changed_at' in price_data:
                        try:
                            changed_at = datetime.fromisoformat(price_data['changed_at'].replace('Z', '+00:00'))
                        except (ValueError, TypeError):
                            # Keep default changed_at time
                            pass

                    # Add shop_id if missing
                    if 'shop_id' not in price_data:
                        price_data['shop_id'] = shop_id

                    # Add user info if missing
                    if 'changed_by' not in price_data:
                        price_data['changed_by'] = user_email

                    if 'changed_by_id' not in price_data:
                        price_data['changed_by_id'] = user_id

                    # Create price history document
                    price_history_entry = {
                        "product_id": product_id,
                        "old_price": old_price,
                        "new_price": new_price,
                        "changed_by": price_data.get('changed_by', user_email),
                        "changed_by_id": price_data.get('changed_by_id', user_id),
                        "change_date": changed_at,
                        "shop_id": price_data.get('shop_id', shop_id)
                    }

                    # Insert into price history
                    result = price_history_collection.insert_one(price_history_entry)

                    # Update product price only if it's not already at the new price
                    if product.get('selling_price') != new_price:
                        products_collection.update_one(
                            {"_id": ObjectId(product_id)},
                            {"$set": {"selling_price": new_price}}
                        )

                    # Add to success list
                    results['success'].append({
                        "data": price_data,
                        "id": str(result.inserted_id)
                    })

                except Exception as e:
                    print(f"Error processing price change: {e}")
                    results['failed'].append({
                        "data": price_data,
                        "error": str(e)
                    })

            return Response(results)

        except Exception as e:
            print(f"Error in offline price changes sync: {e}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# Add ProductDetailView class after the ProductView class
class ProductDetailView(APIView):
    # Get details of a specific product
    def get(self, request, product_id):
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

        try:
            # Check if product_id is a valid ObjectId
            if not is_valid_object_id(product_id):
                return Response(
                    {"error": "Invalid product ID format"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Get the product
            product = products_collection.find_one({"_id": ObjectId(product_id)})

            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Check if product belongs to this shop
            if product['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            # Verify and fix quantities if needed
            quantities_fixed = verify_product_quantities(product_id)
            
            # If quantities were fixed, refresh the product data
            if quantities_fixed:
                product = products_collection.find_one({"_id": ObjectId(product_id)})

            # Convert ObjectId to string for JSON serialization
            product['_id'] = str(product['_id'])

            return Response(product)
        except Exception as e:
            print(f"Error in ProductDetailView GET: {e}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def put(self, request, product_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            user_id = payload.get('user_id', None)
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            # Check if product_id is a valid ObjectId
            if not is_valid_object_id(product_id):
                return Response(
                    {"error": "Invalid product ID format"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Get the existing product
            product = products_collection.find_one({"_id": ObjectId(product_id)})

            if not product:
                return Response(
                    {"error": "Product not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Check if product belongs to this shop
            if product['shop_id'] != shop_id:
                return Response(
                    {"error": "Unauthorized access"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get update data
            update_data = request.data
            
            # Make sure required fields exist in the product object
            if 'quantity' not in product:
                product['quantity'] = 0
            if 'available_quantity' not in product:
                product['available_quantity'] = product['quantity']
            if 'quantity_on_hold' not in product:
                product['quantity_on_hold'] = 0
                
            # Update fields
            updated_product = {
                "updated_at": datetime.now()
            }
            
            # Process fields to update
            for field in ['name', 'buying_price', 'selling_price']:
                if field in update_data:
                    updated_product[field] = update_data[field]
            
            # For quantity fields, recalculate from batches
            if any(field in update_data for field in ['quantity', 'available_quantity', 'quantity_on_hold']):
                # If manual quantity update is requested, verify batch consistency first
                
                # Get all batches for this product
                all_batches = list(batches_collection.find({"product_id": product_id}))
                batches_total_quantity = sum(int(batch.get('quantity', 0)) for batch in all_batches)
                
                # If there's a quantity_on_hold update, use it
                quantity_on_hold = update_data.get('quantity_on_hold', product.get('quantity_on_hold', 0))
                
                # Set quantities based on batches and on-hold amount
                updated_product['quantity'] = batches_total_quantity
                updated_product['available_quantity'] = batches_total_quantity - quantity_on_hold
                updated_product['quantity_on_hold'] = quantity_on_hold
            
            # Check if selling price changed and log it in price history
            if 'selling_price' in update_data and update_data['selling_price'] != product.get('selling_price', 0):
                price_history_collection.insert_one({
                    "product_id": product_id,
                    "old_price": product.get('selling_price', 0),
                    "new_price": update_data['selling_price'],
                    "changed_by": user_email,
                    "changed_by_id": user_id,
                    "change_date": datetime.now(),
                    "shop_id": shop_id
                })
            
            # Update the product
            result = products_collection.update_one(
                {"_id": ObjectId(product_id)},
                {"$set": updated_product}
            )
            
            if result.modified_count == 0:
                # Document might not have been modified if no changes were necessary
                if result.matched_count == 0:
                    return Response(
                        {"error": "Failed to update product"},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
            
            # Get the updated product
            updated_product_doc = products_collection.find_one({"_id": ObjectId(product_id)})
            updated_product_doc['_id'] = str(updated_product_doc['_id'])
            
            return Response({
                "message": "Product updated successfully",
                "product": updated_product_doc
            })
        except Exception as e:
            print(f"Error in ProductDetailView PUT: {e}")
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def delete(self, request, product_id):
        # This is essentially the same as DeleteProductView for consistency
        return DeleteProductView().delete(request, product_id)

# Utility function to verify and fix product quantities
def verify_product_quantities(product_id):
    """Verify that product quantities match batch totals and fix if necessary."""
    try:
        # Get product
        product = products_collection.find_one({"_id": ObjectId(product_id)})
        if not product:
            print(f"Product {product_id} not found")
            return False
            
        # Get all batches
        all_batches = list(batches_collection.find({"product_id": product_id}))
        
        # Calculate total from batches
        total_quantity = sum(int(batch.get('quantity', 0)) for batch in all_batches)
        
        # Check if product quantity matches
        product_quantity = int(product.get('quantity', 0))
        quantity_on_hold = int(product.get('quantity_on_hold', 0))
        
        if product_quantity != total_quantity:
            print(f"Fixing quantity mismatch for product {product_id}: "
                  f"Product shows {product_quantity}, batches sum to {total_quantity}")
            
            # Update product with correct quantities
            products_collection.update_one(
                {"_id": ObjectId(product_id)},
                {"$set": {
                    "quantity": total_quantity,
                    "available_quantity": total_quantity - quantity_on_hold,
                    "updated_at": datetime.now().isoformat()
                }}
            )
            return True
        return False
    except Exception as e:
        print(f"Error in verify_product_quantities: {e}")
        return False