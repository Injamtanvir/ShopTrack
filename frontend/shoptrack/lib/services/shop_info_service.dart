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
      // Use the properly defined endpoint from API constants
      final url = '${ApiConstants.getShopInfo}$shopId/info';
      print('Fetching shop info from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Shop info response status: ${response.statusCode}');
      print('Shop info response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // If shop additional info doesn't exist yet, return empty map
        return {};
      } else {
        throw Exception('Failed to get shop information: [${response.statusCode}] ${response.body}');
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
      // Use the properly defined endpoint from API constants
      final url = '${ApiConstants.getShopInfo}$shopId/info';
      print('Saving shop info to: $url');
      print('Shop info data: $shopInfo');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(shopInfo),
      );

      print('Save shop info response: ${response.statusCode}');
      print('Save shop info response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error body: ${response.body}');
        return false;
      }
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
      // Use the properly defined endpoint from API constants
      final url = '${ApiConstants.getUserInfo}$userId/info';
      print('Fetching user info from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('User info response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // If user additional info doesn't exist yet, return empty map
        return {};
      } else {
        throw Exception('Failed to get user information: [${response.statusCode}] ${response.body}');
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
      // Use the properly defined endpoint from API constants
      final url = '${ApiConstants.getUserInfo}$userId/info';
      print('Saving user info to: $url');
      print('User info data: $userInfo');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userInfo),
      );

      print('Save user info response: ${response.statusCode}');
      print('Save user info response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving user information: $e');
      return false;
    }
  }
} 