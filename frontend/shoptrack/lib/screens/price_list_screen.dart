import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class PriceListScreen extends StatefulWidget {
  static const routeName = '/price-list';

  const PriceListScreen({Key? key}) : super(key: key);

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _priceListData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPriceList();
  }

  Future<void> _loadPriceList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getProductPriceList();
      setState(() {
        _priceListData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sharePriceList() {
    if (_priceListData == null) return;

    // In a real app, you would generate a PDF here
    // For now, we'll just show a dialog about sharing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Price List'),
        content: const Text('This would generate and share a PDF of your price list. In a production app, this would open sharing options.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price List'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _priceListData != null ? _sharePriceList : null,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPriceList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                onPressed: _loadPriceList,
              ),
            ],
          ),
        ),
      )
          : _priceListData == null || (_priceListData!['products'] as List).isEmpty
          ? const Center(
        child: Text('No products found. Add some products!'),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _priceListData!['shop_name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _priceListData!['shop_address'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Products Price List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Price'), numeric: true),
                DataColumn(label: Text('Qty'), numeric: true),
              ],
              rows: [
                for (var product in _priceListData!['products'])
                  DataRow(
                    cells: [
                      DataCell(Text(product['name'])),
                      DataCell(Text('\$${product['selling_price'].toStringAsFixed(2)}')),
                      DataCell(Text('${product['quantity']}')),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}