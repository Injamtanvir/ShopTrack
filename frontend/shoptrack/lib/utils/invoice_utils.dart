import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import '../models/invoice.dart';

class InvoiceUtils {
  // Generate a PDF from an Invoice object
  static Future<dynamic> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Define styles
    final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
    final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final subheaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final normalStyle = pw.TextStyle(fontSize: 12);
    final smallStyle = pw.TextStyle(fontSize: 10);
    final boldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    // Create the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with shop info and logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(invoice.shopName, style: titleStyle),
                  pw.Text('INVOICE', style: titleStyle),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Bill to section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Customer information (left)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO:', style: smallStyle),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.customerName, style: normalStyle),
                      pw.Text('+${invoice.customerPhone}', style: normalStyle),
                      pw.Text(invoice.customerAddress, style: normalStyle),
                    ],
                  ),
                  
                  // Invoice details (right)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice No: ${invoice.invoiceNumber}', style: normalStyle),
                      pw.Text(invoice.getFormattedDateTime(), style: normalStyle),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              
              // Invoice Items Table - modernized with clean lines
              pw.Table(
                border: pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),   // Item
                  1: const pw.FlexColumnWidth(1),   // Quantity
                  2: const pw.FlexColumnWidth(2),   // Unit Price
                  3: const pw.FlexColumnWidth(2),   // Total
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5))
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unit Price', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: boldStyle),
                      ),
                    ],
                  ),
                  // Table rows for each product
                  ...invoice.items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.productName, style: normalStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.quantity.toString(), style: normalStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tk ${item.unitPrice.toStringAsFixed(2)}', style: normalStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tk ${item.totalPrice.toStringAsFixed(2)}', style: normalStyle),
                      ),
                    ],
                  )).toList(),
                ],
              ),
              
              // Totals Section
              pw.SizedBox(height: 20),
              
              // Align to the right
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Subtotal row
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: normalStyle),
                            pw.Text('Tk ${invoice.subtotalAmount.toStringAsFixed(2)}', style: normalStyle),
                          ],
                        ),
                        
                        // If there's a discount, show it
                        if (invoice.discountAmount > 0) ...[
                          pw.SizedBox(height: 4),
                          // Discount row
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:', style: normalStyle),
                              pw.Text('-Tk ${invoice.discountAmount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.red,
                                  )
                              ),
                            ],
                          ),
                        ],
                        
                        // Divider for total
                        pw.Divider(),
                        
                        // Total Amount
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total:', style: boldStyle),
                            pw.Text('Tk ${invoice.totalAmount.toStringAsFixed(2)}', style: boldStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 40),
              
              // Thank you text
              pw.Text('Thank you!', style: headerStyle),
              
              pw.SizedBox(height: 30),
              
              // Shop Information section (was Payment Information)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Shop Information (left)
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SHOP INFORMATION', style: boldStyle),
                        pw.SizedBox(height: 8),
                        pw.Text('Shop Name: ${invoice.shopName}', style: normalStyle),
                        pw.Text('Shop Address: ${invoice.shopAddress}', style: normalStyle),
                        pw.Text('Shop ID: ${invoice.shopId}', style: normalStyle),
                        // Add shop license if available
                        if (invoice.shopLicense.isNotEmpty)
                          pw.Text('Shop License: ${invoice.shopLicense}', style: normalStyle),
                        // Add VAT license if available
                        if (invoice.shopVatLicense.isNotEmpty)
                          pw.Text('VAT License: ${invoice.shopVatLicense}', style: normalStyle),
                        pw.Text('Paid Time: ${DateTime.now().add(Duration(days: 30)).day} ${DateFormat('MMM yyyy').format(DateTime.now())}', style: normalStyle),
                      ],
                    ),
                  ),
                  
                  // Generated by information (right)
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Add user's name - extract name portion from email
                        pw.Text(
                          _extractNameFromEmail(invoice.createdBy), 
                          style: boldStyle
                        ),
                        pw.Text(invoice.createdBy, style: normalStyle),
                        pw.SizedBox(height: 4),
                        pw.Text('${invoice.shopName}', style: normalStyle),
                        pw.Text('${invoice.shopAddress}', style: smallStyle),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Add space before footer
              pw.SizedBox(height: 40),
              
              // Footer text centered at bottom
              pw.Center(
                child: pw.Text(
                  'This Invoice is Generated by ShopTrack',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF based on platform
    try {
      if (kIsWeb) {
        // For web, return the bytes for downloading
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final filename = 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Return as a map with data for web handling
        return {'bytes': bytes, 'url': url, 'filename': filename};
      } else {
        // For mobile platforms
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      // Handle path_provider errors
      if (e.toString().contains('MissingPluginException')) {
        // Fallback for platforms without path_provider support
        final bytes = await pdf.save();
        return bytes;
      }
      rethrow;
    }
  }

  // Format currency values
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Tk ', decimalDigits: 2);
    return formatter.format(amount);
  }

  // Generate a unique invoice number (6 digits)
  static String generateInvoiceNumber(int lastNumber) {
    // Increment the last number and ensure it's 6 digits
    int newNumber = lastNumber + 1;
    return newNumber.toString().padLeft(6, '0');
  }
  
  // Extract a name from an email address
  static String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'Unknown';
    
    // Split by @ and take the first part
    final namePart = email.split('@').first;
    
    // Replace dots and underscores with spaces
    final nameWithSpaces = namePart.replaceAll('.', ' ').replaceAll('_', ' ');
    
    // Capitalize each word
    final words = nameWithSpaces.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : '');
    });
    
    return capitalizedWords.join(' ');
  }
}