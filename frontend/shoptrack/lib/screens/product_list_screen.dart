import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show TextInputType;
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_button.dart';
import '../utils/error_handler.dart';
import '../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';
import 'batch_management_screen.dart';
import 'profit_report_screen.dart';

class ProductListScreen extends StatefulWidget {
  static const routeName = '/product-list';
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productsJson = await _productService.getProducts();
      if (!mounted) return;
      
      // Store shop_id if it's in the first product
      if (productsJson.isNotEmpty && productsJson[0].containsKey('shop_id')) {
        _shopId = productsJson[0]['shop_id'];
      }

      setState(() {
        _products = productsJson.map<Product>((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrice(Product product) async {
    // Check network connectivity
    final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
    if (!connectivityProvider.isOnline) {
      ErrorHandler.showErrorSnackBar(
        context, 
        'No internet connection. Please connect your device to a network.'
      );
      return;
    }

    final TextEditingController controller = TextEditingController(
      text: product.sellingPrice.toString(),
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Price for ${product.name}'),
          content: TextField(
            controller: controller,
            // keyboardType: TextInputType.numberWithOptions(decimal: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'New Selling Price',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                if (double.tryParse(controller.text) != null) {
                  Navigator.of(dialogContext).pop();

                  try {
                    await _apiService.updateProductPrice(
                      productId: product.id,
                      sellingPrice: double.parse(controller.text),
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Price updated successfully')),
                    );

                    _loadProducts(); // Reload the list
                  } catch (e) {
                    if (!mounted) return;
                    ErrorHandler.showErrorSnackBar(context, e);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // New method to manage batches
  void _manageBatches(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchManagementScreen(product: product),
      ),
    ).then((_) => _loadProducts()); // Reload products when returning
  }
  
  // New method to view profit report
  void _viewProfitReport() {
    if (_shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop ID not available')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfitReportScreen(shopId: _shopId!),
      ),
    );
  }

  // New method to delete a product
  Future<void> _deleteProduct(Product product) async {
    // Show confirmation dialog
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text(
            'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    // Proceed with deletion
    try {
      setState(() {
        _isLoading = true;
      });

      await _apiService.deleteProduct(product.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );

      _loadProducts(); // Reload the list
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _viewProfitReport,
            tooltip: 'Profit Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_errorMessage',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Retry',
                    onPressed: _loadProducts,
                  ),
                ],
              ),
            )
          : _products.isEmpty
              ? const Center(child: Text('No products found'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (ctx, i) {
                    final product = _products[i];
                    final isLowStock = product.availableQuantity < 10;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Price: \$${product.sellingPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ${product.quantity}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'On Hold: ${product.quantityOnHold}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  'Available: ${product.availableQuantity}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isLowStock ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Update Price Button
                                ElevatedButton.icon(
                                  onPressed: () => _updatePrice(product),
                                  icon: const Icon(Icons.price_change),
                                  label: const Text('Update Price'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                
                                // Manage Batches Button
                                ElevatedButton.icon(
                                  onPressed: () => _manageBatches(product),
                                  icon: const Icon(Icons.inventory),
                                  label: const Text('Manage Batches'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                
                                // Delete Button
                                IconButton(
                                  onPressed: () => _deleteProduct(product),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  tooltip: 'Delete Product',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}