import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to register shop');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String shopId,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'shop_id': shopId,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token and user data to secure storage
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'user', value: jsonEncode(data['user']));

      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to login');
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
    final token = await _storage.read(key: 'token');

    if (token == null) {
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

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to register sales person');
    }
  }

  // Register another admin (admin only)
  Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
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

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to register admin');
    }
  }

  // Verify JWT token
  Future<bool> verifyToken() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.verifyToken),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] == true;
      } else {
        return false;
      }
    } catch (e) {
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
}