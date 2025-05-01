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
import '../providers/user_provider.dart';

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
    ).then((result) {
      // Check if we need to refresh products
      if (result != null && result is Map && result['refreshNeeded'] == true) {
        _loadProducts(); // Reload products when returning with refresh flag
      }
    });
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

  // Navigate to batch management screen
  void _navigateToBatchManagement(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchManagementScreen(product: product),
      ),
    ).then((result) {
      // Check if we need to refresh the product list
      if (result != null && result is Map && result['refreshNeeded'] == true) {
        _loadProducts();
      }
    });
  }

  // Show dialog to update product price
  Future<void> _showUpdatePriceDialog(BuildContext context, Product product) async {
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
                    
                    return _buildProductCard(context, product);
                  },
                ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                Text('Total: ${product.quantity}'),
                Text(
                  'On Hold: ${product.quantityOnHold}',
                  style: TextStyle(
                    color: product.quantityOnHold > 0 ? Colors.orange : Colors.black54,
                  ),
                ),
                Text(
                  'Available: ${product.availableQuantity}',
                  style: TextStyle(
                    color: product.availableQuantity <= 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
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
                  onPressed: () {
                    _showUpdatePriceDialog(context, product);
                  },
                  icon: const Icon(Icons.monetization_on),
                  label: const Text('Update Price'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                  ),
                ),
                
                // Manage Batches Button
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToBatchManagement(context, product);
                  },
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Manage Batches'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                  ),
                ),
                
                // Delete Product Button
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context, product),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Product',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context, Product product) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    // Check if user has permission (manager or owner)
    if (user?.role != 'manager' && user?.role != 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only managers and owners can delete products')),
      );
      return;
    }
    
    // Controller for the confirmation text field
    final TextEditingController confirmController = TextEditingController();
    // Track if the confirmation text is valid
    bool isConfirmationValid = false;
    
    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Delete ${product.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: This will permanently delete this product and ALL its related data:\n'
                '• All batch history will be deleted\n'
                '• All sales records associated with this product\n'
                '• All price history data\n\n'
                'This action CANNOT be undone.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              const Text(
                'To confirm deletion, type "Delete" in the field below:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type "Delete" to confirm',
                ),
                onChanged: (value) {
                  setState(() {
                    isConfirmationValid = value == 'Delete';
                  });
                },
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isConfirmationValid 
                ? () async {
                    Navigator.pop(dialogContext);
                    await _deleteProduct(product);
                  }
                : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isConfirmationValid ? Colors.red : Colors.grey,
                disabledForegroundColor: Colors.grey.shade300,
              ),
              child: const Text('Delete Product'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Delete product from backend
  Future<void> _deleteProduct(Product product) async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    // Show an ongoing snackbar that can be dismissed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text('Deleting ${product.name}...'),
          ],
        ),
        duration: const Duration(seconds: 30), // Long duration
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    
    try {
      // Attempt to delete the product
      final success = await _productService.deleteProduct(product.id);
      
      // Hide the loading indicator
      setState(() {
        _isLoading = false;
        if (success) {
          // Remove the product from the local list if successful
          _products.removeWhere((p) => p.id == product.id);
        }
      });
      
      // Hide any existing snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (mounted) {
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} has been deleted'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // This branch shouldn't be reached since deleteProduct throws on failure,
          // but just in case the function behavior changes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete product for unknown reason'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Hide the loading indicator
      setState(() {
        _isLoading = false;
      });
      
      // Hide any existing snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (mounted) {
        // Format the error message - remove Exception: prefix if present
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _deleteProduct(product);
              },
            ),
          ),
        );
      }
    }
  }
}