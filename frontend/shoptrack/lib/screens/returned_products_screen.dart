import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class ReturnedProductsScreen extends StatefulWidget {
  static const routeName = '/returned-products';
  
  const ReturnedProductsScreen({Key? key}) : super(key: key);

  @override
  State<ReturnedProductsScreen> createState() => _ReturnedProductsScreenState();
}

class _ReturnedProductsScreenState extends State<ReturnedProductsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = false;
  String? _error;
  
  // Return product form controllers
  final _formKey = GlobalKey<FormState>();
  final _invoiceIdController = TextEditingController();
  final _productIdController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  
  // Returned products list
  List<dynamic>? _returnedProducts;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReturnedProducts();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _invoiceIdController.dispose();
    _productIdController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReturnedProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;
      
      final response = await _apiService.getReturnedProducts(shopId);
      
      setState(() {
        _returnedProducts = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _processReturn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _apiService.returnProduct(
        invoiceId: _invoiceIdController.text.trim(),
        productId: _productIdController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        reason: _reasonController.text.trim(),
      );
      
      // Clear form
      _invoiceIdController.clear();
      _productIdController.clear();
      _quantityController.clear();
      _reasonController.clear();
      
      // Reload returned products
      await _loadReturnedProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Product returned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing return: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPremium = authProvider.isPremium;
    
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Returns'),
          backgroundColor: Colors.indigo,
        ),
        body: const Center(
          child: Text('Premium subscription required to access returns management.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Returned Products'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Returned Products'),
            Tab(text: 'Process New Return'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReturnedProductsTab(),
                    _buildProcessReturnTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadReturnedProducts,
        label: const Text('Refresh'),
        icon: const Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReturnedProducts,
            child: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  // Returned Products Tab
  Widget _buildReturnedProductsTab() {
    if (_returnedProducts == null || _returnedProducts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_return, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Returned Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When customers return products, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Process New Return',
              onPressed: () => _tabController.animateTo(1),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Returns',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _returnedProducts!.length,
            itemBuilder: (context, index) {
              final returnedProduct = _returnedProducts![index];
              return _buildReturnedProductItem(returnedProduct);
            },
          ),
        ],
      ),
    );
  }
  
  // Process Return Tab
  Widget _buildProcessReturnTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Process Product Return',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the details of the product being returned by the customer.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _invoiceIdController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice ID',
                    hintText: 'Enter the original invoice ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an invoice ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _productIdController,
                  decoration: const InputDecoration(
                    labelText: 'Product ID',
                    hintText: 'Enter the product ID being returned',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter the quantity being returned',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.exposure),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quantity';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Return Reason',
                    hintText: 'Why is the customer returning this product?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.comment),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a return reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Process Return',
                  onPressed: _processReturn,
                  color: Theme.of(context).colorScheme.primary,
                  width: double.infinity,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Return Policy Reminders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyItem('Verify the original invoice and product'),
                  _buildPolicyItem('Check the product condition before accepting'),
                  _buildPolicyItem('Ensure return is within the return period'),
                  _buildPolicyItem('Document the reason for return accurately'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReturnedProductItem(Map<String, dynamic> returnedProduct) {
    final productId = returnedProduct['product_id'];
    final invoiceId = returnedProduct['invoice_id'];
    final quantity = returnedProduct['quantity'];
    final reason = returnedProduct['return_reason'];
    final sellingPrice = returnedProduct['selling_price'];
    final returnedAt = _formatDate(returnedProduct['returned_at']);
    final branchId = returnedProduct['branch_id'] ?? 'Main Store';
    final processedBy = returnedProduct['processed_by'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_return, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Product Return: $productId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'QTY: $quantity',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildReturnDetailItem('Invoice', invoiceId),
            _buildReturnDetailItem('Return Date', returnedAt),
            _buildReturnDetailItem('Branch', branchId),
            _buildReturnDetailItem('Processed By', processedBy),
            _buildReturnDetailItem('Refund Value', '৳${(sellingPrice * quantity).toStringAsFixed(2)}'),
            _buildReturnDetailItem('Reason', reason, isLongText: true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReturnDetailItem(String label, String value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isLongText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '$label:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildPolicyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
} 