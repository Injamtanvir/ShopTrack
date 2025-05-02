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
      // First check if product already exists
      String? existingProductId;
      try {
        final products = await getProducts();
        final existingProduct = products.firstWhere(
          (product) => product['name'] == productData['name'],
          orElse: () => null,
        );
        if (existingProduct != null) {
          existingProductId = existingProduct['_id'];
        }
      } catch (e) {
        print('Error checking for existing product: $e');
        // Continue with product creation
      }
      
      if (existingProductId != null) {
        // If product exists, create a new batch instead of updating directly
        print('Product already exists. Adding new batch for product: $existingProductId');
        final batchData = {
          'product_id': existingProductId,
          'product_name': productData['name'] ?? 'Unknown Product',
          'shop_id': productData['shop_id'] ?? await _getShopId(),
          'quantity': productData['quantity'],
          'quantity_purchased': productData['quantity'],
          'cost_price': productData['cost_price'] ?? productData['buying_price'],
          'selling_price': productData['selling_price'],
          'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'remaining': productData['quantity'],
          'added_by': await _storage.read(key: 'user_id') ?? 'Unknown',
          'added_at': DateTime.now().toIso8601String(),
          'is_initial_batch': false
        };
        
        await addBatch(batchData);
        
        // Update the product totals
        await updateProduct(existingProductId, {
          'quantity': productData['quantity'], // This will be added to existing
          'buying_price': productData['buying_price'],
          'selling_price': productData['selling_price'],
        });
        
        return existingProductId;
      }
      
      // For new products, create the product
      final response = await http.post(
        Uri.parse(ApiConstants.products),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );

      // Check if response contains HTML (indicating a server issue)
      if ((response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) && 
          !(response.statusCode >= 200 && response.statusCode < 300)) {
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
            'quantity_purchased': productData['quantity'],
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
          print('Successfully added product with ID: ${data['product_id']}');
          
          // Always create initial batch for new product
          try {
            print('Creating initial batch for product ID: ${data['product_id']}');
            final batchData = {
              'product_id': data['product_id'],
              'product_name': productData['name'] ?? 'Unknown Product',
              'shop_id': productData['shop_id'] ?? await _getShopId(),
              'quantity': productData['quantity'],
              'quantity_purchased': productData['quantity'], 
              'cost_price': productData['cost_price'] ?? productData['buying_price'],
              'selling_price': productData['selling_price'],
              'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              'remaining': productData['quantity'],
              'added_by': await _storage.read(key: 'user_id') ?? 'Unknown',
              'added_at': DateTime.now().toIso8601String(),
              'is_initial_batch': true
            };
            
            final batchId = await addBatch(batchData);
            print('Initial batch created with ID: $batchId');
          } catch (e) {
            print('Error creating initial batch for new product: $e');
            // Try alternative approach for batch creation
            try {
              // Try the direct API endpoint for batches
              await _createInitialBatchDirectly(data['product_id'], productData);
            } catch (innerE) {
              print('Alternative batch creation also failed: $innerE');
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
  
  // Helper method for direct batch creation (alternative approach)
  Future<String> _createInitialBatchDirectly(String productId, Map<String, dynamic> productData) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }
    
    final batchData = {
      'product_id': productId,
      'product_name': productData['name'] ?? 'Unknown Product',
      'shop_id': productData['shop_id'] ?? await _getShopId(),
      'quantity': productData['quantity'],
      'quantity_purchased': productData['quantity'],
      'cost_price': productData['cost_price'] ?? productData['buying_price'],
      'selling_price': productData['selling_price'],
      'purchase_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'remaining': productData['quantity'],
      'added_by': await _storage.read(key: 'user_id') ?? 'Unknown',
      'added_at': DateTime.now().toIso8601String(),
      'is_initial_batch': true
    };
    
    final response = await http.post(
      Uri.parse(ApiConstants.batches),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(batchData),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['batch_id'] ?? 'unknown_batch_id';
    } else {
      throw Exception('Failed to create initial batch: ${response.statusCode}');
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
    
    // Ensure quantity_purchased is set if quantity is provided
    if (batchData.containsKey('quantity') && !batchData.containsKey('quantity_purchased')) {
      batchData['quantity_purchased'] = batchData['quantity'];
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

    print('Adding batch with data: ${batchData.toString()}');
    
    // Store productId and quantity for future refresh
    String productId = batchData['product_id'];

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

      String batchId = 'batch_id_unknown_${DateTime.now().millisecondsSinceEpoch}';
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          batchId = data['batch_id'] ?? batchId;
          
          // Refresh the product details after a successful batch add
          if (productId != null && productId.isNotEmpty) {
            try {
              await _getProductDetails(productId, forceRefresh: true);
              print('Successfully refreshed product data after batch addition');
            } catch (e) {
              print('Error refreshing product after batch add: $e');
            }
          }
        } catch (e) {
          print('Error parsing batch creation response: $e');
          // Store batch locally for future sync
          _saveOfflineBatch(batchData);
          batchId = 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        // For server errors, still try to parse the error message
        try {
          final errorData = jsonDecode(response.body);
          print('Server error: ${errorData['error'] ?? response.statusCode}');
          // Store batch locally for future sync
          _saveOfflineBatch(batchData);
          batchId = 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
        } catch (e) {
          print('Failed to add batch and parse error: ${response.statusCode}');
          // Store batch locally for future sync
          _saveOfflineBatch(batchData);
          batchId = 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
        }
      }
      
      return batchId;
    } catch (e) {
      print('Error adding batch: $e');
      // Store batch locally for future sync
      _saveOfflineBatch(batchData);
      return 'offline_batch_id_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Update a product's quantity after adding a batch
  Future<void> updateProductQuantity(String productId, int quantityToAdd) async {
    try {
      final token = await _storage.read(key: 'token') ?? '';
      if (token.isEmpty) {
        throw Exception('Authorization token not found');
      }
      
      // First get current product data
      final productData = await _getProductDetails(productId);
      final int currentTotal = productData['quantity'] ?? 0;
      final int currentAvailable = productData['available_quantity'] ?? currentTotal;
      
      // Calculate new quantities
      final int newTotal = currentTotal + quantityToAdd;
      final int newAvailable = currentAvailable + quantityToAdd;
      
      print('Updating product $productId quantities: Total $currentTotal -> $newTotal, Available $currentAvailable -> $newAvailable');
      
      // Update product with new quantities
      final response = await http.put(
        Uri.parse('${ApiConstants.products}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': newTotal,
          'available_quantity': newAvailable,
        }),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Successfully updated product quantities');
      } else {
        print('Error updating product quantities: ${response.statusCode}');
        throw Exception('Failed to update product quantities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating product quantity: $e');
      throw Exception('Failed to update product quantity: $e');
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
  Future<Map<String, dynamic>> _getProductDetails(String productId, {bool forceRefresh = false}) async {
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
  
  // Update a product
  Future<void> updateProduct(String productId, Map<String, dynamic> updateData) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      // Get current product data first to calculate new values
      final currentProductData = await _getProductDetails(productId);
      Map<String, dynamic> finalUpdateData = Map.from(updateData);
      
      // If updating quantity, handle it as an increment rather than replacement
      if (updateData.containsKey('quantity')) {
        int currentQuantity = currentProductData['quantity'] ?? 0;
        int quantityToAdd = updateData['quantity'];
        int newQuantity = currentQuantity + quantityToAdd;
        finalUpdateData['quantity'] = newQuantity;
        
        // Also update available quantity
        int currentAvailable = currentProductData['available_quantity'] ?? currentQuantity;
        int newAvailable = currentAvailable + quantityToAdd;
        finalUpdateData['available_quantity'] = newAvailable;
        
        print('Updating product quantity from $currentQuantity to $newQuantity');
      }
      
      final response = await http.put(
        Uri.parse('${ApiConstants.products}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(finalUpdateData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Product updated successfully');
        return;
      } else {
        // Try PATCH as fallback
        final patchResponse = await http.patch(
          Uri.parse('${ApiConstants.products}/$productId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(finalUpdateData),
        );
        
        if (patchResponse.statusCode >= 200 && patchResponse.statusCode < 300) {
          print('Product updated successfully with PATCH');
          return;
        } else {
          throw Exception('Failed to update product: ${response.statusCode}');
        }
      }
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

    print('ProductService: Attempting to delete product with ID: $productId');
    
    // First try to clean the ID - sometimes IDs have extra quotes or spaces
    String cleanedId = productId.trim().replaceAll('"', '').replaceAll("'", '');
    print('ProductService: Using cleaned ID: $cleanedId');
    
    try {
      // Using the correct URL format from ApiConstants (with trailing slash)
      final deleteUrl = ApiConstants.deleteProduct(cleanedId);
      print('ProductService: Using URL: $deleteUrl');
      
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('ProductService: Response status: ${response.statusCode}');
      print('ProductService: Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('ProductService: Product successfully deleted');
        _cleanupLocalCache(productId);
        return true;
      } else if (response.statusCode == 404) {
        // Try multiple different URL patterns to increase chances of success
        print('ProductService: Primary endpoint returned 404, trying alternative URL patterns');
        
        // List of URL patterns to try
        final urlPatterns = [
          '${ApiConstants.baseUrl}/products/$cleanedId/', // Try products endpoint with trailing slash
          '${ApiConstants.baseUrl}/products/$cleanedId',  // Try products endpoint without trailing slash
          '${ApiConstants.baseUrl}/delete-product/$cleanedId/', // Try delete-product with trailing slash
          '${ApiConstants.baseUrl}/delete-product/$cleanedId',  // Try delete-product without trailing slash
          '${ApiConstants.baseUrl}/api/products/$cleanedId/',   // Try with extra /api/ prefix
          '${ApiConstants.baseUrl}/api/delete-product/$cleanedId/'  // Try with extra /api/ prefix
        ];
        
        for (final url in urlPatterns) {
          try {
            print('ProductService: Trying alternative URL: $url');
            
            final altResponse = await http.delete(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            
            print('ProductService: Alternative URL response status: ${altResponse.statusCode}');
            
            if (altResponse.statusCode >= 200 && altResponse.statusCode < 300) {
              print('ProductService: Product successfully deleted using alternative URL: $url');
              _cleanupLocalCache(productId);
              return true;
            }
          } catch (e) {
            print('ProductService: Error with alternative URL $url: $e');
            // Continue trying other URLs
          }
        }
        
        // If we get here, all alternative URLs failed
        throw Exception('Product not found - it may have been already deleted or never existed');
      } else {
        // If the response contains HTML (which indicates a server error)
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          throw Exception('Server returned HTML instead of JSON - backend issue. Status code: ${response.statusCode}');
        }
        
        // Try to parse error from JSON response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error'] ?? 'Unknown error';
          throw Exception(errorMessage);
        } catch (parseError) {
          // If we can't parse the error, use the raw status code
          throw Exception('Failed to delete product: status ${response.statusCode}');
        }
      }
    } catch (e) {
      print('ProductService: Error deleting product: $e');
      rethrow;
    }
  }
  
  // Helper method to clean up local cache after product deletion
  Future<void> _cleanupLocalCache(String productId) async {
    try {
      // Remove product from any local cache
      final cachedProductsJson = await _storage.read(key: 'cached_products') ?? '[]';
      final List<dynamic> cachedProducts = jsonDecode(cachedProductsJson);
      
      final updatedProducts = cachedProducts.where((product) => 
          product['_id'] != productId && product['id'] != productId).toList();
      
      if (cachedProducts.length != updatedProducts.length) {
        print('ProductService: Updated local product cache after deletion');
        await _storage.write(key: 'cached_products', value: jsonEncode(updatedProducts));
      }
    } catch (e) {
      print('ProductService: Error updating local cache: $e');
      // Continue with deletion - this is just a cache cleanup
    }
  }

  // Generate mock batch data for a product when API returns HTML
  Future<List<Map<String, dynamic>>> getMockBatchData(String productId) async {
    // Create an initial batch that resembles what happens when product is first created
    final today = DateTime.now();
    final shopId = await _getShopId();
    final userName = await _storage.read(key: 'user_name') ?? 'System User';
    
    // Get product details to use real values in mock data
    String productName = 'Unknown Product';
    double costPrice = 100.0;
    int initialQuantity = 100;
    try {
      final productData = await _getProductDetails(productId);
      productName = productData['name'] ?? 'Product $productId';
      costPrice = productData['buying_price'] ?? 100.0;
      initialQuantity = productData['quantity'] ?? 100;
      if (costPrice is int) {
        costPrice = costPrice.toDouble();
      }
    } catch (e) {
      productName = 'Product $productId';
    }
    
    // Use create date if available, otherwise default to 30 days ago
    DateTime creationDate = today.subtract(Duration(days: 30));
    try {
      final productData = await _getProductDetails(productId);
      if (productData.containsKey('created_at')) {
        creationDate = DateTime.parse(productData['created_at']);
      }
    } catch (e) {
      // Use default date
    }
    
    // Only create one batch representing the initial product creation
    return [
      {
        '_id': 'initial_batch_$productId',
        'product_id': productId,
        'product_name': productName,
        'shop_id': shopId,
        'purchase_date': DateFormat('yyyy-MM-dd').format(creationDate),
        'quantity_purchased': initialQuantity,
        'remaining': initialQuantity,
        'cost_price': costPrice,
        'added_by': 'System',
        'added_at': creationDate.toIso8601String(),
        'created_at': DateFormat('yyyy-MM-dd').format(creationDate),
        'is_initial_batch': true
      }
    ];
  }

  // Direct HTTP method for product deletion - REST-style approach
  Future<bool> deleteProductDirect(String productId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    print('ProductService: Direct delete for product ID: $productId');
    
    // Clean the ID
    String cleanedId = productId.trim().replaceAll('"', '').replaceAll("'", '');
    
    // List of URLs to try in order
    final urlsToTry = [
      '${ApiConstants.baseUrl}/products/$cleanedId/',  // With trailing slash
      '${ApiConstants.baseUrl}/products/$cleanedId',   // Without trailing slash
      'https://shoptrack-w8wu.onrender.com/api/products/$cleanedId/', // Full URL with trailing slash
      'https://shoptrack-w8wu.onrender.com/api/products/$cleanedId',  // Full URL without trailing slash
      'https://shoptrack-w8wu.onrender.com/api/delete-product/$cleanedId/', // Alternative endpoint
      'https://shoptrack-w8wu.onrender.com/api/delete-product/$cleanedId'   // Alternative without slash
    ];
    
    List<String> errors = [];
    
    // Try each URL
    for (final url in urlsToTry) {
      try {
        print('ProductService: Trying direct REST URL: $url');
        
        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        print('ProductService: Direct method response for $url: ${response.statusCode}');
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('ProductService: Product successfully deleted with direct method using URL: $url');
          _cleanupLocalCache(productId);
          return true;
        } else {
          errors.add('URL $url failed with status ${response.statusCode}');
        }
      } catch (e) {
        print('ProductService: Error in direct deletion using $url: $e');
        errors.add('URL $url error: $e');
      }
    }
    
    // If we get here, all URLs failed
    throw Exception('Direct deletion failed: ${errors.join(', ')}');
  }

  // Public method to get shop ID
  Future<String> getShopId() async {
    return await _getShopId();
  }

  // Public method to get product details
  Future<Map<String, dynamic>> getProductDetails(String productId, {bool forceRefresh = false}) async {
    return await _getProductDetails(productId, forceRefresh: forceRefresh);
  }
} 