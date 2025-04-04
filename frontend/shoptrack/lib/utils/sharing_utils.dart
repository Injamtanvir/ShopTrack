// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:intl/intl.dart';
//
// class SharingUtils {
//   /// Generates a PDF file for price list
//   static Future<File> generatePriceListPdf({
//     required String shopName,
//     required String shopAddress,
//     required String shopId,
//     required List<dynamic> products,
//   }) async {
//     final pdf = pw.Document();
//
//     // Define styles
//     final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
//     final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
//     final normalStyle = pw.TextStyle(fontSize: 12);
//     final boldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
//
//     final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header with shop info
//               pw.Center(child: pw.Text('PRICE LIST', style: titleStyle)),
//               pw.SizedBox(height: 12),
//               pw.Center(child: pw.Text(shopName, style: headerStyle)),
//               pw.Center(child: pw.Text(shopAddress, style: normalStyle)),
//               pw.Center(child: pw.Text('Shop ID: $shopId', style: normalStyle)),
//               pw.Center(child: pw.Text('Generated on: $date', style: normalStyle)),
//               pw.SizedBox(height: 20),
//
//               // Products table
//               pw.Table(
//                 border: pw.TableBorder.all(color: PdfColors.black),
//                 columnWidths: {
//                   0: const pw.FlexColumnWidth(4),
//                   1: const pw.FlexColumnWidth(2),
//                 },
//                 children: [
//                   // Table header
//                   pw.TableRow(
//                     decoration: const pw.BoxDecoration(color: PdfColors.grey300),
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('Product Name', style: boldStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text('Price (USD)', style: boldStyle),
//                       ),
//                     ],
//                   ),
//
//                   // Table rows for each product
//                   ...products.map((product) => pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(product['name'], style: normalStyle),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(8),
//                         child: pw.Text(
//                           '\$${product['selling_price'].toStringAsFixed(2)}',
//                           style: normalStyle,
//                         ),
//                       ),
//                     ],
//                   )).toList(),
//                 ],
//               ),
//
//               // Footer
//               pw.SizedBox(height: 40),
//               pw.Center(
//                 child: pw.Text(
//                   'Thank you for your business!',
//                   style: pw.TextStyle(
//                     fontStyle: pw.FontStyle.italic,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 8),
//               pw.Center(
//                 child: pw.Text(
//                   'Contact us for more information.',
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
//     final file = File('${output.path}/price_list_${shopName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
//     await file.writeAsBytes(await pdf.save());
//
//     return file;
//   }
//
//   /// Shows a bottom sheet with options for sharing a file
//   static void showSharingOptions(BuildContext context, File file, String title) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _buildShareOptions(context, file, title),
//     );
//   }
//
//   /// Builds the bottom sheet with sharing options
//   static Widget _buildShareOptions(BuildContext context, File file, String title) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Share $title',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//
//           // Email option
//           ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.red.shade100,
//               child: Icon(Icons.email, color: Colors.red.shade700),
//             ),
//             title: const Text('Email'),
//             subtitle: const Text('Send via email'),
//             onTap: () {
//               Navigator.pop(context);
//               shareViaEmail(context, file, title);
//             },
//           ),
//
//           // Print option
//           ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.blue.shade100,
//               child: Icon(Icons.print, color: Colors.blue.shade700),
//             ),
//             title: const Text('Print'),
//             subtitle: const Text('Print the document'),
//             onTap: () {
//               Navigator.pop(context);
//               showPrintDialog(context, file);
//             },
//           ),
//
//           // Other sharing options
//           ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.green.shade100,
//               child: Icon(Icons.share, color: Colors.green.shade700),
//             ),
//             title: const Text('Other Apps'),
//             subtitle: const Text('Share via other applications'),
//             onTap: () {
//               Navigator.pop(context);
//               shareFile(context, file, title);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Share via email
//   static Future<void> shareViaEmail(BuildContext context, File file, String subject) async {
//     try {
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         subject: subject,
//         text: 'Please find attached the $subject.',
//       );
//     } catch (e) {
//       _showErrorSnackbar(context, 'Error sharing via email: ${e.toString()}');
//     }
//   }
//
//   /// Show print dialog
//   static void showPrintDialog(BuildContext context, File file) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Print Document'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Searching for nearby printers...'),
//             SizedBox(height: 24),
//             Text(
//               'In a production app, this would detect nearby Bluetooth printers and send the document to the selected printer.',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Share file using system share dialog
//   static Future<void> shareFile(BuildContext context, File file, String subject) async {
//     try {
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         subject: subject,
//       );
//     } catch (e) {
//       _showErrorSnackbar(context, 'Error sharing file: ${e.toString()}');
//     }
//   }
//
//   /// Show error snackbar
//   static void _showErrorSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
// }




import 'package:flutter/foundation.dart' show kIsWeb;
// Use conditional import for IO or web
import 'dart:io' if (dart.library.html) '../utils/web_stub.dart';
// Add this explicit import to fix the WebUtils reference
import '../utils/web_stub.dart' if (dart.library.io) '../utils/io_stub.dart' show WebUtils;

import 'package:flutter/foundation.dart' show kIsWeb;
// Use conditional import
import 'dart:io' if (dart.library.html) 'package:shoptrack/utils/web_stub.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'invoice_utils.dart'; // For WebPdfResult

class SharingUtils {
  /// Generates a PDF file for price list
  static Future<dynamic> generatePriceListPdf({
    required String shopName,
    required String shopAddress,
    required String shopId,
    required List<dynamic> products,
  }) async {
    final pdf = pw.Document();

    // Define styles
    final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
    final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final normalStyle = pw.TextStyle(fontSize: 12);
    final boldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    final date = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with shop info
              pw.Center(child: pw.Text('PRICE LIST', style: titleStyle)),
              pw.SizedBox(height: 12),
              pw.Center(child: pw.Text(shopName, style: headerStyle)),
              pw.Center(child: pw.Text(shopAddress, style: normalStyle)),
              pw.Center(child: pw.Text('Shop ID: $shopId', style: normalStyle)),
              pw.Center(child: pw.Text('Generated on: $date', style: normalStyle)),
              pw.SizedBox(height: 20),
              // Products table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Product Name', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price (USD)', style: boldStyle),
                      ),
                    ],
                  ),
                  // Table rows for each product
                  ...products.map((product) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product['name'], style: normalStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '\$${product['selling_price'].toStringAsFixed(2)}',
                          style: normalStyle,
                        ),
                      ),
                    ],
                  )).toList(),
                ],
              ),
              // Footer
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Contact us for more information.',
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

      // Use the WebUtils helper for web-specific operations
      final url = WebUtils.createPdfBlobUrl(bytes);

      return WebPdfResult(
        bytes: bytes,
        url: url,
        filename: 'price_list_${shopName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } else {
      // For mobile platforms
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/price_list_${shopName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    }
  }

  /// Shows a bottom sheet with options for sharing a file
  static void showSharingOptions(BuildContext context, dynamic fileOrWebResult, String title) {
    if (kIsWeb) {
      if (fileOrWebResult is WebPdfResult) {
        // For web, directly open the PDF in a new tab
        WebUtils.openUrl(fileOrWebResult.url);
      }
    } else {
      // Original mobile sharing options
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildShareOptions(context, fileOrWebResult, title),
      );
    }
  }

  /// Builds the bottom sheet with sharing options
  static Widget _buildShareOptions(BuildContext context, File file, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share $title',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Email option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Icon(Icons.email, color: Colors.red.shade700),
            ),
            title: const Text('Email'),
            subtitle: const Text('Send via email'),
            onTap: () {
              Navigator.pop(context);
              _shareViaEmail(context, file, title);
            },
          ),
          // Print option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.print, color: Colors.blue.shade700),
            ),
            title: const Text('Print'),
            subtitle: const Text('Print the document'),
            onTap: () {
              Navigator.pop(context);
              _showPrintDialog(context, file);
            },
          ),
          // Other sharing options
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.share, color: Colors.green.shade700),
            ),
            title: const Text('Other Apps'),
            subtitle: const Text('Share via other applications'),
            onTap: () {
              Navigator.pop(context);
              _shareFile(context, file, title);
            },
          ),
        ],
      ),
    );
  }

  /// Share via email
  static Future<void> _shareViaEmail(BuildContext context, File file, String subject) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: 'Please find attached the $subject.',
      );
    } catch (e) {
      _showErrorSnackbar(context, 'Error sharing via email: ${e.toString()}');
    }
  }

  /// Show print dialog
  static void _showPrintDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Document'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for nearby printers...'),
            SizedBox(height: 24),
            Text(
              'In a production app, this would detect nearby Bluetooth printers and send the document to the selected printer.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Share file using system share dialog
  static Future<void> _shareFile(BuildContext context, File file, String subject) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
    } catch (e) {
      _showErrorSnackbar(context, 'Error sharing file: ${e.toString()}');
    }
  }

  /// Show error snackbar
  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}