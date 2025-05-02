import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/batch.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../constants/theme_constants.dart';
import 'dart:convert';

class BatchManagementScreen extends StatefulWidget {
  final Product product;

  const BatchManagementScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<Batch> _batches = [];
  String? _errorMessage;
  bool _expandAddBatch = false;
  
  // Variables to store updated product quantities
  int _updatedQuantity = 0;
  int _updatedAvailable = 0;
  int _updatedOnHold = 0;

  // Controllers for adding new batch
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isAddingBatch = false;

  @override
  void initState() {
    super.initState();
    // Initialize updated quantities from product
    _updatedQuantity = widget.product.quantity;
    _updatedAvailable = widget.product.availableQuantity;
    _updatedOnHold = widget.product.quantityOnHold;
    
    // Initialize date to today
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Load data - always refresh product data first to get latest quantities
    _refreshProductData().then((_) {
      // After product refresh, then load batches
      _loadBatches();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final batchData = await _productService.getBatches(widget.product.id);
      
      // Filter out mock batches if we have real ones
      List<dynamic> filteredBatchData = batchData;
      bool hasMockBatches = batchData.any((batch) => 
          (batch['_id'] as String?)?.startsWith('mock_') ?? false);
      
      bool hasRealBatches = batchData.any((batch) => 
          !((batch['_id'] as String?)?.startsWith('mock_') ?? false));
      
      // If we have both mock and real batches, filter out the mock ones
      if (hasMockBatches && hasRealBatches) {
        filteredBatchData = batchData.where((batch) => 
            !((batch['_id'] as String?)?.startsWith('mock_') ?? false)).toList();
      }
      
      final batches = filteredBatchData.map((data) => Batch.fromJson(data)).toList();
      
      // Sort batches - initial batch first, then by date (oldest to newest)
      batches.sort((a, b) {
        // Initial batch always comes first
        if (a.isInitialBatch && !b.isInitialBatch) return -1;
        if (!a.isInitialBatch && b.isInitialBatch) return 1;
        
        // Otherwise sort by date
        try {
          final dateA = DateFormat('yyyy-MM-dd').parse(a.purchaseDate);
          final dateB = DateFormat('yyyy-MM-dd').parse(b.purchaseDate);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0; // Keep original order if parsing fails
        }
      });
      
      // Calculate total quantity from batches
      int totalQuantityFromBatches = 0;
      for (var batch in batches) {
        totalQuantityFromBatches += batch.quantityPurchased;
      }
      
      // If the product quantity doesn't match the batch total, update the display
      if (totalQuantityFromBatches != _updatedQuantity) {
        print('Batch total ($totalQuantityFromBatches) differs from product quantity ($_updatedQuantity)');
        
        // Update our display with the batch total
        setState(() {
          _updatedQuantity = totalQuantityFromBatches;
          _updatedAvailable = totalQuantityFromBatches - _updatedOnHold;
        });
        
        // Try to update the server with the corrected values
        try {
          await _productService.updateProduct(widget.product.id, {
            'quantity': totalQuantityFromBatches,
            'available_quantity': totalQuantityFromBatches - _updatedOnHold
          });
          print('Updated server with corrected quantities');
        } catch (e) {
          print('Failed to update server with corrected quantities: $e');
        }
      }
      
      setState(() {
        _batches = batches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load batches: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime currentDate = _dateController.text.isNotEmpty 
        ? DateTime.parse(_dateController.text) 
        : DateTime.now();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != currentDate) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _addBatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAddingBatch = true;
      _errorMessage = null;
    });

    try {
      // Parse quantity to ensure it's a valid integer
      final int newQuantity = int.parse(_quantityController.text);
      
      final batchData = {
        'product_id': widget.product.id,
        'quantity': newQuantity,
        'cost_price': double.parse(_costPriceController.text),
        'purchase_date': _dateController.text,
      };

      // Add the batch
      final batchId = await _productService.addBatch(batchData);

      if (mounted) {
        // Update our local state to show the new quantity immediately
        setState(() {
          _updatedQuantity += newQuantity;
          _updatedAvailable += newQuantity;
        });
        
        // After successfully adding a batch, we need to:
        // 1. Refresh product data to get updated quantities
        // 2. Reload batches to see the new batch
        // 3. Reset the form
        
        // Refresh product data - use a slight delay to allow server to process
        await Future.delayed(Duration(milliseconds: 300));
        await _refreshProductData();
        
        // Reload batches to include the new one - with delay to ensure server has updated
        await Future.delayed(Duration(milliseconds: 300));
        await _loadBatches();
        
        // Reset form
        _quantityController.clear();
        _costPriceController.clear();
        _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        setState(() {
          _isAddingBatch = false;
          _expandAddBatch = false; // Collapse the add batch form
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingBatch = false;
          _errorMessage = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Get shop ID
  Future<String> _getShopId() async {
    try {
      final ProductService productService = ProductService();
      return await productService.getShopId();
    } catch (e) {
      print('Error getting shop ID: $e');
      return '';
    }
  }
  
  // Force sync batches with server
  Future<void> _syncWithServer() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Refresh product data
      await _refreshProductData();
      
      // Reload batches
      await _loadBatches();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batches synced successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync batches: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add method to refresh product data
  Future<void> _refreshProductData() async {
    try {
      // Get updated product details with force refresh to ensure latest data
      final productData = await _productService.getProductDetails(widget.product.id, forceRefresh: true);

      if (mounted && productData != null) {
        // Get batches to calculate total independently
        try {
          final batchData = await _productService.getBatches(widget.product.id);
          if (batchData.isNotEmpty) {
            // Calculate total quantity from batches
            int batchTotalQuantity = 0;
            for (var batch in batchData) {
              var quantity = batch['quantity'] ?? batch['quantity_purchased'] ?? 0;
              batchTotalQuantity += int.parse(quantity.toString());
            }
            
            // Get quantities from product data
            final int productTotalQuantity = productData['quantity'] ?? 0;
            final int onHoldQuantity = productData['quantity_on_hold'] ?? 0;
            final int availableQuantity = productData['available_quantity'] ?? (productTotalQuantity - onHoldQuantity);
            
            // If there's a mismatch, prefer the batch total
            if (batchTotalQuantity != productTotalQuantity) {
              print('Quantity mismatch detected: Product shows $productTotalQuantity, batches sum to $batchTotalQuantity');
              
              // Update the state with corrected quantities
              setState(() {
                _updatedQuantity = batchTotalQuantity;
                _updatedAvailable = batchTotalQuantity - onHoldQuantity;
                _updatedOnHold = onHoldQuantity;
              });
            } else {
              // Use product data as is
              setState(() {
                _updatedQuantity = productTotalQuantity;
                _updatedAvailable = availableQuantity;
                _updatedOnHold = onHoldQuantity;
              });
            }
          } else {
            // No batches, use product data
            setState(() {
              _updatedQuantity = productData['quantity'] ?? 0;
              _updatedAvailable = productData['available_quantity'] ?? _updatedQuantity;
              _updatedOnHold = productData['quantity_on_hold'] ?? 0;
            });
          }
        } catch (e) {
          print('Error fetching batch data for quantity verification: $e');
          // Fall back to product data
          setState(() {
            _updatedQuantity = productData['quantity'] ?? 0;
            _updatedAvailable = productData['available_quantity'] ?? _updatedQuantity;
            _updatedOnHold = productData['quantity_on_hold'] ?? 0;
          });
        }
      }
      
      print('Product data refreshed successfully: Quantity $_updatedQuantity, Available $_updatedAvailable');
    } catch (e) {
      print('Error refreshing product data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batches for ${widget.product.name}'),
        backgroundColor: kNewPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Sync button to force sync with server
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sync with server',
            onPressed: () => _syncWithServer(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Quantity: ${_updatedQuantity}'),
                            Text('On Hold: ${_updatedOnHold}'),
                            Text('Available: ${_updatedAvailable}'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Current Selling Price: \$${widget.product.sellingPrice.toStringAsFixed(2)}'),
                            Text('Last Updated: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.product.updatedAt))}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add new batch section
            ExpansionTile(
              title: const Text(
                'Add New Batch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: _expandAddBatch,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandAddBatch = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date field and picker
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Date',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a date';
                                  }
                                  return null;
                                },
                                onTap: () => _selectDate(context),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.calendar_today),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Quantity
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity *',
                            hintText: 'Enter quantity purchased',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null || int.parse(value) <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Cost price
                        TextFormField(
                          controller: _costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Cost Price Per Unit *',
                            hintText: 'Enter cost price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter cost price';
                            }
                            if (double.tryParse(value) == null || double.parse(value) <= 0) {
                              return 'Please enter a valid cost price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Add button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isAddingBatch ? null : _addBatch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kNewPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isAddingBatch
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Add Batch'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Batches list
            const Text(
              'Batch History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _batches.isEmpty
                          ? const Center(child: Text('No batches found'))
                          : ListView.builder(
                              itemCount: _batches.length,
                              itemBuilder: (context, index) {
                                final batch = _batches[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(batch.isInitialBatch 
                                      ? 'Initial Batch (#${index + 1})' 
                                      : 'Batch #${index + 1}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: ${batch.purchaseDate}'),
                                        Text('Quantity: ${batch.quantityPurchased} units'),
                                        Text('Remaining: ${batch.remaining} units'),
                                        Text('Cost Price: \$${batch.costPrice.toStringAsFixed(2)}'),
                                        if (batch.sellingPrice != null)
                                          Text('Selling Price: \$${batch.sellingPrice!.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
} 