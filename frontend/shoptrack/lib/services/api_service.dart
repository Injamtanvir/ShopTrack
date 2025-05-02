import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import '../services/product_service.dart';

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
    required String ownerPhone,
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
        'owner_phone': ownerPhone,
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
    required String employeeId,
    required String email,
    required String password,
    String? imageBase64,
    required String idNumber,
    required DateTime dateOfBirth,
    required String address,
    required String phoneNumber,
    required double salary,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    // Format the date as YYYY-MM-DD
    final formattedDate = "${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";

    final response = await http.post(
      Uri.parse(ApiConstants.registerSalesPerson),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'designation': designation,
        'employee_id': employeeId,
        'email': email,
        'password': password,
        'image_base64': imageBase64,
        'id_number': idNumber,
        'date_of_birth': formattedDate,
        'address': address,
        'phone_number': phoneNumber,
        'salary': salary,
      }),
    );

    return await _handleApiResponse(response);
  }

  // Register another admin (admin only)
  Future<Map<String, dynamic>> registerManager({
    required String name,
    required String designation,
    required String employeeId,
    required String email,
    required String password,
    String? imageBase64,
    required String idNumber,
    required DateTime dateOfBirth,
    required String address,
    required String phoneNumber,
    required double salary,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    // Format the date as YYYY-MM-DD string instead of DateTime object
    final formattedDate = "${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}";

    print('Registering manager at: ${ApiConstants.registerManager}');
    print('Using token: ${token.substring(0, 20)}... (truncated)');
    print('Sending data with date: $formattedDate');

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerManager),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'designation': designation,
          'employee_id': employeeId,
          'email': email,
          'password': password,
          'image_base64': imageBase64,
          'id_number': idNumber,
          'date_of_birth': formattedDate, // Send as string, not DateTime object
          'address': address,
          'phone_number': phoneNumber,
          'salary': salary,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');

      return await _handleApiResponse(response);
    } catch (e) {
      print('Error registering manager: $e');
      rethrow;
    }
  }

  // Add this method to your ApiService class
  Future<void> deleteProduct(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }
    
    print('Attempting to delete product with ID: $productId');
    
    // Use the function properly instead of concatenation
    final deleteUrl = ApiConstants.deleteProduct(productId);
    print('Using URL: $deleteUrl');
    
    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Delete product response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Product successfully deleted');
        return; // Successfully deleted
      } else {
        // Try to parse error from response
        try {
          final errorData = jsonDecode(response.body);
          print('Server error response: $errorData');
          throw Exception(errorData['error'] ?? 'Failed to delete product: ${response.statusCode}');
        } catch (parseError) {
          print('Error parsing error response: $parseError');
          throw Exception('Failed to delete product: ${response.statusCode}. Response: ${response.body}');
        }
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Error deleting product: $e');
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

  // Get token from storage
  Future<String> getToken() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }
    return token;
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
      // Import ProductService dynamically to avoid circular dependency
      final productService = ProductService();
      
      // Use ProductService to add product with offline support
      final productId = await productService.addProduct({
        'name': name,
        'quantity': quantity,
        'buying_price': buyingPrice,
        'selling_price': sellingPrice,
        'cost_price': buyingPrice, // Also include cost_price for batch creation
      });
      
      // Check if productId indicates offline mode (could be String or Map)
      final String productIdStr = productId is Map 
          ? (productId['_id'] ?? productId['product_id'] ?? '') 
          : productId.toString();
          
      if (productIdStr.startsWith('offline_product_') || productIdStr.startsWith('mock_product_')) {
        // Return offline product data with success message
        return {
          'product_id': productIdStr,
          'message': 'Product added in offline mode. Changes will be synced when connection is restored.',
          'offline': true
        };
      }
      
      // Return normal success response
      return {
        'product_id': productIdStr,
        'message': 'Product added successfully',
        'offline': false
      };
    } catch (e) {
      print('Error adding product: $e');
      
      // Check if the error is about HTML response
      if (e.toString().contains('HTML')) {
        throw Exception('Server returned HTML instead of JSON. This usually indicates a server configuration or URL issue.');
      }
      
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
    
    // Get current user to find shop ID
    final user = await getCurrentUser();
    final shopId = user?.shopId ?? '';

    try {
      // Use shop-specific endpoint if available
      final endpoint = ApiConstants.getProductPriceList(shopId);
      print('Fetching price list from: $endpoint');
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Price list response status: ${response.statusCode}');
      
      // Check if we have a 404 or other error status
      if (response.statusCode != 200) {
        // Try fallback endpoints if main endpoint fails
        if (response.statusCode == 404) {
          print('Primary endpoint not found, trying alternatives...');
          
          // Try alternate endpoints
          final alternateEndpoints = [
            '${ApiConstants.baseUrl}/price-list/',
            '${ApiConstants.baseUrl}/products/price-list/',
            '${ApiConstants.baseUrl}/product-list/',
            '${ApiConstants.baseUrl}/product-price-list/',
          ];
          
          for (final altEndpoint in alternateEndpoints) {
            print('Trying alternate endpoint: $altEndpoint');
            final altResponse = await http.get(
              Uri.parse(altEndpoint),
              headers: {'Authorization': 'Bearer $token'},
            );
            
            print('Alternate endpoint response: ${altResponse.statusCode}');
            
            if (altResponse.statusCode == 200) {
              try {
                return jsonDecode(altResponse.body);
              } catch (e) {
                print('Failed to parse response from alternate endpoint: $e');
              }
            }
          }
          
          throw Exception('Product price list endpoint not found (404). Please check if the API endpoint is correct or the server is running.');
        }
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
      
      // Check if response is HTML instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        // Log the first 100 characters of the response for debugging
        print('HTML response received. First 100 chars: ${response.body.substring(0, min(100, response.body.length))}');
        
        // Try to retry once after a short delay
        print('Received HTML response instead of JSON. Retrying after delay...');
        await Future.delayed(Duration(seconds: 2));
        
        final retryResponse = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        // Check if retry was successful
        if (retryResponse.statusCode != 200 || 
            retryResponse.body.trim().startsWith('<!DOCTYPE') || 
            retryResponse.body.trim().startsWith('<html')) {
          throw Exception('Server returned HTML instead of JSON after retry. Please check your network connection or try again later.');
        }
        
        try {
          return jsonDecode(retryResponse.body);
        } catch (e) {
          throw Exception('Failed to parse price list data after retry: $e');
        }
      }

      // Normal JSON response handling
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Failed to parse price list data: $e');
      }
    } catch (e) {
      print('Error fetching price list: $e');
      rethrow;
    }
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

  // Get all users for the shop
  Future<List<dynamic>> getShopUsers() async {
    final token = await _storage.read(key: 'token') ?? '';

    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConstants.getShopUsers),
      headers: {'Authorization': 'Bearer $token'},
    );

    return await _handleApiResponse(response);
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.deleteUser}$userId/'),
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
          throw Exception(errorData['error'] ?? 'Failed to delete user');
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Debug method to check API structure
  Future<void> debugApiEndpoints() async {
    final token = await _storage.read(key: 'token') ?? '';
    
    if (token.isEmpty) {
      print('No token available for debugging');
      return;
    }
    
    print('===== DEBUGGING API ENDPOINTS =====');
    
    // List of potential endpoints to check
    final endpoints = [
      '/api',
      '/api/products',
      '/api/price-list',
      '/api/products/price-list',
      '/api/product-price-list',
    ];
    
    for (final endpoint in endpoints) {
      try {
        final baseUrl = 'https://shoptrack-w8wu.onrender.com';
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        print('Endpoint: $endpoint - Status: ${response.statusCode}');
      } catch (e) {
        print('Error checking endpoint $endpoint: $e');
      }
    }
    
    print('===== END DEBUGGING =====');
  }

  // Generate mock price list data when API is unavailable
  Future<Map<String, dynamic>> getMockPriceListData() async {
    final user = await getCurrentUser();
    
    // Create a sample product list with realistic data
    final sampleProducts = [
      {
        'id': '1',
        'name': 'Sample Product 1',
        'quantity': 10,
        'selling_price': 100.0,
        'buying_price': 80.0,
      },
      {
        'id': '2',
        'name': 'Sample Product 2',
        'quantity': 5,
        'selling_price': 200.0,
        'buying_price': 150.0,
      },
      {
        'id': '3',
        'name': 'Sample Product 3',
        'quantity': 0,
        'selling_price': 300.0,
        'buying_price': 250.0,
      },
      {
        'id': '4',
        'name': 'Sample Product 4',
        'quantity': 20,
        'selling_price': 50.0,
        'buying_price': 30.0,
      },
    ];
    
    // Create a mock price list structure matching expected format
    return {
      'shop_id': user?.shopId ?? 'Sample-Shop',
      'shop_name': user?.shopName ?? 'Sample Shop Name',
      'shop_address': 'Sample Shop Address, City',
      'products': sampleProducts,
    };
  }
}