// // import 'dart:convert';
// // import 'dart:math';
// // import 'package:http/http.dart' as http;
// // import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// // import '../constants/api_constants.dart';
// // import '../models/user.dart';
// //
// // class ApiService {
// //   final FlutterSecureStorage _storage = const FlutterSecureStorage();
// //
// //   // Updated method with async keyword
// //   Future<dynamic> _handleApiResponse(http.Response response) async {
// //     try {
// //       // Check if response is HTML instead of JSON
// //       if (response.body.trim().startsWith('<!DOCTYPE') ||
// //           response.body.trim().startsWith('<html')) {
// //         throw Exception('Server returned HTML instead of JSON. This usually indicates a server configuration or URL issue.');
// //       }
// //
// //       if (response.statusCode >= 200 && response.statusCode < 300) {
// //         return jsonDecode(response.body);
// //       } else {
// //         try {
// //           final errorData = jsonDecode(response.body);
// //           throw Exception(errorData['error'] ?? 'API error: ${response.statusCode}');
// //         } catch (e) {
// //           throw Exception('Error ${response.statusCode}: ${response.body.substring(0, min(100, response.body.length))}');
// //         }
// //       }
// //     } catch (e) {
// //       print('API error: ${e.toString()}');
// //       rethrow;
// //     }
// //   }
// //
// //   // Register a new shop
// //   Future<Map<String, dynamic>> registerShop({
// //     required String name,
// //     required String address,
// //     required String ownerName,
// //     required String licenseNumber,
// //     required String email,
// //     required String password,
// //     required String confirmPassword,
// //   }) async {
// //     final response = await http.post(
// //       Uri.parse(ApiConstants.registerShop),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({
// //         'name': name,
// //         'address': address,
// //         'owner_name': ownerName,
// //         'license_number': licenseNumber,
// //         'email': email,
// //         'password': password,
// //         'confirm_password': confirmPassword,
// //       }),
// //     );
// //
// //     return await _handleApiResponse(response);
// //   }
// //
// //   // Login user
// //   Future<Map<String, dynamic>> login({
// //     required String shopId,
// //     required String email,
// //     required String password,
// //   }) async {
// //     try {
// //       print('Attempting login to: ${ApiConstants.login}');
// //       final response = await http.post(
// //         Uri.parse(ApiConstants.login),
// //         headers: {'Content-Type': 'application/json'},
// //         body: jsonEncode({
// //           'shop_id': shopId,
// //           'email': email,
// //           'password': password,
// //         }),
// //       );
// //
// //       print('Response status code: ${response.statusCode}');
// //       print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');
// //
// //       final data = await _handleApiResponse(response);
// //
// //       // Save token and user data to secure storage
// //       await _storage.write(key: 'token', value: data['token']);
// //       await _storage.write(key: 'user', value: jsonEncode(data['user']));
// //
// //       return data;
// //     } catch (e) {
// //       print('Login error: $e');
// //       rethrow;
// //     }
// //   }
// //
// //   // Register a sales person (admin only)
// //   // Future<Map<String, dynamic>> registerSalesPerson({
// //   //   required String name,
// //   //   required String designation,
// //   //   required String sellerId,
// //   //   required String email,
// //   //   required String password,
// //   // }) async {
// //   //   final token = await _storage.read(key: 'token') ?? '';
// //   //
// //   //   if (token.isEmpty) {
// //   //     throw Exception('Authorization token not found');
// //   //   }
// //   //
// //   //   final response = await http.post(
// //   //     Uri.parse(ApiConstants.registerSalesPerson),
// //   //     headers: {
// //   //       'Content-Type': 'application/json',
// //   //       'Authorization': 'Bearer $token',
// //   //     },
// //   //     body: jsonEncode({
// //   //       'name': name,
// //   //       'designation': designation,
// //   //       'seller_id': sellerId,
// //   //       'email': email,
// //   //       'password': password,
// //   //     }),
// //   //   );
// //   //
// //   //   return await _handleApiResponse(response);
// //   // }
// //
// //   // Register another admin (admin only)
// //   Future<Map<String, dynamic>> registerAdmin({
// //     required String name,
// //     required String email,
// //     required String password,
// //   }) async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     final response = await http.post(
// //       Uri.parse(ApiConstants.registerAdmin),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $token',
// //       },
// //       body: jsonEncode({
// //         'name': name,
// //         'email': email,
// //         'password': password,
// //       }),
// //     );
// //
// //     return await _handleApiResponse(response);
// //   }
// //
// //
// //
// //   // Add this method to your ApiService class
// //   Future<void> deleteProduct(String productId) async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     try {
// //       final response = await http.delete(
// //         Uri.parse('${ApiConstants.deleteProduct}$productId/'),
// //         headers: {
// //           'Authorization': 'Bearer $token',
// //         },
// //       );
// //
// //       if (response.statusCode != 200) {
// //         if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
// //           throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
// //         }
// //
// //         try {
// //           final errorData = jsonDecode(response.body);
// //           throw Exception(errorData['error'] ?? 'Failed to delete product');
// //         } catch (e) {
// //           throw Exception('Error ${response.statusCode}: ${response.body}');
// //         }
// //       }
// //     } catch (e) {
// //       print('Error deleting product: $e');
// //       rethrow;
// //     }
// //   }
// //
// //
// //
// //
// //
// //   // Verify JWT token
// //   Future<bool> verifyToken() async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //
// //     if (token.isEmpty) {
// //       return false;
// //     }
// //
// //     try {
// //       final response = await http.get(
// //         Uri.parse(ApiConstants.verifyToken),
// //         headers: {'Authorization': 'Bearer $token'},
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final data = await _handleApiResponse(response);
// //         return data['valid'] == true;
// //       } else {
// //         return false;
// //       }
// //     } catch (e) {
// //       print('Token verification error: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Get current user from storage
// //   Future<User?> getCurrentUser() async {
// //     final userData = await _storage.read(key: 'user');
// //
// //     if (userData == null) {
// //       return null;
// //     }
// //
// //     return User.fromJson(jsonDecode(userData));
// //   }
// //
// //   // Logout user
// //   Future<void> logout() async {
// //     await _storage.delete(key: 'token');
// //     await _storage.delete(key: 'user');
// //   }
// //
// //   // Add/update product
// //   Future<Map<String, dynamic>> addProduct({
// //     required String name,
// //     required int quantity,
// //     required double buyingPrice,
// //     required double sellingPrice,
// //   }) async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     try {
// //       print('Adding product to: ${ApiConstants.products}');
// //       final response = await http.post(
// //         Uri.parse(ApiConstants.products),
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'Authorization': 'Bearer $token',
// //         },
// //         body: jsonEncode({
// //           'name': name,
// //           'quantity': quantity,
// //           'buying_price': buyingPrice,
// //           'selling_price': sellingPrice,
// //         }),
// //       );
// //
// //       print('Response status: ${response.statusCode}');
// //       return await _handleApiResponse(response);
// //     } catch (e) {
// //       print('Error adding product: $e');
// //       rethrow;
// //     }
// //   }
// //
// //   // Get all products
// //   Future<List<dynamic>> getProducts() async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     final response = await http.get(
// //       Uri.parse(ApiConstants.products),
// //       headers: {'Authorization': 'Bearer $token'},
// //     );
// //
// //     return await _handleApiResponse(response);
// //   }
// //
// //   // Update product price (admin only)
// //   Future<Map<String, dynamic>> updateProductPrice({
// //     required String productId,
// //     required double sellingPrice,
// //   }) async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     final response = await http.post(
// //       Uri.parse(ApiConstants.updateProductPrice),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'Authorization': 'Bearer $token',
// //       },
// //       body: jsonEncode({
// //         'product_id': productId,
// //         'selling_price': sellingPrice,
// //       }),
// //     );
// //
// //     return await _handleApiResponse(response);
// //   }
// //
// //   // Get product price list
// //   Future<Map<String, dynamic>> getProductPriceList() async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     final response = await http.get(
// //       Uri.parse(ApiConstants.productPriceList),
// //       headers: {'Authorization': 'Bearer $token'},
// //     );
// //
// //     return await _handleApiResponse(response);
// //   }
// //
// //   // Retry mechanism for failed API calls
// //   Future<T> retryRequest<T>(Future<T> Function() requestFunc, {int maxRetries = 3}) async {
// //     int attempts = 0;
// //     while (attempts < maxRetries) {
// //       try {
// //         return await requestFunc();
// //       } catch (e) {
// //         attempts++;
// //         if (attempts >= maxRetries) {
// //           rethrow;
// //         }
// //         // Wait before retrying (exponential backoff)
// //         await Future.delayed(Duration(milliseconds: 300 * attempts));
// //       }
// //     }
// //     throw Exception('Max retry attempts reached');
// //   }
// //
// //   // Get all users in a shop
// //   Future<List<User>> getShopUsers(String shopId) async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     try {
// //       final response = await http.get(
// //         Uri.parse('${ApiConstants.getShopUsers}$shopId/'),
// //         headers: {'Authorization': 'Bearer $token'},
// //       );
// //
// //       if (response.statusCode == 200) {
// //         final List<dynamic> data = jsonDecode(response.body);
// //         return data.map((user) => User.fromJson(user)).toList();
// //       } else {
// //         throw Exception('Failed to load shop users: ${response.body}');
// //       }
// //     } catch (e) {
// //       print('Error getting shop users: $e');
// //       rethrow;
// //     }
// //   }
// //
// // // Delete a user
// //   Future<void> deleteUser(String userId) async {
// //     final token = await _storage.read(key: 'token') ?? '';
// //     if (token.isEmpty) {
// //       throw Exception('Authorization token not found');
// //     }
// //
// //     try {
// //       final response = await http.delete(
// //         Uri.parse('${ApiConstants.deleteUser}$userId/'),
// //         headers: {'Authorization': 'Bearer $token'},
// //       );
// //
// //       if (response.statusCode != 200) {
// //         throw Exception('Failed to delete user: ${response.body}');
// //       }
// //     } catch (e) {
// //       print('Error deleting user: $e');
// //       rethrow;
// //     }
// //   }
// //
// //
// // }
//
//
//
//
//
//
//
//
//
//
//
//
// import 'dart:convert';
// import 'dart:math';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../constants/api_constants.dart';
// import '../models/user.dart';
//
// class ApiService {
//   final FlutterSecureStorage _storage = const FlutterSecureStorage();
//
//   // Updated method with async keyword
//   Future<dynamic> _handleApiResponse(http.Response response) async {
//     try {
//       // Check if response is HTML instead of JSON
//       if (response.body.trim().startsWith('<!DOCTYPE') ||
//           response.body.trim().startsWith('<html>')) {
//         throw Exception('Server returned HTML instead of JSON. This usually indicates a server configuration or URL issue.');
//       }
//
//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return jsonDecode(response.body);
//       } else {
//         try {
//           final errorData = jsonDecode(response.body);
//           throw Exception(errorData['error'] ?? 'API error: ${response.statusCode}');
//         } catch (e) {
//           throw Exception('Error ${response.statusCode}: ${response.body.substring(0, min(100, response.body.length))}');
//         }
//       }
//     } catch (e) {
//       print('API error: ${e.toString()}');
//       rethrow;
//     }
//   }
//
//   // Helper method to decode JWT token payload for debugging
//   String _decodeToken(String token) {
//     try {
//       final parts = token.split('.');
//       if (parts.length != 3) {
//         return 'Invalid token format';
//       }
//
//       final payload = parts[1];
//       String normalized = payload;
//       if (payload.length % 4 > 0) {
//         normalized = payload + '=' * (4 - payload.length % 4);
//       }
//
//       final decoded = utf8.decode(base64Url.decode(normalized));
//       return decoded;
//     } catch (e) {
//       return 'Error decoding token: $e';
//     }
//   }
//
//   // Register a new shop
//   Future<Map<String, dynamic>> registerShop({
//     required String name,
//     required String address,
//     required String ownerName,
//     required String licenseNumber,
//     required String email,
//     required String password,
//     required String confirmPassword,
//   }) async {
//     print('Registering shop with name: $name, email: $email');
//     final response = await http.post(
//       Uri.parse(ApiConstants.registerShop),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'name': name,
//         'address': address,
//         'owner_name': ownerName,
//         'license_number': licenseNumber,
//         'email': email,
//         'password': password,
//         'confirm_password': confirmPassword,
//       }),
//     );
//
//     print('Shop registration response status: ${response.statusCode}');
//     final responseData = await _handleApiResponse(response);
//     print('Shop registered with ID: ${responseData['shop_id']}');
//     return responseData;
//   }
//
//   // Login user
//   Future<Map<String, dynamic>> login({
//     required String shopId,
//     required String email,
//     required String password,
//   }) async {
//     try {
//       print('Attempting login to: ${ApiConstants.login}');
//       print('Login parameters - Shop ID: $shopId, Email: $email');
//
//       final response = await http.post(
//         Uri.parse(ApiConstants.login),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'shop_id': shopId,
//           'email': email,
//           'password': password,
//         }),
//       );
//
//       print('Response status code: ${response.statusCode}');
//       print('Response body preview: ${response.body.substring(0, min(100, response.body.length))}...');
//
//       final data = await _handleApiResponse(response);
//
//       // Save token and user data to secure storage
//       await _storage.write(key: 'token', value: data['token']);
//
//       // Log user role from the token
//       print('User role from login response: ${data['user']['role']}');
//
//       await _storage.write(key: 'user', value: jsonEncode(data['user']));
//
//       return data;
//     } catch (e) {
//       print('Login error: $e');
//       rethrow;
//     }
//   }
//
//   // Register a sales person (admin only)
//   Future<Map<String, dynamic>> registerSalesPerson({
//     required String name,
//     required String designation,
//     required String sellerId,
//     required String email,
//     required String password,
//   }) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     print('Sending register sales person request with token: ${token.substring(0, 20)}...');
//     print('Token payload: ${_decodeToken(token)}');
//
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.registerSalesPerson),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'name': name,
//           'designation': designation,
//           'seller_id': sellerId,
//           'email': email,
//           'password': password,
//         }),
//       );
//
//       print('Register sales person response status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//
//       return await _handleApiResponse(response);
//     } catch (e) {
//       print('Error registering sales person: $e');
//       rethrow;
//     }
//   }
//
//   // Register another admin (admin only)
//   Future<Map<String, dynamic>> registerAdmin({
//     required String name,
//     required String email,
//     required String password,
//   }) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     print('Sending register admin request with token: ${token.substring(0, 20)}...');
//     print('Token payload: ${_decodeToken(token)}');
//
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.registerAdmin),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'name': name,
//           'email': email,
//           'password': password,
//         }),
//       );
//
//       print('Register admin response status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//
//       return await _handleApiResponse(response);
//     } catch (e) {
//       print('Error registering admin: $e');
//       rethrow;
//     }
//   }
//
//   // Delete a product
//   Future<void> deleteProduct(String productId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     try {
//       final response = await http.delete(
//         Uri.parse('${ApiConstants.deleteProduct}$productId/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode != 200) {
//         if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
//           throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
//         }
//
//         try {
//           final errorData = jsonDecode(response.body);
//           throw Exception(errorData['error'] ?? 'Failed to delete product');
//         } catch (e) {
//           throw Exception('Error ${response.statusCode}: ${response.body}');
//         }
//       }
//     } catch (e) {
//       print('Error deleting product: $e');
//       rethrow;
//     }
//   }
//
//   // Verify JWT token
//   Future<bool> verifyToken() async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       print('No token found in storage');
//       return false;
//     }
//
//     try {
//       print('Verifying token: ${token.length > 20 ? token.substring(0, 20) + '...' : token}');
//       print('Token payload: ${_decodeToken(token)}');
//
//       final response = await http.get(
//         Uri.parse(ApiConstants.verifyToken),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       print('Token verification response status: ${response.statusCode}');
//       if (response.statusCode == 200) {
//         print('Token verification response body: ${response.body}');
//         final data = await _handleApiResponse(response);
//
//         print('Token valid: ${data['valid']}');
//         if (data['valid'] == true && data.containsKey('user')) {
//           print('User role from token: ${data['user']['role']}');
//         }
//
//         return data['valid'] == true;
//       } else {
//         print('Token verification failed with status: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       print('Token verification error: $e');
//       return false;
//     }
//   }
//
//   // Get current user from storage
//   Future<User?> getCurrentUser() async {
//     final userData = await _storage.read(key: 'user');
//     if (userData == null) {
//       print('No user data found in storage');
//       return null;
//     }
//
//     final user = User.fromJson(jsonDecode(userData));
//     print('Retrieved user from storage: ${user.name}, Role: ${user.role}');
//     return user;
//   }
//
//   // Logout user
//   Future<void> logout() async {
//     print('Logging out user');
//     await _storage.delete(key: 'token');
//     await _storage.delete(key: 'user');
//     print('User logged out, storage cleared');
//   }
//
//   // Add/update product
//   Future<Map<String, dynamic>> addProduct({
//     required String name,
//     required int quantity,
//     required double buyingPrice,
//     required double sellingPrice,
//   }) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     try {
//       print('Adding product to: ${ApiConstants.products}');
//       final response = await http.post(
//         Uri.parse(ApiConstants.products),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'name': name,
//           'quantity': quantity,
//           'buying_price': buyingPrice,
//           'selling_price': sellingPrice,
//         }),
//       );
//
//       print('Response status: ${response.statusCode}');
//       return await _handleApiResponse(response);
//     } catch (e) {
//       print('Error adding product: $e');
//       rethrow;
//     }
//   }
//
//   // Get all products
//   Future<List<dynamic>> getProducts() async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse(ApiConstants.products),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     return await _handleApiResponse(response);
//   }
//
//   // Update product price (admin only)
//   Future<Map<String, dynamic>> updateProductPrice({
//     required String productId,
//     required double sellingPrice,
//   }) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.post(
//       Uri.parse(ApiConstants.updateProductPrice),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode({
//         'product_id': productId,
//         'selling_price': sellingPrice,
//       }),
//     );
//
//     return await _handleApiResponse(response);
//   }
//
//   // Get product price list
//   Future<Map<String, dynamic>> getProductPriceList() async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse(ApiConstants.productPriceList),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     return await _handleApiResponse(response);
//   }
//
//   // Retry mechanism for failed API calls
//   Future<T> retryRequest<T>(Future<T> Function() requestFunc, {int maxRetries = 3}) async {
//     int attempts = 0;
//     while (attempts < maxRetries) {
//       try {
//         return await requestFunc();
//       } catch (e) {
//         attempts++;
//         if (attempts >= maxRetries) {
//           rethrow;
//         }
//         // Wait before retrying (exponential backoff)
//         await Future.delayed(Duration(milliseconds: 300 * attempts));
//       }
//     }
//     throw Exception('Max retry attempts reached');
//   }
//
//   // Get all users in a shop
//   Future<List<User>> getShopUsers(String shopId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     try {
//       print('Fetching shop users for shopId: $shopId');
//       final response = await http.get(
//         Uri.parse('${ApiConstants.getShopUsers}$shopId/'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       print('Shop users response status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         print('Found ${data.length} users');
//
//         // Log user roles for debugging
//         for (var userData in data) {
//           print('User: ${userData['name']}, Role: ${userData['role']}');
//         }
//
//         return data.map((user) => User.fromJson(user)).toList();
//       } else {
//         print('Failed to load shop users. Response: ${response.body}');
//         throw Exception('Failed to load shop users: ${response.body}');
//       }
//     } catch (e) {
//       print('Error getting shop users: $e');
//       rethrow;
//     }
//   }
//
//   // Delete a user
//   Future<void> deleteUser(String userId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     try {
//       print('Deleting user with ID: $userId');
//       final response = await http.delete(
//         Uri.parse('${ApiConstants.deleteUser}$userId/'),
//         headers: {'Authorization': 'Bearer $token'},
//       );
//
//       print('Delete user response status: ${response.statusCode}');
//
//       if (response.statusCode != 200) {
//         print('Failed to delete user. Response: ${response.body}');
//         throw Exception('Failed to delete user: ${response.body}');
//       }
//
//       print('User deleted successfully');
//     } catch (e) {
//       print('Error deleting user: $e');
//       rethrow;
//     }
//   }
// }





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

  // Network timeout duration
  static const Duration requestTimeout = Duration(seconds: 20);

  // Handle API response with improved error checking
  Future<dynamic> _handleApiResponse(http.Response response) async {
    try {
      // Check if response is HTML instead of JSON
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
      print('API error: ${e.toString()}');
      rethrow;
    }
  }

  // Helper method to decode JWT token payload for debugging
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
    print('Registering shop with name: $name, email: $email');

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
      print('Shop registration error: $e');
      rethrow;
    }
  }

  // Login user with improved error handling
  // Future<Map<String, dynamic>> login({
  //   required String shopId,
  //   required String email,
  //   required String password,
  // }) async {
  //   try {
  //     print('Attempting login to: ${ApiConstants.login}');
  //     print('Login parameters - Shop ID: $shopId, Email: $email');
  //
  //     final data = await _safeApiCall(() => http.post(
  //       Uri.parse(ApiConstants.login),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'shop_id': shopId,
  //         'email': email,
  //         'password': password,
  //       }),
  //     ));
  //
  //     // Save token and user data to secure storage
  //     await _storage.write(key: 'token', value: data['token']);
  //
  //     // Log user role from the token
  //     print('User role from login response: ${data['user']['role']}');
  //
  //     await _storage.write(key: 'user', value: jsonEncode(data['user']));
  //
  //     return data;
  //   } catch (e) {
  //     print('Login error: $e');
  //     rethrow;
  //   }
  // }

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

    print('Sending register sales person request with token: ${token.substring(0, min(20, token.length))}...');
    print('Token payload: ${_decodeToken(token)}');

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
      print('Error registering sales person: $e');
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

    print('Sending register admin request with token: ${token.substring(0, min(20, token.length))}...');
    print('Token payload: ${_decodeToken(token)}');

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
      print('Error registering admin: $e');
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
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Verify JWT token with improved error handling
  Future<bool> verifyToken() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      print('No token found in storage');
      return false;
    }

    try {
      print('Verifying token: ${token.length > 20 ? token.substring(0, 20) + '...' : token}');

      final response = await http.get(
        Uri.parse(ApiConstants.verifyToken),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      print('Token verification response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = await _handleApiResponse(response);

        print('Token valid: ${data['valid']}');
        if (data['valid'] == true && data.containsKey('user')) {
          print('User role from token: ${data['user']['role']}');
        }

        return data['valid'] == true;
      } else {
        print('Token verification failed with status: ${response.statusCode}');
        return false;
      }
    } on SocketException {
      print('Network error during token verification');
      return false;
    } on TimeoutException {
      print('Timeout during token verification');
      return false;
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }

  // // Get current user from storage
  // Future<User?> getCurrentUser() async {
  //   final userData = await _storage.read(key: 'user');
  //   if (userData == null) {
  //     print('No user data found in storage');
  //     return null;
  //   }
  //
  //   try {
  //     final user = User.fromJson(jsonDecode(userData));
  //     print('Retrieved user from storage: ${user.name}, Role: ${user.role}');
  //     return user;
  //   } catch (e) {
  //     print('Error parsing user data: $e');
  //     return null;
  //   }
  // }

  // Logout user
  Future<void> logout() async {
    print('Logging out user');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    print('User logged out, storage cleared');
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
      print('Adding product to: ${ApiConstants.products}');
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
      print('Error adding product: $e');
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
      print('Error getting products: $e');
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

  // =====================================



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






  //=============================================




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
        Uri.parse('${ApiConstants.getShopUsers}$shopId/'),
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
      final response = await http.get(
        Uri.parse('${ApiConstants.getShopUsers}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      print('Shop users response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} users in raw data');
        return data;
      } else {
        print('Failed to load shop users. Response: ${response.body}');
        throw Exception('Failed to load shop users: ${response.body}');
      }
    } on SocketException {
      throw Exception('Network error: Unable to connect to the server');
    } on TimeoutException {
      throw Exception('Network timeout: Server took too long to respond');
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

      print('User deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}