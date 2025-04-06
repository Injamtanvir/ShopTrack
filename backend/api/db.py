import pymongo
from django.conf import settings
import random
import string
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime
import jwt
import os
from bson.objectid import ObjectId

# JWT Secret key
JWT_SECRET = os.getenv('SECRET_KEY', '1XRG32NbM@nuva7022')

# MongoDB connection
client = pymongo.MongoClient(settings.MONGODB_URI)
db = client[settings.MONGODB_DB]

# Collections
shops_collection = db["shops"]
users_collection = db["users"]
products_collection = db["products"]
invoices_collection = db["invoices"]

def generate_shop_id():
    """Generate a unique 8-digit shop ID"""
    while True:
        # Generate random 8-digit number
        shop_id = ''.join(random.choices(string.digits, k=8))
        # Check if it already exists
        if not shops_collection.find_one({"shop_id": shop_id}):
            return shop_id

# Get next invoice number
class NextInvoiceNumberView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check if the shop ID in the request matches the shop ID in the token
        if shop_id != payload['shop_id']:
            return Response(
                {"error": "Unauthorized access"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get the last invoice number from the shop
        latest_invoice = invoices_collection.find_one(
            {"shop_id": shop_id},
            sort=[("invoice_number", -1)]  # Sort by invoice_number in descending order
        )

        # Generate a new 6-digit invoice number
        if latest_invoice:
            try:
                # If the invoice number is already a 6-digit number, increment it
                last_number = int(latest_invoice['invoice_number'])
                next_number = str(last_number + 1).zfill(6)  # Pad with leading zeros
            except ValueError:
                # If it's not a valid number, start from 000001
                next_number = "000001"
        else:
            # If no invoices exist, start from 000001
            next_number = "000001"

        return Response({"next_invoice_number": next_number})

# Save invoice (as pending)
class SaveInvoiceView(APIView):
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

        # Check if the shop ID in the request matches the shop ID in the token
        if request.data['shop_id'] != shop_id:
            return Response(
                {"error": "Unauthorized access"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Create the invoice document
        # invoice_data = {
        #     "invoice_number": request.data['invoice_number'],
        #     "shop_id": shop_id,
        #     "shop_name": request.data['shop_name'],
        #     "shop_address": request.data['shop_address'],
        #     "shop_license": request.data['shop_license'],
        #     "customer_name": request.data['customer_name'],
        #     "customer_address": request.data['customer_address'],
        #     "date": request.data['date'],
        #     "items": request.data['items'],
        #     "total_amount": request.data['total_amount'],
        #     "status": request.data['status'],  # 'pending' or 'completed'
        #     "created_by": user_email,
        #     "created_at": datetime.now(),
        #     "updated_at": datetime.now()
        # }



        invoice_data = {
            "invoice_number": request.data['invoice_number'],
            "shop_id": shop_id,
            "shop_name": request.data['shop_name'],
            "shop_address": request.data['shop_address'],
            "shop_license": request.data['shop_license'],
            "customer_name": request.data['customer_name'],
            "customer_address": request.data['customer_address'],
            "date": request.data['date'],
            "items": request.data['items'],
            "subtotal_amount": request.data['subtotal_amount'],
            "discount_amount": request.data['discount_amount'],
            "total_amount": request.data['total_amount'],
            "status": request.data['status'],  # 'pending' or 'completed'
            "created_by": user_email,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }


        # Insert the invoice
        result = invoices_collection.insert_one(invoice_data)

        return Response({
            "message": "Invoice saved successfully",
            "invoice_id": str(result.inserted_id)
        }, status=status.HTTP_201_CREATED)

# Generate invoice (update product quantities and change status)
class GenerateInvoiceView(APIView):
    def post(self, request, invoice_id):
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
                    {"error": "Invoice already completed"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Update product quantities - with additional error handling
            for item in invoice['items']:
                product_id = item['product_id']
                quantity = item['quantity']

                # Get the product with proper error handling
                try:
                    product = products_collection.find_one({"_id": ObjectId(product_id)})
                except Exception as e:
                    return Response(
                        {"error": f"Invalid product ID {product_id}: {str(e)}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

                if not product:
                    return Response(
                        {"error": f"Product {product_id} not found"},
                        status=status.HTTP_404_NOT_FOUND
                    )

                # Check if there's enough quantity
                if product['quantity'] < quantity:
                    return Response(
                        {"error": f"Not enough quantity for product {product['name']}. Available: {product['quantity']}, Requested: {quantity}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Update the product quantity
                new_quantity = product['quantity'] - quantity
                result = products_collection.update_one(
                    {"_id": ObjectId(product_id)},
                    {"$set": {
                        "quantity": new_quantity,
                        "updated_at": datetime.now()
                    }}
                )
                
                # Verify update was successful
                if result.modified_count == 0:
                    return Response(
                        {"error": f"Failed to update quantity for product {product['name']}"},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )

            # Update the invoice status to completed
            result = invoices_collection.update_one(
                {"_id": ObjectId(invoice_id)},
                {"$set": {
                    "status": "completed",
                    "updated_at": datetime.now(),
                    "completed_by": user_email
                }}
            )

            if result.modified_count == 0:
                return Response(
                    {"error": "Failed to update invoice status"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            return Response({
                "message": "Invoice generated successfully",
                "invoice_id": invoice_id
            })

        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# Get pending invoices
class PendingInvoicesView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check if the shop ID in the request matches the shop ID in the token
        if shop_id != payload['shop_id']:
            return Response(
                {"error": "Unauthorized access"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all pending invoices for this shop
        pending_invoices = list(invoices_collection.find({
            "shop_id": shop_id,
            "status": "pending"
        }).sort("created_at", -1))  # Sort by created_at in descending order

        # Convert ObjectId to string for JSON serialization
        for invoice in pending_invoices:
            invoice['_id'] = str(invoice['_id'])

        return Response(pending_invoices)

# Get invoice history (completed invoices)
class InvoiceHistoryView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check if the shop ID in the request matches the shop ID in the token
        if shop_id != payload['shop_id']:
            return Response(
                {"error": "Unauthorized access"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all completed invoices for this shop
        completed_invoices = list(invoices_collection.find({
            "shop_id": shop_id,
            "status": "completed"
        }).sort("created_at", -1))  # Sort by created_at in descending order

        # Convert ObjectId to string for JSON serialization
        for invoice in completed_invoices:
            invoice['_id'] = str(invoice['_id'])

        return Response(completed_invoices)

# Get a specific invoice by ID
class InvoiceDetailView(APIView):
    def get(self, request, invoice_id):
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

        # Convert ObjectId to string for JSON serialization
        invoice['_id'] = str(invoice['_id'])

        return Response(invoice)

# Search products by name (for autocomplete)
class SearchProductsView(APIView):
    def get(self, request, shop_id):
        # Verify JWT token from headers
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return Response(
                {"error": "Invalid or expired token"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check if the shop ID in the request matches the shop ID in the token
        if shop_id != payload['shop_id']:
            return Response(
                {"error": "Unauthorized access"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get the search query
        query = request.GET.get('query', '')
        if not query:
            return Response([])

        # Search for products with names matching the query
        products = list(products_collection.find({
            "shop_id": shop_id,
            "name": {"$regex": query, "$options": "i"}  # Case insensitive search
        }).limit(10))  # Limit to 10 results

        # Convert ObjectId to string for JSON serialization
        for product in products:
            product['_id'] = str(product['_id'])

        return Response(products)