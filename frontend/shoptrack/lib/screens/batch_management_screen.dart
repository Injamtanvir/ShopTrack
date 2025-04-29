import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/batch.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../constants/theme_constants.dart';

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
      final batches = batchData.map((data) => Batch.fromJson(data)).toList();
      
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
      final batchData = {
        'product_id': widget.product.id,
        'quantity': int.parse(_quantityController.text),
        'cost_price': double.parse(_costPriceController.text),
        'purchase_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      // Add new selling price if it's different from the current one
      if (_sellingPriceController.text.isNotEmpty && 
          double.parse(_sellingPriceController.text) != widget.product.sellingPrice) {
        batchData['new_selling_price'] = double.parse(_sellingPriceController.text);
      }

      await _productService.addBatch(batchData);
      
      // Clear the form and reload batches
      _quantityController.clear();
      _costPriceController.clear();
      await _loadBatches();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add batch: $e')),
      );
    } finally {
      setState(() {
        _isAddingBatch = false;
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
                                    title: Text('Batch #${index + 1}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: ${batch.purchaseDate}'),
                                        Text('Quantity: ${batch.quantityPurchased} units'),
                                        Text('Remaining: ${batch.remaining} units'),
                                        Text('Cost Price: \$${batch.costPrice.toStringAsFixed(2)}'),
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