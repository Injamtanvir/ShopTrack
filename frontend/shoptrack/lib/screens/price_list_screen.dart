
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../utils/sharing_utils.dart';

class PriceListScreen extends StatefulWidget {
  static const routeName = '/price-list';
  final bool showShareOptions;
  const PriceListScreen({Key? key, this.showShareOptions = false}) : super(key: key);

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _priceListData;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Filter options
  bool _showOutOfStock = true;
  String _sortBy = 'name'; // 'name', 'price_asc', 'price_desc'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPriceList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPriceList() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _apiService.getProductPriceList().then((data) {
      if (mounted) {
        setState(() {
          _priceListData = data;
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _sharePriceList() async {
    if (_priceListData == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate PDF using the utility class
      final pdfFile = await SharingUtils.generatePriceListPdf(
        shopName: _priceListData!['shop_name'],
        shopAddress: _priceListData!['shop_address'],
        shopId: _priceListData!['shop_id'],
        products: _filteredProducts,
      );

      // Share the PDF
      if (mounted) {
        SharingUtils.shareFile(
            context,
            pdfFile,
            'Price List - ${_priceListData!['shop_name']}'
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Filter and sort products
  List<dynamic> get _filteredProducts {
    if (_priceListData == null) return [];

    List<dynamic> products = [..._priceListData!['products']];

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) =>
          product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter out of stock items
    if (!_showOutOfStock) {
      products = products.where((product) => product['quantity'] > 0).toList();
    }

    // Sort products
    switch (_sortBy) {
      case 'name':
        products.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
        break;
      case 'price_asc':
        products.sort((a, b) => a['selling_price'].compareTo(b['selling_price']));
        break;
      case 'price_desc':
        products.sort((a, b) => b['selling_price'].compareTo(a['selling_price']));
        break;
    }

    return products;
  }

  // Format price safely
  String _formatPrice(dynamic price) {
    try {
      if (price is int) {
        return '\$${price.toDouble().toStringAsFixed(2)}';
      } else if (price is double) {
        return '\$${price.toStringAsFixed(2)}';
      } else {
        return '\$${double.parse(price.toString()).toStringAsFixed(2)}';
      }
    } catch (e) {
      return '\$0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price List'),
        backgroundColor: Colors.indigo,
        actions: [
          if (!_isLoading && _priceListData != null)
            IconButton(
              icon: _isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.share),
              onPressed: _isProcessing ? null : _sharePriceList,
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
          : Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Filter options
                Row(
                  children: [
                    // Sort dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
                            hint: const Text('Sort by'),
                            items: const [
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Name (A-Z)'),
                              ),
                              DropdownMenuItem(
                                value: 'price_asc',
                                child: Text('Price (Low to High)'),
                              ),
                              DropdownMenuItem(
                                value: 'price_desc',
                                child: Text('Price (High to Low)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Out of stock switch
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Show out of stock'),
                            Switch(
                              value: _showOutOfStock,
                              activeColor: Colors.indigo,
                              onChanged: (value) {
                                setState(() {
                                  _showOutOfStock = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Shop info and products list
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop info card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                    // Products heading with count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Products (${_filteredProducts.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Share button
                        if (widget.showShareOptions)
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _sharePriceList,
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // No products found after filtering
                    if (_filteredProducts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products match your filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                    // Products Grid View
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final bool inStock = product['quantity'] > 0;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? 'Unknown Product',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _formatPrice(product['selling_price']),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: inStock ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        inStock
                                            ? 'In Stock: ${product['quantity']}'
                                            : 'Out of Stock',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: inStock ? Colors.blue : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Out of stock overlay
                                if (!inStock)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'OUT OF STOCK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Share button at bottom
                    if (widget.showShareOptions && _filteredProducts.isNotEmpty)
                      Center(
                        child: SizedBox(
                          width: 200,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share Price List'),
                            onPressed: _isProcessing ? null : _sharePriceList,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}