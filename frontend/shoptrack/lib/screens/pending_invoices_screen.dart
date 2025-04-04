import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_service.dart';
import '../utils/invoice_utils.dart';
import '../utils/sharing_utils.dart';
import '../widgets/custom_button.dart';

class PendingInvoicesScreen extends StatefulWidget {
  static const routeName = '/pending-invoices';

  const PendingInvoicesScreen({Key? key}) : super(key: key);

  @override
  State<PendingInvoicesScreen> createState() => _PendingInvoicesScreenState();
}

class _PendingInvoicesScreenState extends State<PendingInvoicesScreen> {
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

  // Future<void> _generateInvoice(Invoice invoice) async {
  //   setState(() {
  //     _isProcessing = true;
  //   });
  //
  //   try {
  //     // Generate the invoice (update product quantities)
  //     await _invoiceService.generateInvoice(invoice.id!);
  //
  //     // Get the complete invoice data
  //     final completeInvoice = await _invoiceService.getInvoiceById(invoice.id!);
  //
  //     // Generate PDF
  //     final pdfFile = await InvoiceUtils.generateInvoicePdf(completeInvoice);
  //
  //     // Show sharing options
  //     if (mounted) {
  //       SharingUtils.showSharingOptions(
  //           context,
  //           pdfFile,
  //           'Invoice ${completeInvoice.invoiceNumber}'
  //       );
  //     }
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Invoice generated successfully')),
  //     );
  //
  //     _loadPendingInvoices(); // Refresh the list
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isProcessing = false;
  //     });
  //   }
  // }

  // In lib/screens/pending_invoices_screen.dart
  // Update the _generateInvoice method:

  Future<void> _generateInvoice(Invoice invoice) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('Generating invoice with ID: ${invoice.id}');

      // Generate the invoice (update product quantities)
      await _invoiceService.generateInvoice(invoice.id!);
      print('Invoice generation completed successfully');

      // Get the complete invoice data
      final completeInvoice = await _invoiceService.getInvoiceById(invoice.id!);
      print('Retrieved complete invoice data');

      // Generate PDF
      final pdfFile = await InvoiceUtils.generateInvoicePdf(completeInvoice);
      print('PDF generation completed');

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

      _loadPendingInvoices(); // Refresh the list
    } catch (e) {
      print('Error in _generateInvoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Invoices'),
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
            ),
          );
        },
      ),
    );
  }
}