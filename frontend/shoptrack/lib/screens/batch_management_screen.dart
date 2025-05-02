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
  bool _isLoading = true;
  List<Batch> _batches = [];
  String? _errorMessage;

  // Controllers for adding new batch
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isAddingBatch = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();
    
    // Initialize selling price from product
    _sellingPriceController.text = widget.product.sellingPrice.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addBatch() async {
    if (_quantityController.text.isEmpty || _costPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isAddingBatch = true;
    });

    try {
      // Parse inputs
      final int newQuantity = int.parse(_quantityController.text);
      final double newCostPrice = double.parse(_costPriceController.text);
      double? newSellingPrice;
      
      if (_sellingPriceController.text.isNotEmpty) {
        newSellingPrice = double.parse(_sellingPriceController.text);
      }

      // Create batch data
      final batchData = {
        'product_id': widget.product.id,
        'product_name': widget.product.name,
        'quantity': newQuantity,
        'quantity_purchased': newQuantity,
        'cost_price': newCostPrice,
        'purchase_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'remaining': newQuantity, // Initially all items are remaining
        'shop_id': await _getShopId(),
        'is_initial_batch': false // Mark as not an initial batch
      };

      // Add new selling price if it's different from the current one
      if (newSellingPrice != null && newSellingPrice != widget.product.sellingPrice) {
        batchData['selling_price'] = newSellingPrice;
        
        // Also update the product price
        try {
          await _productService.updateProduct(widget.product.id, {
            'selling_price': newSellingPrice
          });
          print('Updated product selling price to $newSellingPrice');
        } catch (e) {
          print('Error updating product price: $e');
          // Continue with batch creation even if price update fails
        }
      } else {
        // Use current selling price if not changing
        batchData['selling_price'] = widget.product.sellingPrice;
      }

      // Add batch on the server
      final batchId = await _productService.addBatch(batchData);
      
      // Clear the form
      _quantityController.clear();
      _costPriceController.clear();
      
      // Set a flag to show we need to reload products
      bool needsRefresh = true;
      
      if (batchId.startsWith('offline_batch_id') || batchId.startsWith('mock_')) {
        // If we got a mock ID, it means the API had issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch was saved in offline mode due to server issues. Changes will be synced when connection is restored.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        
        // Create a local Batch object to display immediately
        final newBatch = Batch(
          id: batchId,
          productId: widget.product.id,
          productName: widget.product.name,
          purchaseDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          quantityPurchased: newQuantity,
          remaining: newQuantity,
          costPrice: newCostPrice,
          createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          sellingPrice: newSellingPrice ?? widget.product.sellingPrice,
        );
        
        // Add the batch to our local list
        setState(() {
          _batches = [newBatch, ..._batches];
          _isAddingBatch = false;
        });
      } else {
        // Successful server-side addition
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload batches to show the new one
        await _loadBatches();
      }
      
      // Notify the parent screen that the products need to be refreshed
      if (needsRefresh && mounted) {
        Navigator.pop(context, {'refreshNeeded': true});
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add batch: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error adding batch: $e');
    } finally {
      setState(() {
        _isAddingBatch = false;
      });
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
                            Text('Total Quantity: ${widget.product.quantity}'),
                            Text('On Hold: ${widget.product.quantityOnHold}'),
                            Text('Available: ${widget.product.availableQuantity}'),
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Purchase date
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Purchase Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Quantity
                      TextField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          hintText: 'Enter quantity purchased',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      
                      // Cost price
                      TextField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price Per Unit *',
                          hintText: 'Enter cost price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      
                      // Selling price
                      TextField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'New Selling Price (optional)',
                          hintText: 'Enter new selling price if changed',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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