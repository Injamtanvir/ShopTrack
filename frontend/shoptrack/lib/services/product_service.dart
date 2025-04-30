import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/product.dart';

class ProductService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get all products
  Future<List<dynamic>> getProducts() async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.products),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting products: $e');
      rethrow;
    }
  }
  
  // Add a new product
  Future<String> addProduct(Map<String, dynamic> productData) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.products),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['product_id'];
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }
  
  // Add a new batch for an existing product
  Future<String> addBatch(Map<String, dynamic> batchData) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.batches),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(batchData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['batch_id'];
      } else {
        throw Exception('Failed to add batch: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding batch: $e');
      rethrow;
    }
  }
  
  // Get batches for a product
  Future<List<dynamic>> getBatches(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.batches}/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorMessage = response.body.isNotEmpty ? jsonDecode(response.body)['error'] : 'Failed to get batches';
        throw Exception('Failed to get batches: ${errorMessage}');
      }
    } catch (e) {
      print('Error getting batches: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format when getting batches');
      }
      rethrow;
    }
  }
  
  // Get price history for a product
  Future<List<dynamic>> getPriceHistory(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.priceHistory}/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get price history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting price history: $e');
      rethrow;
    }
  }
  
  // Get profit report
  Future<Map<String, dynamic>> getProfitReport(String shopId, {String? startDate, String? endDate}) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      String url = '${ApiConstants.profitReport}/$shopId';
      if (startDate != null || endDate != null) {
        url += '?';
        if (startDate != null) {
          url += 'start_date=$startDate';
        }
        if (endDate != null) {
          url += startDate != null ? '&' : '';
          url += 'end_date=$endDate';
        }
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get profit report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting profit report: $e');
      rethrow;
    }
  }
  
  // Update product details
  Future<bool> updateProduct(String productId, Map<String, dynamic> productData) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.products}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
  
  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.deleteProduct}/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
} 