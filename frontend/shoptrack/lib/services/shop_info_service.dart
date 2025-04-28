import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ShopInfoService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get shop additional information
  Future<Map<String, dynamic>> getShopAdditionalInfo(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/shops/$shopId/info'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // If shop additional info doesn't exist yet, return empty map
        return {};
      } else {
        throw Exception('Failed to get shop information');
      }
    } catch (e) {
      print('Error getting shop information: $e');
      // Return empty map in case of error
      return {};
    }
  }

  // Save shop additional information
  Future<bool> saveShopAdditionalInfo(String shopId, Map<String, dynamic> shopInfo) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/shops/$shopId/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(shopInfo),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving shop information: $e');
      return false;
    }
  }

  // Get user additional information
  Future<Map<String, dynamic>> getUserAdditionalInfo(String userId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/info'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // If user additional info doesn't exist yet, return empty map
        return {};
      } else {
        throw Exception('Failed to get user information');
      }
    } catch (e) {
      print('Error getting user information: $e');
      // Return empty map in case of error
      return {};
    }
  }

  // Save user additional information
  Future<bool> saveUserAdditionalInfo(String userId, Map<String, dynamic> userInfo) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userInfo),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving user information: $e');
      return false;
    }
  }
} 