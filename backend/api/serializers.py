from rest_framework import serializers

class ShopRegistrationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    address = serializers.CharField(max_length=200)
    owner_name = serializers.CharField(max_length=100)
    license_number = serializers.CharField(max_length=50)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)
    confirm_password = serializers.CharField(min_length=6, write_only=True)

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        return data

class UserLoginSerializer(serializers.Serializer):
    shop_id = serializers.CharField(max_length=8)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)

class SalesPersonRegistrationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    designation = serializers.CharField(max_length=100)
    seller_id = serializers.CharField(max_length=50)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)

class AdminRegistrationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)


class ProductSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    quantity = serializers.IntegerField(min_value=0)
    buying_price = serializers.FloatField(min_value=0)
    selling_price = serializers.FloatField(min_value=0)

class UpdateProductPriceSerializer(serializers.Serializer):
    product_id = serializers.CharField()
    selling_price = serializers.FloatField(min_value=0)