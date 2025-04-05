
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../utils/invoice_utils.dart';
import '../utils/sharing_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreateInvoiceScreen extends StatefulWidget {
  static const routeName = '/create-invoice';
  const CreateInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  // Controllers for product search and quantity
  final _productSearchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _invoiceService = InvoiceService();
  final _apiService = ApiService();

  String _invoiceNumber = '';
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedProduct;
  List<InvoiceItem> _invoiceItems = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Additional feature - discount
  final _discountController = TextEditingController(text: '0');
  double _discountAmount = 0;
  bool _isDiscountPercentage = false;

  @override
  void initState() {
    super.initState();
    _initInvoice();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _productSearchController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _initInvoice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;

      // Get next invoice number from the server
      _invoiceNumber = await _invoiceService.getNextInvoiceNumber(shopId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;

      final results = await _invoiceService.searchProducts(shopId, query);

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Just clear results on error
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProduct = product;
      _productSearchController.text = product['name'];
      _searchResults = [];
    });
  }

  void _addProductToInvoice() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quantity')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    // Check if quantity is available
    if (quantity > _selectedProduct!['quantity']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${_selectedProduct!['quantity']} items available in stock')),
      );
      return;
    }

    final item = InvoiceItem(
      productId: _selectedProduct!['_id'],
      productName: _selectedProduct!['name'],
      quantity: quantity,
      unitPrice: _selectedProduct!['selling_price'].toDouble(),
    );

    setState(() {
      _invoiceItems.add(item);
      _selectedProduct = null;
      _productSearchController.clear();
      _quantityController.clear();
    });
  }

  void _removeInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  // Calculate subtotal
  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate discount
  void _calculateDiscount() {
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (_isDiscountPercentage) {
      _discountAmount = _subtotal * (discountValue / 100);
    } else {
      _discountAmount = discountValue;
    }
    setState(() {});
  }

  // Calculate total with discount
  double get _totalWithDiscount {
    return _subtotal - _discountAmount;
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user!;

      final invoice = Invoice(
        invoiceNumber: _invoiceNumber,
        shopId: user.shopId,
        shopName: user.shopName ?? 'Unknown Shop',
        shopAddress: '', // This would need to be fetched from somewhere
        shopLicense: '', // This would need to be fetched from somewhere
        customerName: _customerNameController.text,
        customerAddress: _customerAddressController.text,
        date: DateTime.now(),
        items: _invoiceItems,
        status: 'pending',
        createdBy: user.email,
      );

      await _invoiceService.savePendingInvoice(invoice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully')),
      );

      _resetForm();
      _initInvoice(); // Get new invoice number
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user!;

      final invoice = Invoice(
        invoiceNumber: _invoiceNumber,
        shopId: user.shopId,
        shopName: user.shopName ?? 'Unknown Shop',
        shopAddress: '', // This would need to be fetched from somewhere
        shopLicense: '', // This would need to be fetched from somewhere
        customerName: _customerNameController.text,
        customerAddress: _customerAddressController.text,
        date: DateTime.now(),
        items: _invoiceItems,
        status: 'pending', // Save as pending first
        createdBy: user.email,
      );

      // First save the invoice as pending
      final saveResult = await _invoiceService.savePendingInvoice(invoice);
      final invoiceId = saveResult['invoice_id'];

      // Then generate the invoice (update inventory)
      try {
        await _invoiceService.generateInvoice(invoiceId);

        // Fetch the completed invoice data
        final completeInvoice = await _invoiceService.getInvoiceById(invoiceId);

        // Generate PDF
        final pdfFile = await InvoiceUtils.generateInvoicePdf(completeInvoice);

        // Show sharing options
        if (mounted) {
          SharingUtils.showSharingOptions(
              context,
              pdfFile,
              'Invoice ${completeInvoice.invoiceNumber}'
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice generated successfully')),
        );

        _resetForm();
        _initInvoice(); // Get new invoice number
      } catch (e) {
        // Check if the error is about an already completed invoice
        if (e.toString().contains('already completed') ||
            e.toString().contains('already processed')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice is already processed. Please check invoice history.')),
          );
          _resetForm();
          _initInvoice();
        } else {
          throw e; // Re-throw other errors
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _customerNameController.clear();
    _customerAddressController.clear();
    _productSearchController.clear();
    _quantityController.clear();
    _discountController.text = '0';
    setState(() {
      _invoiceItems = [];
      _selectedProduct = null;
      _searchResults = [];
      _discountAmount = 0;
      _isDiscountPercentage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.indigo,
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
                onPressed: _initInvoice,
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice header
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Invoice',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Invoice #: $_invoiceNumber',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Customer information
              const Text(
                'Customer Information',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Customer Name',
                controller: _customerNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Customer Address',
                controller: _customerAddressController,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Product selection
              const Text(
                'Add Products',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product search field
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Product Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _productSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search products',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.search),
                          ),
                          onChanged: _searchProduct,
                        ),
                        if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final product = _searchResults[index];
                                return ListTile(
                                  title: Text(product['name']),
                                  subtitle: Text(
                                      'Price: \$${product['selling_price'].toStringAsFixed(2)} - In Stock: ${product['quantity']}'
                                  ),
                                  onTap: () => _selectProduct(product),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quantity field
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quantity'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add button
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton(
                      onPressed: _addProductToInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Invoice items list
              if (_invoiceItems.isNotEmpty) ...[
                const Text(
                  'Invoice Items',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(1),
                      },
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      children: [
                        // Table header
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Product',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Unit Price',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // Table rows for each product
                        for (int i = 0; i < _invoiceItems.length; i++)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _invoiceItems[i].productName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _invoiceItems[i].quantity.toString(),
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '\$${_invoiceItems[i].unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '\$${_invoiceItems[i].totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () => _removeInvoiceItem(i),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // NEW FEATURE: Discount section
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: _isDiscountPercentage ? 'Discount %' : 'Discount Amount',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (_) => _calculateDiscount(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ToggleButtons(
                              isSelected: [!_isDiscountPercentage, _isDiscountPercentage],
                              onPressed: (index) {
                                setState(() {
                                  _isDiscountPercentage = index == 1;
                                  _calculateDiscount();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('\$'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('%'),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _calculateDiscount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                              ),
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Summary section
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '\$${_subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount ${_isDiscountPercentage ? "(${_discountController.text}%)" : ""}:',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                '-\$${_discountAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_totalWithDiscount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Save and Generate buttons - SIMPLIFIED!
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save as Pending'),
                      onPressed: _isProcessing ? null : _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt),
                      label: const Text('Generate Invoice'),
                      onPressed: _isProcessing ? null : _generateInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}