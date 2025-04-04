// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import '../models/invoice.dart';
//
// class InvoiceUtils {
//   // Generate a PDF from an Invoice object
//   static Future<File> generateInvoicePdf(Invoice invoice) async {
//     final pdf = pw.Document();
//
//     // Define styles
//     final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
//     final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
//     final subheaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
//     final normalStyle = pw.TextStyle(fontSize: 12);
//     final boldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
//
//     // Create colorful ShopTrack logo
//     final logo = pw.Row(
//       children: [
//         pw.Text('Shop', style: pw.TextStyle(color: PdfColors.blue, fontSize: 20, fontWeight: pw.FontWeight.bold)),
//         pw.Text('Track', style: pw.TextStyle(color: PdfColors.red, fontSize: 20, fontWeight: pw.FontWeight.bold)),
//       ],
//     );
//
//     // Create the PDF
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header with shop info and logo
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   logo,
//                   pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.end,
//                     children: [
//                       pw.Text('INVOICE', style: titleStyle),
//                       pw.Text('# ${invoice.invoiceNumber}', style: subheaderStyle),
//                       pw.SizedBox(height: 4),
//                       pw.Text('Date: ${invoice.getFormattedDate()}', style: normalStyle),
//                     ],
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 20),
//
//               // Shop Information
//               pw.Row(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Expanded(
//                     child: pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text('From:', style: boldStyle),
//                         pw.Text(invoice.shopName, style: normalStyle),
//                         pw.Text(invoice.shopAddress, style: normalStyle),
//                         pw.Text('License: ${invoice.shopLicense}', style: normalStyle),
//                         pw.Text('Shop ID: ${invoice.shopId}', style: normalStyle),
//                       ],
//                     ),
//                   ),
//                   pw.Expanded(
//                     child: pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text('To:', style: boldStyle),
//                         pw.Text(invoice.customerName, style: normalStyle),
//                         pw.Text(invoice.customerAddress, style: normalStyle),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 30),
//
//               // Invoice Items Table
//               pw.Table(
//                 border: pw.TableBorder.all(color: PdfColors.black),
//                 columnWidths: {
//                   0: const pw.FlexColumnWidth(4),
//                   1: const pw.FlexColumnWidth(1),
//                   2: const pw.FlexColumnWidth(2),
//                   3: const pw.FlexColumnWidth(2),
//                 },
//                 children: [
//                   // Table header
//                   pw.TableRow(
//                     decoration: const pw.BoxDecoration(color: PdfColors.grey300),
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('Product', style: boldStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('Qty', style: boldStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('Unit Price', style: boldStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('Total', style: boldStyle),
//                       ),
//                     ],
//                   ),
//
//                   // Table rows for each product
//                   ...invoice.items.map((item) => pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(item.productName, style: normalStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(item.quantity.toString(), style: normalStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('\$${item.unitPrice.toStringAsFixed(2)}', style: normalStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('\$${item.totalPrice.toStringAsFixed(2)}', style: normalStyle),
//                       ),
//                     ],
//                   )).toList(),
//                 ],
//               ),
//
//               // Total Amount
//               pw.SizedBox(height: 20),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.end,
//                 children: [
//                   pw.Container(
//                     padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     decoration: pw.BoxDecoration(
//                       color: PdfColors.grey200,
//                       border: pw.Border.all(color: PdfColors.black),
//                     ),
//                     child: pw.Row(
//                       children: [
//                         pw.Text('Total Amount: ', style: boldStyle),
//                         pw.Text('\$${invoice.totalAmount.toStringAsFixed(2)}', style: boldStyle),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//
//               // Footer
//               pw.SizedBox(height: 40),
//               pw.Divider(),
//               pw.SizedBox(height: 10),
//               pw.Center(
//                 child: pw.Text(
//                   'Thank you for your business!',
//                   style: pw.TextStyle(
//                     fontStyle: pw.FontStyle.italic,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 4),
//               pw.Center(
//                 child: pw.Text(
//                   'Generated using ShopTrack',
//                   style: normalStyle,
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//
//     // Save the PDF
//     final output = await getTemporaryDirectory();
//     final file = File('${output.path}/invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf');
//     await file.writeAsBytes(await pdf.save());
//
//     return file;
//   }
//
//   // Format currency values
//   static String formatCurrency(double amount) {
//     final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
//     return formatter.format(amount);
//   }
//
//   // Generate a unique invoice number (6 digits)
//   static String generateInvoiceNumber(int lastNumber) {
//     // Increment the last number and ensure it's 6 digits
//     int newNumber = lastNumber + 1;
//     return newNumber.toString().padLeft(6, '0');
//   }
// }




import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // Used conditionally with platform checks

import '../models/invoice.dart';

// Create a class for web PDF result
class WebPdfResult {
  final List<int> bytes;
  final String filename;

  WebPdfResult({required this.bytes, required this.filename});
}

class InvoiceUtils {
  // Generate a PDF from an Invoice object
  static Future<dynamic> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Define styles
    final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
    final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final subheaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final normalStyle = pw.TextStyle(fontSize: 12);
    final boldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    // Create colorful ShopTrack logo
    final logo = pw.Row(
      children: [
        pw.Text('Shop', style: pw.TextStyle(color: PdfColors.blue, fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Track', style: pw.TextStyle(color: PdfColors.red, fontSize: 20, fontWeight: pw.FontWeight.bold)),
      ],
    );

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
                  logo,
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: titleStyle),
                      pw.Text('# ${invoice.invoiceNumber}', style: subheaderStyle),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: ${invoice.getFormattedDate()}', style: normalStyle),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Shop Information
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('From:', style: boldStyle),
                        pw.Text(invoice.shopName, style: normalStyle),
                        pw.Text(invoice.shopAddress, style: normalStyle),
                        pw.Text('License: ${invoice.shopLicense}', style: normalStyle),
                        pw.Text('Shop ID: ${invoice.shopId}', style: normalStyle),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('To:', style: boldStyle),
                        pw.Text(invoice.customerName, style: normalStyle),
                        pw.Text(invoice.customerAddress, style: normalStyle),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              // Invoice Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Product', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty', style: boldStyle),
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
                        child: pw.Text('\$${item.unitPrice.toStringAsFixed(2)}', style: normalStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('\$${item.totalPrice.toStringAsFixed(2)}', style: normalStyle),
                      ),
                    ],
                  )).toList(),
                ],
              ),
              // Total Amount
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text('Total Amount: ', style: boldStyle),
                        pw.Text('\$${invoice.totalAmount.toStringAsFixed(2)}', style: boldStyle),
                      ],
                    ),
                  ),
                ],
              ),
              // Footer
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Generated using ShopTrack',
                  style: normalStyle,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF differently based on platform
    if (kIsWeb) {
      // For web platform
      final bytes = await pdf.save();

      // Just return the bytes for web
      return WebPdfResult(
        bytes: bytes,
        filename: 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } else {
      // For mobile platforms
      try {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      } catch (e) {
        print('Error creating PDF file: $e');
        // Return bytes as fallback
        final bytes = await pdf.save();
        return WebPdfResult(
          bytes: bytes,
          filename: 'invoice_${invoice.invoiceNumber}.pdf',
        );
      }
    }
  }

  // Format currency values
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  // Generate a unique invoice number (6 digits)
  static String generateInvoiceNumber(int lastNumber) {
    // Increment the last number and ensure it's 6 digits
    int newNumber = lastNumber + 1;
    return newNumber.toString().padLeft(6, '0');
  }
}