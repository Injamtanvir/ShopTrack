import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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
      // Use the correct endpoint for shop info
      final url = ApiConstants.shopById(shopId);
      print('Fetching shop info from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Shop info response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        // If shop info doesn't exist yet, return empty map
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

  // Check if shop info already has additional fields set
  Future<bool> isShopInfoAlreadySet(String shopId) async {
    final shopInfo = await getShopAdditionalInfo(shopId);
    
    // Check if any of the additional fields are already set
    return shopInfo.containsKey('shopCategory') && 
           shopInfo['shopCategory'] != null && 
           shopInfo['shopCategory'].toString().isNotEmpty;
  }

  // Save shop additional information
  Future<bool> saveShopAdditionalInfo(String shopId, Map<String, dynamic> shopInfo) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }
    
    // Check if an image file needs to be uploaded
    if (shopInfo.containsKey('imageFile') && shopInfo['imageFile'] != null) {
      final imageFile = shopInfo['imageFile'] as XFile;
      try {
        final imageUrl = await uploadImage(imageFile, token);
        if (imageUrl != null) {
          shopInfo['image_url'] = imageUrl;
        }
      } catch (e) {
        print('Failed to upload image: $e');
        // Continue without image if upload fails
      }
      
      // Remove the file from the shopInfo object
      shopInfo.remove('imageFile');
    }

    try {
      // Use the correct endpoint for updating shop info
      final url = ApiConstants.shopById(shopId);
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
      } else if (response.statusCode == 400 && response.body.contains('can only be set once')) {
        throw Exception('Shop information can only be set once');
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving shop information: $e');
      rethrow;
    }
  }

  // Get user additional information
  Future<Map<String, dynamic>> getUserAdditionalInfo(String userId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      // Use the correct endpoint for user info
      final url = ApiConstants.userInfo(userId);
      print('Fetching user info from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('User info response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        // If user info doesn't exist yet, return empty map
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

  // Check if user info already has additional fields set
  Future<bool> isUserInfoAlreadySet(String userId) async {
    final userInfo = await getUserAdditionalInfo(userId);
    
    // Check if any of the additional fields are already set
    return userInfo.containsKey('id_number') && 
           userInfo['id_number'] != null && 
           userInfo['id_number'].toString().isNotEmpty;
  }

  // Save user additional information
  Future<bool> saveUserAdditionalInfo(String userId, Map<String, dynamic> userInfo) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    // Check if an image file needs to be uploaded
    if (userInfo.containsKey('imageFile') && userInfo['imageFile'] != null) {
      final imageFile = userInfo['imageFile'] as XFile;
      try {
        final imageUrl = await uploadImage(imageFile, token);
        if (imageUrl != null) {
          userInfo['image_url'] = imageUrl;
        }
      } catch (e) {
        print('Failed to upload image: $e');
        // Continue without image if upload fails
      }
      
      // Remove the file from the userInfo object
      userInfo.remove('imageFile');
    }

    try {
      // Use the correct endpoint for updating user info
      final url = ApiConstants.userInfo(userId);
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
      } else if (response.statusCode == 400 && response.body.contains('can only be set once')) {
        throw Exception('User information can only be set once');
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving user information: $e');
      rethrow;
    }
  }
  
  // Upload image and return the URL
  Future<String?> uploadImage(XFile imageFile, String token) async {
    try {
      final url = ApiConstants.uploadImage;
      
      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      
      // If web, we need to handle differently
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await imageFile.readAsBytes(),
            filename: 'image.jpg',
          ),
        );
      } else {
        // For mobile platforms
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: 'image.jpg',
          ),
        );
      }
      
      var response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Read response
        final respStr = await response.stream.bytesToString();
        final respJson = jsonDecode(respStr);
        return respJson['imageUrl'];
      } else {
        print('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Method to test image upload (for debugging)
  Future<bool> testImageUpload(XFile imageFile) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }
    
    try {
      final imageUrl = await uploadImage(imageFile, token);
      print('Uploaded image URL: $imageUrl');
      return imageUrl != null;
    } catch (e) {
      print('Error testing image upload: $e');
      rethrow;
    }
  }
} 