import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../widgets/batch_history_card.dart';

class BatchHistoryScreen extends StatefulWidget {
  static const routeName = '/batch-history';
  final String productId;
  final String productName;
  final List<Batch> batches;

  const BatchHistoryScreen({
    Key? key,
    required this.batches,
  }) : super(key: key);

  @override
  State<BatchHistoryScreen> createState() => _BatchHistoryScreenState();
}

class _BatchHistoryScreenState extends State<BatchHistoryScreen> {
  late List<Batch> _filteredBatches;
  String _sortBy = 'date';
  bool _ascending = false;
  String _filterBy = 'all';

  @override
  void initState() {
    super.initState();
    _filteredBatches = List.from(widget.batches);
    _sortBatches();
  }

  void _sortBatches() {
    switch (_sortBy) {
      case 'date':
        _filteredBatches.sort((a, b) => _ascending
            ? a.purchaseDate.compareTo(b.purchaseDate)
            : b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case 'quantity':
        _filteredBatches.sort((a, b) => _ascending
            ? a.quantityPurchased.compareTo(b.quantityPurchased)
            : b.quantityPurchased.compareTo(a.quantityPurchased));
        break;
      case 'remaining':
        _filteredBatches.sort((a, b) => _ascending
            ? a.remaining.compareTo(b.remaining)
            : b.remaining.compareTo(a.remaining));
        break;
      case 'cost':
        _filteredBatches.sort((a, b) => _ascending
            ? a.costPrice.compareTo(b.costPrice)
            : b.costPrice.compareTo(a.costPrice));
        break;
    }
  }

  void _filterBatches() {
    _filteredBatches = widget.batches.where((batch) {
      switch (_filterBy) {
        case 'out_of_stock':
          return batch.remaining <= 0;
        case 'low_stock':
          final ratio = batch.remaining / batch.quantityPurchased;
          return ratio > 0 && ratio <= 0.2;
        case 'medium_stock':
          final ratio = batch.remaining / batch.quantityPurchased;
          return ratio > 0.2 && ratio <= 0.5;
        case 'well_stocked':
          final ratio = batch.remaining / batch.quantityPurchased;
          return ratio > 0.5;
        default:
          return true;
      }
    }).toList();
    _sortBatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = value;
                  _ascending = true;
                }
                _sortBatches();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'quantity',
                child: Text('Sort by Quantity'),
              ),
              const PopupMenuItem(
                value: 'remaining',
                child: Text('Sort by Remaining'),
              ),
              const PopupMenuItem(
                value: 'cost',
                child: Text('Sort by Cost'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterBy = value;
                _filterBatches();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Batches'),
              ),
              const PopupMenuItem(
                value: 'out_of_stock',
                child: Text('Out of Stock'),
              ),
              const PopupMenuItem(
                value: 'low_stock',
                child: Text('Low Stock'),
              ),
              const PopupMenuItem(
                value: 'medium_stock',
                child: Text('Medium Stock'),
              ),
              const PopupMenuItem(
                value: 'well_stocked',
                child: Text('Well Stocked'),
              ),
            ],
          ),
        ],
      ),
      body: _filteredBatches.isEmpty
          ? const Center(
              child: Text(
                'No batches found',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredBatches.length,
              itemBuilder: (context, index) {
                return BatchHistoryCard(
                  batch: _filteredBatches[index],
                  onTap: () {
                    // TODO: Navigate to batch details screen
                  },
                );
              },
            ),
    );
  }
} 