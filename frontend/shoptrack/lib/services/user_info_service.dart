import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class UserInfoService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get user information
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
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
        // If user info doesn't exist yet, return empty map
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

  // Save user information
  Future<bool> saveUserInfo(String userId, Map<String, dynamic> userInfo) async {
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