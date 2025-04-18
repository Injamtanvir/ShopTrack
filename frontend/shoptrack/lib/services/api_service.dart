import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Network Timout For My Render Free set to
  static const Duration requestTimeout = Duration(seconds: 100);

  // Handle API response
  Future<dynamic> _handleApiResponse(http.Response response) async {
    try {
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html>')) {
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
      // print('API error: ${e.toString()}');
      rethrow;
    }
  }

  String _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return 'Invalid token format';
      }

      final payload = parts[1];
      String normalized = payload;
      if (payload.length % 4 > 0) {
        normalized = payload + '=' * (4 - payload.length % 4);
      }

      final decoded = utf8.decode(base64Url.decode(normalized));
      return decoded;
    } catch (e) {
      return 'Error decoding token: $e';
    }
  }

  // Improved error handling for network requests
  Future<dynamic> _safeApiCall(Future<http.Response> Function() apiCall) async {
    try {
      final response = await apiCall().timeout(requestTimeout);
      return await _handleApiResponse(response);
    } on SocketException {
      throw Exception('Network error: Unable to connect to the server. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Network timeout: The server took too long to respond. Please try again later.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}. Please check your connection and try again.');
    } catch (e) {
      rethrow;
    }
  }

  // Register a new shop with improved error handling
  Future<Map<String, dynamic>> registerShop({
    required String name,
    required String address,
    required String ownerName,
    required String licenseNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // print('Registering shop with name: $name, email: $email');

    try {
      return await _safeApiCall(() => http.post(
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
      ));
    } catch (e) {
      // print('Shop registration error: $e');
      rethrow;
    }
  }

  // Register a sales person with improved error handling
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

    // print('Sending register sales person request with token: ${token.substring(0, min(20, token.length))}...');
    // print('Token payload: ${_decodeToken(token)}');

    try {
      return await _safeApiCall(() => http.post(
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
      ));
    } catch (e) {
      // print('Error registering sales person: $e');
      rethrow;
    }
  }

  // Register admin with improved error handling
  Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    // print('Sending register admin request with token: ${token.substring(0, min(20, token.length))}...');
    // print('Token payload: ${_decodeToken(token)}');

    try {
      return await _safeApiCall(() => http.post(
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
      ));
    } catch (e) {
      // print('Error registering admin: $e');
      rethrow;
    }
  }

  // Delete product with improved error handling
  Future<void> deleteProduct(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      await _safeApiCall(() => http.delete(
        Uri.parse('${ApiConstants.deleteProduct}$productId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ));
    } catch (e) {
      // print('Error deleting product: $e');
      rethrow;
    }
  }

  // Verify JWT token with improved error handling
  Future<bool> verifyToken() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      // print('No token found in storage');
      return false;
    }

    try {
      // print('Verifying token: ${token.length > 20 ? token.substring(0, 20) + '...' : token}');

      final response = await http.get(
        Uri.parse(ApiConstants.verifyToken),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      // print('Token verification response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = await _handleApiResponse(response);

        // print('Token valid: ${data['valid']}');
        if (data['valid'] == true && data.containsKey('user')) {
          print('User role from token: ${data['user']['role']}');
        }

        return data['valid'] == true;
      } else {
        // print('Token verification failed with status: ${response.statusCode}');
        return false;
      }
    } on SocketException {
      // print('Network error during token verification');
      return false;
    } on TimeoutException {
      // print('Timeout during token verification');
      return false;
    } catch (e) {
      // print('Token verification error: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    // print('Logging out user');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    // print('User logged out, storage cleared');
  }

  // Add/update product with improved error handling
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
      // print('Adding product to: ${ApiConstants.products}');
      return await _safeApiCall(() => http.post(
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
      ));
    } catch (e) {
      // print('Error adding product: $e');
      rethrow;
    }
  }

  // Get all products with improved error handling
  Future<List<dynamic>> getProducts() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse(ApiConstants.products),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      // print('Error getting products: $e');
      rethrow;
    }
  }

  // Update product price with improved error handling
  Future<Map<String, dynamic>> updateProductPrice({
    required String productId,
    required double sellingPrice,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.updateProductPrice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'selling_price': sellingPrice,
        }),
      ));
    } catch (e) {
      print('Error updating product price: $e');
      rethrow;
    }
  }

  // Get product price list with improved error handling
  Future<Map<String, dynamic>> getProductPriceList() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse(ApiConstants.productPriceList),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting product price list: $e');
      rethrow;
    }
  }


  // In api_service.dart

  Future<Map<String, dynamic>> login({
    required String shopId,
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login to: ${ApiConstants.login}');
      print('Login parameters - Shop ID: $shopId, Email: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shop_id': shopId,
          'email': email,
          'password': password,
        }),
      ).timeout(requestTimeout);

      print('Response status code: ${response.statusCode}');
      print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');

      final data = await _handleApiResponse(response);

      // Print the full user data for debugging
      print('User data from login response: ${data['user']}');

      // Check specifically for designation and seller_id
      if (data['user'] != null) {
        print('Designation: ${data['user']['designation']}');
        print('Seller ID: ${data['user']['seller_id']}');
      }

      // Save token and user data to secure storage
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'user', value: jsonEncode(data['user']));

      return data;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }






  // In api_service.dart

  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: 'user');
    if (userData == null) {
      print('No user data found in storage');
      return null;
    }

    try {
      final Map<String, dynamic> userJson = jsonDecode(userData);
      print('Retrieved raw user data from storage: $userJson');

      // Check if designation and seller_id are present
      print('Designation in storage: ${userJson['designation']}');
      print('Seller ID in storage: ${userJson['seller_id']}');

      final user = User.fromJson(userJson);
      print('Parsed user from storage: ${user.name}, Role: ${user.role}, Designation: ${user.designation}, Seller ID: ${user.sellerId}');
      return user;
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
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

  // Get all users in a shop with improved error handling
  Future<List<User>> getShopUsers(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Fetching shop users for shopId: $shopId');
      final data = await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.shopUsers}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));

      print('Found ${data.length} users');

      // Log user roles for debugging
      for (var userData in data) {
        print('User: ${userData['name']}, Role: ${userData['role']}');
      }

      return data.map((user) => User.fromJson(user)).toList();
    } catch (e) {
      print('Error getting shop users: $e');
      rethrow;
    }
  }




  // Add this method to your ApiService class
  Future<List<dynamic>> getShopUsersRaw(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Fetching shop users for shopId: $shopId');
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.shopUsers}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting shop users: $e');
      rethrow;
    }
  }




  // Delete a user with improved error handling
  Future<void> deleteUser(String userId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Deleting user with ID: $userId');
      await _safeApiCall(() => http.delete(
        Uri.parse('${ApiConstants.deleteUser}$userId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));

      // print('User deleted successfully');
    } catch (e) {
      // print('Error deleting user: $e');
      rethrow;
    }
  }

  // Add Premium-related methods to the ApiService class

  // Get premium status
  Future<Map<String, dynamic>> getPremiumStatus({required String shopId}) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.premiumStatus}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting premium status: $e');
      rethrow;
    }
  }

  // Subscribe to premium with simplified transaction handling
  Future<Map<String, dynamic>> subscribeToPremium({
    required String transactionId,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      // Simple request with only transaction ID
      // Server will verify transaction, activate premium if valid,
      // and delete the transaction ID from database immediately
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.premiumSubscribe),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transaction_id': transactionId,
        }),
      ));
    } catch (e) {
      print('Error subscribing to premium: $e');
      rethrow;
    }
  }

  // Get recharge history
  Future<List<dynamic>> getRechargeHistory({
    required String shopId,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.rechargeHistory}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting recharge history: $e');
      rethrow;
    }
  }

  // Get shop branches
  Future<List<dynamic>> getShopBranches({
    required String shopId,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.branches}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting shop branches: $e');
      rethrow;
    }
  }

  // Create branch
  Future<Map<String, dynamic>> createBranch({
    required String name,
    required String address,
    String? managerEmail,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final requestBody = {
        'name': name,
        'address': address,
      };
      
      if (managerEmail != null && managerEmail.isNotEmpty) {
        requestBody['manager_email'] = managerEmail;
      }
      
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.createBranch),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ));
    } catch (e) {
      print('Error creating branch: $e');
      rethrow;
    }
  }

  // Assign user to branch
  Future<Map<String, dynamic>> assignUserToBranch({
    required String userEmail,
    required String branchId,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.assignUserToBranch),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_email': userEmail,
          'branch_id': branchId,
        }),
      ));
    } catch (e) {
      print('Error assigning user to branch: $e');
      rethrow;
    }
  }

  // Return a product
  Future<Map<String, dynamic>> returnProduct({
    required String invoiceId,
    required String productId,
    required int quantity,
    required String reason,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.returnProduct),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'invoice_id': invoiceId,
          'product_id': productId,
          'quantity': quantity,
          'return_reason': reason,
        }),
      ));
    } catch (e) {
      print('Error returning product: $e');
      rethrow;
    }
  }

  // Get returned products
  Future<List<dynamic>> getReturnedProducts(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.returnedProducts}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting returned products: $e');
      rethrow;
    }
  }

  // Get premium sales analytics
  Future<Map<String, dynamic>> getPremiumSalesAnalytics(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.premiumSalesAnalytics}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting premium sales analytics: $e');
      rethrow;
    }
  }

  // Get product profit analytics
  Future<Map<String, dynamic>> getProductProfitAnalytics(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.productProfitAnalytics}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting product profit analytics: $e');
      rethrow;
    }
  }

  // Get shop settings
  Future<Map<String, dynamic>> getShopSettings(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.get(
        Uri.parse('${ApiConstants.shopSettings}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ));
    } catch (e) {
      print('Error getting shop settings: $e');
      rethrow;
    }
  }

  // Update shop settings
  Future<Map<String, dynamic>> updateShopSettings({
    required String shopId,
    required String name,
    required String address,
    required String licenseNumber,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.put(
        Uri.parse('${ApiConstants.shopSettings}$shopId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'address': address,
          'license_number': licenseNumber,
        }),
      ));
    } catch (e) {
      print('Error updating shop settings: $e');
      rethrow;
    }
  }

  // Upload shop logo
  Future<Map<String, dynamic>> uploadShopLogo({
    required String shopId,
    required String logoUrl,
  }) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      return await _safeApiCall(() => http.post(
        Uri.parse('${ApiConstants.uploadShopLogo}$shopId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'logo_url': logoUrl,
        }),
      ));
    } catch (e) {
      print('Error uploading shop logo: $e');
      rethrow;
    }
  }

  // Verify Email OTP
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.verifyEmail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ));
    } catch (e) {
      print('Error verifying email: $e');
      rethrow;
    }
  }
  
  // Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      return await _safeApiCall(() => http.post(
        Uri.parse(ApiConstants.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      ));
    } catch (e) {
      print('Error resending OTP: $e');
      rethrow;
    }
  }

  // Premium subscription transaction API methods
  Future<Map<String, dynamic>> checkTransaction(String transactionId) async {
    try {
      final token = await _safeApiCall(() => _storage.read(key: 'token'));
      if (token == null) {
        return {'success': false, 'message': 'No valid token found'};
      }

      return await _safeApiCall(() async {
        final response = await http.get(
          Uri.parse(ApiConstants.checkTransaction + transactionId),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        return _handleApiResponse(response);
      });
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addRecharge(String transactionId, double amount) async {
    try {
      final token = await _safeApiCall(() => _storage.read(key: 'token'));
      if (token == null) {
        return {'success': false, 'message': 'No valid token found'};
      }

      return await _safeApiCall(() async {
        final response = await http.post(
          Uri.parse(ApiConstants.addRecharge),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'transactionId': transactionId,
            'amount': amount,
          }),
        );

        return _handleApiResponse(response);
      });
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> recordTransaction(String transactionId, double amount) async {
    try {
      final token = await _safeApiCall(() => _storage.read(key: 'token'));
      if (token == null) {
        return {'success': false, 'message': 'No valid token found'};
      }

      return await _safeApiCall(() async {
        final response = await http.post(
          Uri.parse(ApiConstants.recordTransaction),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'transactionId': transactionId,
            'amount': amount,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );

        return _handleApiResponse(response);
      });
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}