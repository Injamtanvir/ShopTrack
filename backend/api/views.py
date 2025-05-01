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


class AdminRegistrationView(APIView):
    def post(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            # Only owner can register admins/managers
            if payload['role'] != 'owner':
                return Response(
                    {"error": "Only owners can register managers"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Get shop_id from token
            shop_id = payload['shop_id']
            owner_email = payload['email']
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

            # Create manager/admin user
            user_data = {
                "shop_id": shop_id,
                "name": data['name'],
                "email": data['email'],
                "password": hash_password(data['password']),
                "role": "manager",  # Set role as manager
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
                "created_by": owner_email
            }
            
            result = users_collection.insert_one(user_data)
            
            return Response({
                "message": "Manager registered successfully",
                "user_id": str(result.inserted_id)
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


class DeleteProductView(APIView):
    def delete(self, request, product_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            user_email = payload['email']
            role = payload.get('role', '')

            # Allow both managers and owners to delete products
            if role not in ['manager', 'owner']:
                return Response(
                    {"error": "Only managers or owners can delete products"},
                    status=status.HTTP_403_FORBIDDEN
                )

        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            print(f"Attempting to delete product {product_id} by user {user_email} with role {role}")
            
            # First attempt - try with ObjectId
            product = None
            delete_id = None
            try:
                object_id = ObjectId(product_id)
                product = products_collection.find_one({"_id": object_id})
                if product:
                    print(f"Found product with ObjectId: {product.get('name', 'Unknown')}")
                    delete_id = object_id
            except InvalidId:
                print(f"Product ID {product_id} is not a valid ObjectId format")
            except Exception as e:
                print(f"Error when searching with ObjectId: {str(e)}")
            
            # Second attempt - try with string ID
            if not product:
                try:
                    product = products_collection.find_one({"_id": product_id})
                    if product:
                        print(f"Found product with string ID: {product.get('name', 'Unknown')}")
                        delete_id = product_id
                except Exception as e:
                    print(f"Error when searching with string ID: {str(e)}")
            
            # Third attempt - try looking up by name in this shop
            if not product:
                try:
                    # Try searching by shop_id and looking for product ID in other fields
                    shop_products = list(products_collection.find({"shop_id": shop_id}))
                    print(f"Found {len(shop_products)} products for shop {shop_id}")
                    
                    for p in shop_products:
                        # Check if any field matches the product_id
                        if (str(p.get('_id', '')) == product_id or 
                            p.get('id', '') == product_id or 
                            p.get('product_id', '') == product_id):
                            product = p
                            delete_id = p['_id']
                            print(f"Found product by field comparison: {product.get('name', 'Unknown')}")
                            break
                except Exception as e:
                    print(f"Error during shop products search: {str(e)}")

            # If product is still not found, return error
            if not product:
                return Response(
                    {"error": f"Product not found with ID: {product_id}"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Check if the product belongs to this shop
            if product.get('shop_id') != shop_id:
                return Response(
                    {"error": "Unauthorized access - product belongs to a different shop"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Store product info for response
            product_name = product.get('name', 'Unknown Product')
            
            # Delete the product
            print(f"Deleting product with ID type {type(delete_id).__name__}: {delete_id}")
            try:
                result = products_collection.delete_one({"_id": delete_id})
                print(f"Product deletion result: {result.deleted_count} document(s) deleted")
            except Exception as e:
                print(f"Error during product deletion: {str(e)}")
                # Try with string ID if ObjectId failed
                if isinstance(delete_id, ObjectId):
                    try:
                        str_id = str(delete_id)
                        result = products_collection.delete_one({"_id": str_id})
                        print(f"Fallback deletion with string ID: {result.deleted_count} document(s) deleted")
                    except Exception as nested_e:
                        print(f"Error during fallback deletion: {str(nested_e)}")
                        result = None
            
            # Convert product_id to string for related collections
            product_id_str = str(delete_id) if isinstance(delete_id, ObjectId) else product_id
            
            # Delete batches - try both string and ObjectId formats
            batches_deleted = 0
            try:
                # Try with string ID
                batch_result = batches_collection.delete_many({"product_id": product_id_str})
                batches_deleted += batch_result.deleted_count
                print(f"Deleted {batch_result.deleted_count} batches with string product_id")
                
                # Try with ObjectId if possible
                try:
                    obj_id = ObjectId(product_id_str)
                    batch_result = batches_collection.delete_many({"product_id": obj_id})
                    batches_deleted += batch_result.deleted_count
                    print(f"Deleted {batch_result.deleted_count} batches with ObjectId product_id")
                except (InvalidId, Exception) as e:
                    print(f"Skip ObjectId batch deletion: {str(e)}")
            except Exception as e:
                print(f"Error deleting batches: {str(e)}")
            
            # Delete sales records - try both formats
            sales_deleted = 0
            try:
                # Try with string ID
                sales_result = sales_collection.delete_many({"product_id": product_id_str})
                sales_deleted += sales_result.deleted_count
                print(f"Deleted {sales_result.deleted_count} sales with string product_id")
                
                # Try with ObjectId if possible
                try:
                    obj_id = ObjectId(product_id_str)
                    sales_result = sales_collection.delete_many({"product_id": obj_id})
                    sales_deleted += sales_result.deleted_count
                    print(f"Deleted {sales_result.deleted_count} sales with ObjectId product_id")
                except (InvalidId, Exception) as e:
                    print(f"Skip ObjectId sales deletion: {str(e)}")
            except Exception as e:
                print(f"Error deleting sales: {str(e)}")
            
            # Delete price history
            price_history_deleted = 0
            try:
                # Try with string ID
                ph_result = price_history_collection.delete_many({"product_id": product_id_str})
                price_history_deleted += ph_result.deleted_count
                print(f"Deleted {ph_result.deleted_count} price history records with string product_id")
                
                # Try with ObjectId if possible
                try:
                    obj_id = ObjectId(product_id_str)
                    ph_result = price_history_collection.delete_many({"product_id": obj_id})
                    price_history_deleted += ph_result.deleted_count
                    print(f"Deleted {ph_result.deleted_count} price history records with ObjectId product_id")
                except (InvalidId, Exception) as e:
                    print(f"Skip ObjectId price history deletion: {str(e)}")
            except Exception as e:
                print(f"Error deleting price history: {str(e)}")

            return Response({
                "message": f"Product '{product_name}' and related data deleted successfully",
                "batches_deleted": batches_deleted,
                "sales_deleted": sales_deleted,
                "price_history_deleted": price_history_deleted
            })

        except Exception as e:
            error_message = f"Error deleting product: {str(e)}"
            print(error_message)
            import traceback
            print(traceback.format_exc())
            return Response(
                {"error": error_message},
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


class ShopUsersView(APIView):
    def get(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            shop_id = payload['shop_id']
            role = payload.get('role', '')
            
            # Only managers and owners can see all shop users
            if role not in ['manager', 'owner']:
                return Response(
                    {"error": "Only managers and owners can view all shop users"},
                    status=status.HTTP_403_FORBIDDEN
                )
                
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        try:
            # Find all users for this shop
            users = list(users_collection.find({"shop_id": shop_id}))
            
            # Convert ObjectId to string for each user
            for user in users:
                user['_id'] = str(user['_id'])
                
                # Remove password field for security
                if 'password' in user:
                    del user['password']
                    
                # Convert date objects to ISO format strings
                if 'date_of_birth' in user and user['date_of_birth']:
                    if isinstance(user['date_of_birth'], (datetime, date)):
                        user['date_of_birth'] = user['date_of_birth'].isoformat()
                        
                if 'created_at' in user and user['created_at']:
                    if isinstance(user['created_at'], datetime):
                        user['created_at'] = user['created_at'].isoformat()
                        
                if 'updated_at' in user and user['updated_at']:
                    if isinstance(user['updated_at'], datetime):
                        user['updated_at'] = user['updated_at'].isoformat()
            
            return Response(users)
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class VerifyTokenView(APIView):
    def get(self, request):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            # Attempt to decode the token
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            
            # If we get here, token is valid
            return Response({
                "valid": True,
                "user_id": payload.get('user_id', ''),
                "email": payload.get('email', ''),
                "role": payload.get('role', ''),
                "shop_id": payload.get('shop_id', '')
            })
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError) as e:
            return Response({
                "valid": False,
                "error": str(e)
            }, status=status.HTTP_200_OK)  # Still return 200 to allow client to handle this gracefully
        except Exception as e:
            return Response({
                "valid": False,
                "error": f"Unknown error: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)