import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/batch.dart';

class BatchHistoryCard extends StatelessWidget {
  final Batch batch;
  final VoidCallback? onTap;

  const BatchHistoryCard({
    Key? key,
    required this.batch,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 1);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Purchase Date: ${dateFormat.format(DateTime.parse(batch.purchaseDate))}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Quantity',
                '${batch.quantityPurchased} units',
                'Remaining',
                '${batch.remaining} units',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Cost Price',
                currencyFormat.format(batch.costPrice),
                'Total Cost',
                currencyFormat.format(batch.totalCost),
              ),
              if (batch.sellingPrice != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Selling Price',
                  currencyFormat.format(batch.sellingPrice!),
                  'Margin',
                  percentFormat.format(batch.profitMarginPercentage! / 100),
                ),
              ],
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: batch.remaining / batch.quantityPurchased,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(batch.remaining / batch.quantityPurchased),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final ratio = batch.remaining / batch.quantityPurchased;
    String label;
    Color color;

    if (ratio <= 0) {
      label = 'Out of Stock';
      color = Colors.red;
    } else if (ratio <= 0.2) {
      label = 'Low Stock';
      color = Colors.orange;
    } else if (ratio <= 0.5) {
      label = 'Medium Stock';
      color = Colors.blue;
    } else {
      label = 'Well Stocked';
      color = Colors.green;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(label1, value1),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(label2, value2),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double ratio) {
    if (ratio <= 0.2) {
      return Colors.red;
    } else if (ratio <= 0.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
} 