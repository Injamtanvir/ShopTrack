import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BatchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> batchData;
  final String productName;

  const BatchDetailScreen({
    Key? key,
    required this.batchData,
    required this.productName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInitialBatch = batchData['is_initial_batch'] == true;
    final batchId = batchData['_id'] ?? 'Unknown';
    final batchNumber = isInitialBatch ? 1 : (batchData['batch_number'] ?? 'Unknown');
    
    // Format dates
    String purchaseDate = 'Unknown';
    try {
      purchaseDate = batchData['purchase_date'] ?? 
          (batchData['created_at'] != null 
              ? DateFormat('yyyy-MM-dd').format(DateTime.parse(batchData['created_at']))
              : 'Unknown');
    } catch (e) {
      purchaseDate = batchData['purchase_date'] ?? batchData['created_at']?.toString().split('T')[0] ?? 'Unknown';
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isInitialBatch ? 'Initial Batch Details' : 'Batch #$batchNumber Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Batch ID', batchId),
                    _buildDetailRow('Purchase Date', purchaseDate),
                    _buildDetailRow(
                      'Quantity Purchased', 
                      '${batchData['quantity_purchased'] ?? batchData['quantity'] ?? 'Unknown'} units'
                    ),
                    _buildDetailRow(
                      'Remaining', 
                      '${batchData['remaining'] ?? 'Unknown'} units'
                    ),
                    _buildDetailRow(
                      'Cost Price', 
                      '\$${(batchData['cost_price'] ?? 0).toStringAsFixed(2)}'
                    ),
                    _buildDetailRow(
                      'Selling Price', 
                      '\$${(batchData['selling_price'] ?? 0).toStringAsFixed(2)}'
                    ),
                    if (batchData['added_by'] != null)
                      _buildDetailRow('Added By', batchData['added_by']),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // More details if needed
            if (batchData.containsKey('notes'))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(batchData['notes'] ?? 'No notes available'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 