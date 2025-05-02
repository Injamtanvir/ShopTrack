import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'batch_detail_screen.dart';

class BatchHistoryScreen extends StatefulWidget {
  final String productId;
  final String productName;
  
  const BatchHistoryScreen({
    Key? key, 
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  _BatchHistoryScreenState createState() => _BatchHistoryScreenState();
}

class _BatchHistoryScreenState extends State<BatchHistoryScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = true;
  List<dynamic> _batches = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final batchData = await _productService.getBatches(widget.productId);
      
      // Sort batches - initial batch first, then by date (oldest to newest)
      batchData.sort((a, b) {
        // Initial batch always comes first
        if (a['is_initial_batch'] == true && b['is_initial_batch'] != true) return -1;
        if (a['is_initial_batch'] != true && b['is_initial_batch'] == true) return 1;
        
        // Sort by date
        final dateA = a['purchase_date'] ?? a['created_at'] ?? '';
        final dateB = b['purchase_date'] ?? b['created_at'] ?? '';
        return dateA.compareTo(dateB);
      });
      
      setState(() {
        _batches = batchData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load batches: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch History - ${widget.productName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _batches.isEmpty
                  ? const Center(child: Text('No batch history found'))
                  : ListView.builder(
                      itemCount: _batches.length,
                      itemBuilder: (context, index) {
                        final batch = _batches[index];
                        final isInitialBatch = batch['is_initial_batch'] == true;
                        
                        // Format the date
                        String purchaseDate = 'Unknown';
                        try {
                          purchaseDate = batch['purchase_date'] ?? 
                              (batch['created_at'] != null 
                                  ? DateFormat('yyyy-MM-dd').format(DateTime.parse(batch['created_at']))
                                  : 'Unknown');
                        } catch (e) {
                          purchaseDate = batch['purchase_date'] ?? batch['created_at']?.toString().split('T')[0] ?? 'Unknown';
                        }
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                              isInitialBatch ? 'Initial Batch (#1)' : 'Batch #${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: $purchaseDate'),
                                Text('Quantity: ${batch['quantity_purchased'] ?? batch['quantity'] ?? 'Unknown'} units'),
                                Text('Remaining: ${batch['remaining'] ?? 'Unknown'} units'),
                                Text('Cost Price: \$${(batch['cost_price'] ?? 0).toStringAsFixed(2)}'),
                                Text('Selling Price: \$${(batch['selling_price'] ?? 0).toStringAsFixed(2)}'),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BatchDetailScreen(
                                    batchData: batch,
                                    productName: widget.productName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
} 