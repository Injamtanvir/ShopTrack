import 'package:flutter/material.dart';

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
    final batchNumber = isInitialBatch ? 1 : (batchData['batch_number'] ?? '?');
    final purchaseDate = batchData['purchase_date'] ?? batchData['created_at']?.toString().split('T')[0] ?? 'Unknown';
    final quantity = batchData['quantity_purchased'] ?? batchData['quantity'] ?? 0;
    final remaining = batchData['remaining'] ?? 0;
    final costPrice = batchData['cost_price'] ?? 0.0;
    final sellingPrice = batchData['selling_price'] ?? 0.0;
    final addedBy = batchData['added_by'] ?? 'Unknown';
    final addedAt = batchData['added_at']?.toString().split('T')[0] ?? purchaseDate;

    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              isInitialBatch ? 'Initial Batch (#1)' : 'Batch #$batchNumber',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Product: $productName',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            Divider(height: 32),
            
            // Batch Information
            _buildInfoRow('Purchase Date', purchaseDate),
            _buildInfoRow('Quantity Purchased', '$quantity units'),
            _buildInfoRow('Remaining', '$remaining units'),
            _buildInfoRow('Cost Price', '\$${costPrice.toStringAsFixed(2)}'),
            _buildInfoRow('Selling Price', '\$${sellingPrice.toStringAsFixed(2)}'),
            
            Divider(height: 32),
            
            // Additional Information
            Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Added By', addedBy),
            _buildInfoRow('Date Added', addedAt),
            _buildInfoRow('Batch ID', batchData['_id'] ?? 'Unknown'),
            
            // If offline, show indicator
            if (batchData['is_offline'] == true)
              Container(
                margin: EdgeInsets.only(top: 24),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      color: Colors.orange.shade800,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This batch was created in offline mode and will be synced when connection is restored.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 