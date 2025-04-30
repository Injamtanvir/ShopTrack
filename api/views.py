            # Ensure required fields exist
            required_fields = ['invoice_number', 'customer_name', 'items', 'total_amount']
            for field in required_fields:
                if field not in data:
                    return Response(
                        {"error": f"Missing required field: {field}"},
                        status=status.HTTP_400_BAD_REQUEST
                    ) 