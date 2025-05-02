import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/batch.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../constants/theme_constants.dart';
import 'dart:convert';
import '../widgets/custom_snackbar.dart';
import 'batch_history_screen.dart';
import 'batch_detail_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BatchManagementScreen extends StatefulWidget {
  final Product product;

  const BatchManagementScreen({Key? key, required this.product}) : super(key: key);

  @override
  _BatchManagementScreenState createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  final ProductService _productService = ProductService();
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _loadingBatches = false;
  List<dynamic> _batches = [];
  String? _errorMessage;
  
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _costPriceController = TextEditingController();
  TextEditingController _sellingPriceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sellingPriceController.text = widget.product.sellingPrice.toString();
    _loadBatches();
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
      _loadingBatches = true;
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
      
      // Sort batches by date (newest first)
      filteredBatchData.sort((a, b) {
        final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
        final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _batches = filteredBatchData;
        _loadingBatches = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load batches: $e';
        _loadingBatches = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBatch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final shopId = await _storage.read(key: 'shop_id') ?? '';
        final userId = await _storage.read(key: 'user_id') ?? '';
        
        final Map<String, dynamic> batchData = {
          'product_id': widget.product.id,
          'product_name': widget.product.name,
          'shop_id': shopId,
          'quantity': int.parse(_quantityController.text),
          'quantity_purchased': int.parse(_quantityController.text),
          'cost_price': double.parse(_costPriceController.text),
          'selling_price': double.parse(_sellingPriceController.text),
          'purchase_date': _selectedDate.toString().split(' ')[0],
          'remaining': int.parse(_quantityController.text),
          'added_by': userId,
          'is_initial_batch': false
        };
        
        final batchId = await _productService.addBatch(batchData);
        
        // Check if this was processed in offline mode
        final wasOffline = await _storage.read(key: 'last_batch_offline') == 'true';
        
        // Only show offline message if truly offline
        if (wasOffline) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Batch was saved in offline mode due to server issues. Changes will be synced when connection is restored.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Batch added successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        
        // Refresh the product and batches
        await _loadBatches();
        
        // Clear form fields and collapse form
        _quantityController.clear();
        _costPriceController.clear();
        setState(() {
          _isExpanded = false;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to add batch: $e';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add batch: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batches for ${widget.product.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBatches,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product summary card
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Quantity: ${widget.product.quantity}'),
                              Text('On Hold: ${widget.product.quantity - widget.product.availableQuantity}'),
                              Text('Available: ${widget.product.availableQuantity}'),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Current Selling Price: \$${widget.product.sellingPrice.toStringAsFixed(2)}'),
                            Text('Last Updated: ${widget.product.updatedAt.split('T')[0]}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Add New Batch section
            Card(
              margin: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Add New Batch',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                  if (_isExpanded)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a quantity';
                                }
                                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _costPriceController,
                              decoration: InputDecoration(
                                labelText: 'Cost Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a cost price';
                                }
                                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                  return 'Please enter a valid cost price';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _sellingPriceController,
                              decoration: InputDecoration(
                                labelText: 'Selling Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a selling price';
                                }
                                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                  return 'Please enter a valid selling price';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Purchase Date',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedDate.toString().split(' ')[0],
                                      ),
                                      Icon(Icons.calendar_today),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitBatch,
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text('Add Batch'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Batch History section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Batch History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (_loadingBatches)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_batches.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No batch history found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _batches.length,
                itemBuilder: (context, index) {
                  final batch = _batches[index];
                  final isInitialBatch = batch['is_initial_batch'] == true;
                  
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        isInitialBatch ? 'Initial Batch (#1)' : 'Batch #${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${batch['purchase_date'] ?? batch['created_at']?.toString().split('T')[0] ?? 'Unknown'}'),
                          Text('Quantity: ${batch['quantity_purchased'] ?? batch['quantity']} units'),
                          Text('Remaining: ${batch['remaining']} units'),
                          Text('Cost Price: \$${(batch['cost_price'] ?? 0).toStringAsFixed(2)}'),
                          Text('Selling Price: \$${(batch['selling_price'] ?? 0).toStringAsFixed(2)}'),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        // Navigate to batch detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BatchDetailScreen(
                              batchData: batch,
                              productName: widget.product.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
} 