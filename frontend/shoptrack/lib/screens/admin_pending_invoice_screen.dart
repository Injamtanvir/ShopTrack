import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_service.dart';
import '../utils/invoice_utils.dart';
import '../utils/sharing_utils.dart';
import '../widgets/custom_button.dart';

class AdminPendingInvoicesScreen extends StatefulWidget {
  static const routeName = '/admin-pending-invoices';
  const AdminPendingInvoicesScreen({Key? key}) : super(key: key);

  @override
  State<AdminPendingInvoicesScreen> createState() => _AdminPendingInvoicesScreenState();
}

class _AdminPendingInvoicesScreenState extends State<AdminPendingInvoicesScreen> {
  final _invoiceService = InvoiceService();
  List<Invoice> _pendingInvoices = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingInvoices();
  }

  Future<void> _loadPendingInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;

      final invoices = await _invoiceService.getPendingInvoices(shopId);

      setState(() {
        _pendingInvoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInvoice(Invoice invoice) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate the invoice (update product quantities)
      await _invoiceService.generateInvoice(invoice.id!);

      // Get the complete invoice data
      final completeInvoice = await _invoiceService.getInvoiceById(invoice.id!);

      // Generate PDF
      final pdfFile = await InvoiceUtils.generateInvoicePdf(completeInvoice);

      // Show sharing options
      if (mounted) {
        SharingUtils.showSharingOptions(
          context,
          pdfFile,
          'Invoice ${completeInvoice.invoiceNumber}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice generated successfully')),
      );

      _loadPendingInvoices(); // Refresh the list
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

  // Method to delete pending invoice
  Future<void> _deleteInvoice(String invoiceId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _invoiceService.deletePendingInvoice(invoiceId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted successfully')),
      );

      _loadPendingInvoices(); // Refresh the list
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

  // Confirmation dialog for deletion
  Future<void> _confirmDeleteInvoice(Invoice invoice) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
            'Are you sure you want to delete Invoice #${invoice.invoiceNumber}?\n\nThis action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteInvoice(invoice.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // View invoice details in a popup
  void _viewInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.invoiceNumber} Details'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Text(
                  'Customer: ${invoice.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Address: ${invoice.customerAddress}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(invoice.date)}'),
                const SizedBox(height: 16),

                // Products table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Products list
                ...invoice.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(item.productName),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${item.quantity}'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('\$${item.unitPrice.toStringAsFixed(2)}'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                )).toList(),

                const Divider(thickness: 1),

                // Total
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '\$${invoice.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Created by info (admin-specific)
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'Created by: ${invoice.createdBy}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                // Note
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'Note: This is a preview only. Generate the invoice to complete the transaction.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateInvoice(invoice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            child: const Text('Generate Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Pending Invoices'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingInvoices,
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
                onPressed: _loadPendingInvoices,
              ),
            ],
          ),
        ),
      )
          : _pendingInvoices.isEmpty
          ? const Center(
        child: Text('No pending invoices found'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingInvoices.length,
        itemBuilder: (context, index) {
          final invoice = _pendingInvoices[index];
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice #${invoice.invoiceNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(invoice.date),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer: ${invoice.customerName}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Items: ${invoice.items.length}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created by: ${invoice.createdBy}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: \$${invoice.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Row(
                        children: [
                          // Delete button - Admin specific feature
                          ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _confirmDeleteInvoice(invoice),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Delete'),
                          ),
                          const SizedBox(width: 8),
                          // View button
                          ElevatedButton(
                            onPressed: () => _viewInvoiceDetails(invoice),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('View'),
                          ),
                          const SizedBox(width: 8),
                          // Generate button
                          ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _generateInvoice(invoice),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                            ),
                            child: const Text('Generate'),
                          ),
                        ],
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