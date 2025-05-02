import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/product_service.dart';
import '../constants/theme_constants.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  static const routeName = '/add-product';
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<bool> _checkConnectivity() async {
    try {
      // Implement a better connectivity check that tries to access the server
      // Don't just rely on device network status which could be misleading
      bool isConnected = await _productService.testConnection();
      return isConnected;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Check connectivity before proceeding
        bool isConnected = await _checkConnectivity();
        
        // Get product data from form
        final String name = _nameController.text.trim();
        final String description = _descriptionController.text.trim();
        final int quantity = int.parse(_quantityController.text.trim());
        final double costPrice = double.parse(_costPriceController.text.trim());
        final double sellingPrice = double.parse(_sellingPriceController.text.trim());
        final String barcode = _barcodeController.text.trim();
        
        final shopId = await _storage.read(key: 'shop_id') ?? '';
        final userId = await _storage.read(key: 'user_id') ?? '';

        // Create product data
        Map<String, dynamic> productData = {
          'name': name,
          'description': description,
          'quantity': quantity,
          'available_quantity': quantity,
          'cost_price': costPrice,
          'selling_price': sellingPrice,
          'shop_id': shopId,
          'added_by': userId,
        };

        if (barcode.isNotEmpty) {
          productData['barcode'] = barcode;
        }

        // Add the product
        final createdProduct = await _productService.addProduct(productData);
        
        // If successful, create initial batch
        if (createdProduct != null && createdProduct.containsKey('_id')) {
          String productId = createdProduct['_id'];
          
          // Create initial batch data
          Map<String, dynamic> initialBatchData = {
            'product_id': productId,
            'product_name': name,
            'quantity': quantity,
            'quantity_purchased': quantity,
            'cost_price': costPrice,
            'selling_price': sellingPrice,
            'purchase_date': DateTime.now().toString().split(' ')[0],
            'remaining': quantity,
            'shop_id': shopId,
            'added_by': userId,
            'is_initial_batch': true,
            'batch_number': 1
          };
          
          try {
            // Create initial batch
            await _productService.addBatch(initialBatchData);
            print('Created initial batch for product $name');
          } catch (e) {
            print('Error creating initial batch: $e');
            // Continue with success flow even if batch creation fails
            // The product was still created successfully
          }
        }

        // Check if the product was added in offline mode
        final wasOffline = await _storage.read(key: 'last_product_offline') == 'true';
        
        setState(() {
          _isSuccess = true;
          _isLoading = false;
          // Only show offline notification if we're truly offline
          _errorMessage = wasOffline 
              ? 'Product added in offline mode. Changes will be synced when connection is restored.'
              : null;
        });
        
        // Clear form fields
        _nameController.clear();
        _descriptionController.clear();
        _quantityController.clear();
        _costPriceController.clear();
        _sellingPriceController.clear();
        _barcodeController.clear();
        
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = 'Failed to add product: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        elevation: 0,
      ),
      body: _isSuccess
          ? _buildSuccessScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Initial Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an initial quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a cost price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a selling price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Add Product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Product Added Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.orange.shade800),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSuccess = false;
                });
              },
              child: const Text('Add Another Product'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}