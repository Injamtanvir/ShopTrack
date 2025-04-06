import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Updated method with async keyword
  Future<dynamic> _handleApiResponse(http.Response response) async {
    try {
      // Check if response is HTML instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON. This usually indicates a server configuration or URL issue.');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'API error: ${response.statusCode}');
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body.substring(0, min(100, response.body.length))}');
        }
      }
    } catch (e) {
      print('API error: ${e.toString()}');
      rethrow;
    }
  }

  // Register a new shop
  Future<Map<String, dynamic>> registerShop({
    required String name,
    required String address,
    required String ownerName,
    required String licenseNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.registerShop),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'address': address,
        'owner_name': ownerName,
        'license_number': licenseNumber,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    return await _handleApiResponse(response);
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String shopId,
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login to: ${ApiConstants.login}');
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shop_id': shopId,
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');

      final data = await _handleApiResponse(response);

      // Save token and user data to secure storage
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'user', value: jsonEncode(data['user']));

      return data;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Register a sales person (admin only)
  Future<Map<String, dynamic>> registerSalesPerson({
    required String name,
    required String designation,
    required String sellerId,
    required String email,
    required String password,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.registerSalesPerson),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'designation': designation,
        'seller_id': sellerId,
        'email': email,
        'password': password,
      }),
    );

    return await _handleApiResponse(response);
  }

  // Register another admin (admin only)
  Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.registerAdmin),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return await _handleApiResponse(response);
  }



  // Add this method to your ApiService class
  Future<void> deleteProduct(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.deleteProduct}$productId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }

        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to delete product');
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }





  // Verify JWT token
  Future<bool> verifyToken() async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.verifyToken),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = await _handleApiResponse(response);
        return data['valid'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }

  // Get current user from storage
  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: 'user');

    if (userData == null) {
      return null;
    }

    return User.fromJson(jsonDecode(userData));
  }

  // Logout user
  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }

  // Add/update product
  Future<Map<String, dynamic>> addProduct({
    required String name,
    required int quantity,
    required double buyingPrice,
    required double sellingPrice,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Adding product to: ${ApiConstants.products}');
      final response = await http.post(
        Uri.parse(ApiConstants.products),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'quantity': quantity,
          'buying_price': buyingPrice,
          'selling_price': sellingPrice,
        }),
      );

      print('Response status: ${response.statusCode}');
      return await _handleApiResponse(response);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // Get all products
  Future<List<dynamic>> getProducts() async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConstants.products),
      headers: {'Authorization': 'Bearer $token'},
    );

    return await _handleApiResponse(response);
  }

  // Update product price (admin only)
  Future<Map<String, dynamic>> updateProductPrice({
    required String productId,
    required double sellingPrice,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.updateProductPrice),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'selling_price': sellingPrice,
      }),
    );

    return await _handleApiResponse(response);
  }

  // Get product price list
  Future<Map<String, dynamic>> getProductPriceList() async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConstants.productPriceList),
      headers: {'Authorization': 'Bearer $token'},
    );

    return await _handleApiResponse(response);
  }

  // Retry mechanism for failed API calls
  Future<T> retryRequest<T>(Future<T> Function() requestFunc, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await requestFunc();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
    throw Exception('Max retry attempts reached');
  }
}