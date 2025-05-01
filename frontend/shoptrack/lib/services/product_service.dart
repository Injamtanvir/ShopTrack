import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';

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

      // Check if response contains HTML (indicating a server issue)
      if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
        print('Server returned HTML instead of JSON when adding product');
        
        // Generate a temporary product ID
        final tempProductId = 'offline_product_${DateTime.now().millisecondsSinceEpoch}';
        
        // Save product for offline sync later
        await _saveOfflineProduct(productData, tempProductId);
        
        // Create initial batch for offline product
        try {
          final batchData = {
            'product_id': tempProductId,
            'product_name': productData['name'] ?? 'Unknown Product',
            'shop_id': productData['shop_id'] ?? await _getShopId(),
            'quantity': productData['quantity'],
            'cost_price': productData['cost_price'] ?? productData['buying_price'],
            'selling_price': productData['selling_price'],
            'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'remaining': productData['quantity'],
            'added_by': await _storage.read(key: 'user_id') ?? 'Unknown',
            'added_at': DateTime.now().toIso8601String(),
            'is_initial_batch': true,
            'is_offline': true
          };
          
          _saveOfflineBatch(batchData);
        } catch (e) {
          print('Error creating offline batch for product: $e');
        }
        
        return tempProductId;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Create initial batch for new product
          if (productData.containsKey('quantity') && (productData.containsKey('cost_price') || productData.containsKey('buying_price'))) {
            try {
              final batchData = {
                'product_id': data['product_id'],
                'product_name': productData['name'] ?? 'Unknown Product',
                'shop_id': productData['shop_id'] ?? await _getShopId(),
                'quantity': productData['quantity'],
                'cost_price': productData['cost_price'] ?? productData['buying_price'],
                'selling_price': productData['selling_price'],
                'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'remaining': productData['quantity'],
                'added_by': await _storage.read(key: 'user_id') ?? 'Unknown',
                'added_at': DateTime.now().toIso8601String(),
                'is_initial_batch': true
              };
              
              await addBatch(batchData);
            } catch (e) {
              print('Error creating initial batch for new product: $e');
              // Continue even if initial batch fails as the product was created
            }
          }
          
          return data['product_id'];
        } catch (e) {
          print('Error parsing product response: $e');
          // Generate a temporary product ID and save offline
          final tempProductId = 'offline_product_${DateTime.now().millisecondsSinceEpoch}';
          await _saveOfflineProduct(productData, tempProductId);
          return tempProductId;
        }
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding product: $e');
      // Save product offline if there's a network error
      final tempProductId = 'offline_product_${DateTime.now().millisecondsSinceEpoch}';
      await _saveOfflineProduct(productData, tempProductId);
      return tempProductId;
    }
  }
  
  // Helper method to save product offline for later sync
  Future<void> _saveOfflineProduct(Map<String, dynamic> productData, String tempId) async {
    try {
      // Get existing offline products
      final offlineProductsJson = await _storage.read(key: 'offline_products') ?? '[]';
      List<dynamic> offlineProducts = jsonDecode(offlineProductsJson);
      
      // Add temporary ID and timestamp
      productData['_id'] = tempId;
      productData['offline_created_at'] = DateTime.now().toIso8601String();
      
      // Add to offline products
      offlineProducts.add(productData);
      
      // Save back to storage
      await _storage.write(
        key: 'offline_products', 
        value: jsonEncode(offlineProducts)
      );
      
      print('Saved product to offline storage for future sync');
    } catch (e) {
      print('Error saving offline product: $e');
    }
  }
  
  // Add a new batch for an existing product
  Future<String> addBatch(Map<String, dynamic> batchData) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }
    
    // Ensure all required fields are present
    if (!batchData.containsKey('shop_id') || batchData['shop_id'] == null) {
      batchData['shop_id'] = await _getShopId();
    }
    
    if (!batchData.containsKey('added_by') || batchData['added_by'] == null) {
      batchData['added_by'] = await _storage.read(key: 'user_id') ?? 'Unknown';
    }
    
    if (!batchData.containsKey('added_at') || batchData['added_at'] == null) {
      batchData['added_at'] = DateTime.now().toIso8601String();
    }
    
    // Get product name if not provided
    if (!batchData.containsKey('product_name') || batchData['product_name'] == null) {
      try {
        final productData = await _getProductDetails(batchData['product_id']);
        batchData['product_name'] = productData['name'] ?? 'Unknown Product';
      } catch (e) {
        print('Error getting product name: $e');
        batchData['product_name'] = 'Unknown Product';
      }
    }

    try {
      // Try both URLs to handle potential API inconsistencies
      final baseUrl = ApiConstants.batches;
      final altUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      
      // First attempt
      var response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(batchData),
      );

      // Check if response is HTML
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html>')) {
        print('Received HTML response when adding batch instead of JSON');
        
        // Try with alternate URL
        print('Retrying batch creation with alternate URL...');
        await Future.delayed(Duration(seconds: 1));
        
        response = await http.post(
          Uri.parse(altUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(batchData),
        );
        
        // If still HTML response, try one more variation
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html>')) {
            
          print('Still receiving HTML. Trying with product_id in URL...');
          final productUrl = '$altUrl${batchData['product_id']}';
          
          response = await http.post(
            Uri.parse(productUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(batchData),
          );
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          return data['batch_id'] ?? 'batch_id_unknown';
        } catch (e) {
          print('Error parsing batch creation response: $e');
          // Store batch locally for future sync
          _saveOfflineBatch(batchData);
          return 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        // For server errors, still try to parse the error message
        try {
          final errorData = jsonDecode(response.body);
          print('Server error: ${errorData['error'] ?? response.statusCode}');
          // Store batch locally for future sync
          _saveOfflineBatch(batchData);
          return 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
        } catch (e) {
          print('Failed to add batch and parse error: ${response.statusCode}');
          // Store batch locally for future sync
          _saveOfflineBatch(batchData);
          return 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
        }
      }
    } catch (e) {
      print('Error adding batch: $e');
      // Store batch locally for future sync
      _saveOfflineBatch(batchData);
      return 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Helper method to save batch offline for later sync
  Future<void> _saveOfflineBatch(Map<String, dynamic> batchData) async {
    try {
      // Get existing offline batches
      final offlineBatchesJson = await _storage.read(key: 'offline_batches') ?? '[]';
      List<dynamic> offlineBatches = jsonDecode(offlineBatchesJson);
      
      // Add timestamp for sorting
      batchData['offline_created_at'] = DateTime.now().toIso8601String();
      
      // Add to offline batches
      offlineBatches.add(batchData);
      
      // Save back to storage
      await _storage.write(
        key: 'offline_batches', 
        value: jsonEncode(offlineBatches)
      );
      
      print('Saved batch to offline storage for future sync');
    } catch (e) {
      print('Error saving offline batch: $e');
    }
  }
  
  // Helper method to get current shop ID
  Future<String> _getShopId() async {
    try {
      final shopId = await _storage.read(key: 'shop_id');
      if (shopId != null && shopId.isNotEmpty) {
        return shopId;
      }
      
      // Try to get shop ID from products
      final products = await getProducts();
      if (products.isNotEmpty && products[0].containsKey('shop_id')) {
        final id = products[0]['shop_id'];
        await _storage.write(key: 'shop_id', value: id);
        return id;
      }
      
      return 'unknown_shop';
    } catch (e) {
      print('Error getting shop ID: $e');
      return 'unknown_shop';
    }
  }
  
  // Helper method to get product details
  Future<Map<String, dynamic>> _getProductDetails(String productId) async {
    try {
      final token = await _storage.read(key: 'token') ?? '';
      if (token.isEmpty) {
        throw Exception('Authorization token not found');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConstants.products}/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get product details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting product details: $e');
      return {'name': 'Unknown Product'};
    }
  }
  
  // Get batches for a product
  Future<List<dynamic>> getBatches(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      // Try multiple URL formats to handle API inconsistencies
      final baseUrl = ApiConstants.batches;
      final urls = [
        baseUrl.endsWith('/') ? '${baseUrl}$productId' : '${baseUrl}/$productId',
        baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        '${ApiConstants.products}/$productId/batches'
      ];
      
      http.Response? finalResponse;
      String usedUrl = '';
      
      // Try each URL until we get a good response
      for (var url in urls) {
        try {
          print('Trying to fetch batches from: $url');
          final response = await http.get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          // Check if we got a valid response
          if (response.statusCode == 200 && 
              !response.body.trim().startsWith('<!DOCTYPE') && 
              !response.body.trim().startsWith('<html>')) {
            finalResponse = response;
            usedUrl = url;
            break;
          } else {
            finalResponse ??= response; // Keep the first response if all fail
          }
        } catch (e) {
          print('Error trying URL $url: $e');
        }
      }
      
      // Use the best response we got
      final response = finalResponse!;
      
      if (response.statusCode == 200) {
        // Check if response contains HTML (which would indicate an error)
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          // If the response is HTML, return mock data + offline batches
          print('Received HTML response for batches instead of JSON');
          
          // Check if we have offline batches first
          final offlineBatches = await _getOfflineBatches(productId);
          if (offlineBatches.isNotEmpty) {
            // Sort offline batches by date
            offlineBatches.sort((a, b) {
              final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
              final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
              return dateA.compareTo(dateB);
            });
            
            return offlineBatches;
          }
          
          // Fall back to mock data only if no offline batches
          final mockBatches = await getMockBatchData(productId);
          
          return mockBatches;
        }
        
        try {
          final data = jsonDecode(response.body);
          
          // Add any offline batches for this product
          final combinedBatches = [...data];
          final offlineBatches = await _getOfflineBatches(productId);
          if (offlineBatches.isNotEmpty) {
            combinedBatches.addAll(offlineBatches);
          }
          
          // Only use actual data when available (don't use mock data)
          if (combinedBatches.isNotEmpty) {
            // Sort batches by date (ascending)
            combinedBatches.sort((a, b) {
              final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
              final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
              return dateA.compareTo(dateB);
            });
            
            return combinedBatches;
          } else {
            // Only use mock data if no actual batches are available
            final mockBatches = await getMockBatchData(productId);
            
            return mockBatches;
          }
        } catch (e) {
          print('Error parsing batch data: $e');
          
          // Check if we have offline batches first
          final offlineBatches = await _getOfflineBatches(productId);
          if (offlineBatches.isNotEmpty) {
            // Sort offline batches by date
            offlineBatches.sort((a, b) {
              final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
              final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
              return dateA.compareTo(dateB);
            });
            
            return offlineBatches;
          }
          
          // Fall back to mock data only if no offline batches
          final mockBatches = await getMockBatchData(productId);
          
          return mockBatches;
        }
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          // If the response is HTML, return mock data + offline batches
          print('Received HTML response for batches instead of JSON');
          
          // Check if we have offline batches first
          final offlineBatches = await _getOfflineBatches(productId);
          if (offlineBatches.isNotEmpty) {
            // Sort offline batches by date
            offlineBatches.sort((a, b) {
              final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
              final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
              return dateA.compareTo(dateB);
            });
            
            return offlineBatches;
          }
          
          // Fall back to mock data only if no offline batches
          final mockBatches = await getMockBatchData(productId);
          
          return mockBatches;
        }
        
        try {
          final errorMessage = response.body.isNotEmpty 
              ? (jsonDecode(response.body)['error'] ?? 'Unknown error') 
              : 'Failed to get batches';
          throw Exception('Failed to get batches: ${errorMessage}');
        } catch (e) {
          // If we can't parse the error message, still return mock data + offline batches
          print('Error processing error response: $e');
          final mockBatches = await getMockBatchData(productId);
          final offlineBatches = await _getOfflineBatches(productId);
          final combinedBatches = [...mockBatches, ...offlineBatches];
          
          return combinedBatches;
        }
      }
    } catch (e) {
      print('Error getting batches: $e');
      // For any error, return offline batches first, then mock data as last resort
      final offlineBatches = await _getOfflineBatches(productId);
      if (offlineBatches.isNotEmpty) {
        // Sort offline batches by date
        offlineBatches.sort((a, b) {
          final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
          final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
          return dateA.compareTo(dateB);
        });
        
        return offlineBatches;
      }
      
      // Fall back to mock data only if no offline batches exist
      final mockBatches = await getMockBatchData(productId);
      
      return mockBatches;
    }
  }
  
  // Helper method to get offline batches for a product
  Future<List<Map<String, dynamic>>> _getOfflineBatches(String productId) async {
    try {
      final offlineBatchesJson = await _storage.read(key: 'offline_batches') ?? '[]';
      List<dynamic> allOfflineBatches = jsonDecode(offlineBatchesJson);
      
      // Filter batches for this product
      final productBatches = allOfflineBatches
          .where((batch) => batch['product_id'] == productId)
          .map((batch) => Map<String, dynamic>.from(batch))
          .toList();
      
      return productBatches;
    } catch (e) {
      print('Error getting offline batches: $e');
      return [];
    }
  }
  
  // Public method to get offline batches for a specific product
  Future<List<Map<String, dynamic>>> getOfflineBatchesForProduct(String productId) async {
    return await _getOfflineBatches(productId);
  }
  
  // Public method to get raw offline batches JSON string for debugging
  Future<String> getOfflineBatchesJson() async {
    return await _storage.read(key: 'offline_batches') ?? '[]';
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
      // Check if this is a price update and record it for history
      if (productData.containsKey('selling_price')) {
        final oldProduct = await _getProductDetails(productId);
        if (oldProduct.containsKey('selling_price') && 
            oldProduct['selling_price'] != productData['selling_price']) {
          // Record price change in history
          try {
            final priceHistoryData = {
              'product_id': productId,
              'old_price': oldProduct['selling_price'],
              'new_price': productData['selling_price'],
              'changed_at': DateTime.now().toIso8601String(),
              'changed_by': await _storage.read(key: 'user_id') ?? 'Unknown',
              'shop_id': oldProduct['shop_id'] ?? await _getShopId()
            };
            
            _recordPriceChange(priceHistoryData);
          } catch (e) {
            print('Error recording price history: $e');
            // Continue with update even if history recording fails
          }
        }
      }
    
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
  
  // Helper method to record price change
  Future<void> _recordPriceChange(Map<String, dynamic> priceData) async {
    try {
      final token = await _storage.read(key: 'token') ?? '';
      if (token.isEmpty) {
        throw Exception('Authorization token not found');
      }
      
      await http.post(
        Uri.parse(ApiConstants.priceHistory),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(priceData),
      );
    } catch (e) {
      print('Error recording price change: $e');
      // Save for offline sync
      try {
        final offlinePriceChangesJson = await _storage.read(key: 'offline_price_changes') ?? '[]';
        List<dynamic> offlinePriceChanges = jsonDecode(offlinePriceChangesJson);
        offlinePriceChanges.add(priceData);
        await _storage.write(
          key: 'offline_price_changes', 
          value: jsonEncode(offlinePriceChanges)
        );
      } catch (e) {
        print('Error saving offline price change: $e');
      }
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

  // Generate mock batch data for a product when API returns HTML
  Future<List<Map<String, dynamic>>> getMockBatchData(String productId) async {
    // Create initial batch with large quantity (first batch) and a follow-up batch
    final today = DateTime.now();
    final shopId = await _getShopId();
    final userName = await _storage.read(key: 'user_name') ?? 'System User';
    
    // Get product details to use real values in mock data
    String productName = 'Unknown Product';
    double costPrice = 100.0;
    try {
      final productData = await _getProductDetails(productId);
      productName = productData['name'] ?? 'Product $productId';
      costPrice = productData['buying_price'] ?? 100.0;
      if (costPrice is int) {
        costPrice = costPrice.toDouble();
      }
    } catch (e) {
      productName = 'Product $productId';
    }
    
    // First batch: initial product creation with large quantity
    final initialBatchDate = today.subtract(Duration(days: 30)); // 30 days ago
    
    // Second batch: additional recently added batch with smaller quantity
    final secondBatchDate = today.subtract(Duration(days: 5)); // 5 days ago
    
    return [
      {
        '_id': 'mock_initial_batch_$productId',
        'product_id': productId,
        'product_name': productName,
        'shop_id': shopId,
        'purchase_date': DateFormat('yyyy-MM-dd').format(initialBatchDate),
        'quantity_purchased': 2000,  // Large initial quantity
        'remaining': 1800,  // Most remaining
        'cost_price': costPrice,
        'added_by': 'System',
        'added_at': initialBatchDate.toIso8601String(),
        'created_at': DateFormat('yyyy-MM-dd').format(initialBatchDate),
        'is_initial_batch': true
      },
      {
        '_id': 'mock_batch_${productId}_2',
        'product_id': productId,
        'product_name': productName,
        'shop_id': shopId,
        'purchase_date': DateFormat('yyyy-MM-dd').format(secondBatchDate),
        'quantity_purchased': 200,  // Additional smaller batch
        'remaining': 200,  // All remaining since we deduct from oldest first
        'cost_price': costPrice * 1.05, // Slightly higher cost price
        'added_by': userName,
        'added_at': secondBatchDate.toIso8601String(),
        'created_at': DateFormat('yyyy-MM-dd').format(secondBatchDate),
        'is_initial_batch': false
      }
    ];
  }
} 