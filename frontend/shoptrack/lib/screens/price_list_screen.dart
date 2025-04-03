// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import '../services/api_service.dart';
// import '../widgets/custom_button.dart';
//
// class PriceListScreen extends StatefulWidget {
//   static const routeName = '/price-list';
//   final bool showShareOptions;
//
//   const PriceListScreen({Key? key, this.showShareOptions = false}) : super(key: key);
//
//   @override
//   State<PriceListScreen> createState() => _PriceListScreenState();
// }
//
// class _PriceListScreenState extends State<PriceListScreen> {
//   final ApiService _apiService = ApiService();
//   Map<String, dynamic>? _priceListData;
//   bool _isLoading = true;
//   bool _isProcessing = false;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPriceList();
//   }
//
//   // Non-async method for button callbacks
//   void _loadPriceList() {
//     _handleLoadPriceList();
//   }
//
//   // Async implementation
//   Future<void> _handleLoadPriceList() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final data = await _apiService.getProductPriceList();
//       if (mounted) {
//         setState(() {
//           _priceListData = data;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   // Non-async method for button callbacks
//   void _sharePriceList() {
//     _handleSharePriceList();
//   }
//
//   // Async implementation
//   Future<void> _handleSharePriceList() async {
//     if (_priceListData == null) return;
//
//     setState(() {
//       _isProcessing = true;
//     });
//
//     try {
//       // Generate the PDF
//       final pdfFile = await _generatePdf();
//
//       if (widget.showShareOptions) {
//         // Show the bottom sheet with options
//         if (mounted) {
//           showModalBottomSheet(
//             context: context,
//             shape: const RoundedRectangleBorder(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             builder: (context) => _buildShareOptions(pdfFile),
//           );
//         }
//       } else {
//         // Just share the PDF directly
//         await _sharePdf(pdfFile);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error creating PDF: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }
//
//   Future<File> _generatePdf() async {
//     final pdf = pw.Document();
//
//     // Define styles - no const for pw.TextStyle
//     final titleStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
//     final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
//     final normalStyle = pw.TextStyle(fontSize: 12);
//     final boldStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
//
//     // Get data
//     final shopName = _priceListData!['shop_name'];
//     final shopAddress = _priceListData!['shop_address'];
//     final shopId = _priceListData!['shop_id'];
//     final products = _priceListData!['products'] as List;
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
//   // Build the bottom sheet with sharing options
//   Widget _buildShareOptions(File pdfFile) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'Share Price List',
//             style: TextStyle(
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
//               _shareViaEmail(pdfFile);
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
//             subtitle: const Text('Print the price list'),
//             onTap: () {
//               Navigator.pop(context);
//               _printPdf(pdfFile);
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
//               _sharePdf(pdfFile);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Share via email
//   void _shareViaEmail(File pdfFile) {
//     _handleShareViaEmail(pdfFile);
//   }
//
//   Future<void> _handleShareViaEmail(File pdfFile) async {
//     try {
//       // This would typically launch the email app with the PDF attached
//       // For now, we'll just use the standard share dialog
//       await Share.shareXFiles(
//         [XFile(pdfFile.path)],
//         subject: 'Price List - ${_priceListData!['shop_name']}',
//         text: 'Please find attached the price list for ${_priceListData!['shop_name']}.',
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error sharing via email: ${e.toString()}')),
//         );
//       }
//     }
//   }
//
//   // Print PDF
//   void _printPdf(File pdfFile) {
//     // In a real app, this would connect to a printer
//     // For now, we'll show a simulation dialog
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Print Price List'),
//           content: const Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Searching for nearby printers...'),
//               SizedBox(height: 24),
//               Text(
//                 'In a production app, this would detect nearby Bluetooth printers and send the document to the selected printer.',
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   // Share PDF
//   // CHANGED from void -> Future<void> so we can await it in _handleSharePriceList.
//   Future<void> _sharePdf(File pdfFile) {
//     return _handleSharePdf(pdfFile);
//   }
//
//   Future<void> _handleSharePdf(File pdfFile) async {
//     try {
//       await Share.shareXFiles(
//         [XFile(pdfFile.path)],
//         subject: 'Price List - ${_priceListData!['shop_name']}',
//         text: 'Price List for ${_priceListData!['shop_name']}',
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error sharing PDF: ${e.toString()}')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Price List'),
//         backgroundColor: Colors.indigo,
//         actions: [
//           if (!_isLoading && _priceListData != null)
//             IconButton(
//               icon: _isProcessing
//                   ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//                   : const Icon(Icons.share),
//               onPressed: _isProcessing ? null : _sharePriceList,
//               tooltip: 'Share',
//             ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadPriceList,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Error: $_errorMessage',
//                 style: const TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               CustomButton(
//                 text: 'Retry',
//                 onPressed: _loadPriceList,
//               ),
//             ],
//           ),
//         ),
//       )
//           : _priceListData == null ||
//           (_priceListData!['products'] as List).isEmpty
//           ? const Center(
//         child: Text('No products found. Add some products!'),
//       )
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Shop info card
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _priceListData!['shop_name'],
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _priceListData!['shop_address'],
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             // Products price list heading
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Products Price List',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // Share button
//                 if (widget.showShareOptions)
//                   ElevatedButton.icon(
//                     onPressed: _isProcessing ? null : _sharePriceList,
//                     icon: const Icon(Icons.share, size: 18),
//                     label: const Text('Share'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.indigo,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//
//             // Products Table
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Table(
//                   columnWidths: const {
//                     0: FlexColumnWidth(3),
//                     1: FlexColumnWidth(2),
//                   },
//                   border: TableBorder.all(
//                     color: Colors.grey.shade300,
//                     width: 1,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   children: [
//                     // Table header
//                     TableRow(
//                       decoration: BoxDecoration(
//                         color: Colors.indigo.shade50,
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(8),
//                           topRight: Radius.circular(8),
//                         ),
//                       ),
//                       children: const [
//                         Padding(
//                           padding: EdgeInsets.all(12),
//                           child: Text(
//                             'Product',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(12),
//                           child: Text(
//                             'Price',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                             textAlign: TextAlign.right,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     // Table rows for each product
//                     for (var product in _priceListData!['products'])
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               product['name'],
//                               style: const TextStyle(fontSize: 15),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               '\$${product['selling_price'].toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.green,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               textAlign: TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Footer
//             const SizedBox(height: 32),
//             Center(
//               child: Text(
//                 'Total Products: ${(_priceListData!['products'] as List).length}',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey.shade700,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             if (widget.showShareOptions)
//               Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: CustomButton(
//                     text: 'Generate PDF & Share',
//                     onPressed: _isProcessing ? null :    _sharePriceList,
//                     isLoading: _isProcessing,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }
// }






//
//
//
//
//
//
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import '../services/api_service.dart';
// import '../widgets/custom_button.dart';
// import '../widgets/share_helper.dart';
// import '../widgets/share_options_bottom_sheet.dart';
//
// class PriceListScreen extends StatefulWidget {
//   static const routeName = '/price-list';
//   final bool showShareOptions;
//
//   const PriceListScreen({Key? key, this.showShareOptions = false}) : super(key: key);
//
//   @override
//   State<PriceListScreen> createState() => _PriceListScreenState();
// }
//
// class _PriceListScreenState extends State<PriceListScreen> {
//   final ApiService _apiService = ApiService();
//   Map<String, dynamic>? _priceListData;
//   bool _isLoading = true;
//   bool _isProcessing = false;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPriceList();
//   }
//
//   void _loadPriceList() {
//     _handleLoadPriceList();
//   }
//
//   Future<void> _handleLoadPriceList() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final data = await _apiService.getProductPriceList();
//       if (mounted) {
//         setState(() {
//           _priceListData = data;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _sharePriceList() {
//     _handleSharePriceList();
//   }
//
//   Future<void> _handleSharePriceList() async {
//     if (_priceListData == null) return;
//
//     setState(() {
//       _isProcessing = true;
//     });
//
//     try {
//       final pdfFile = await ShareHelper.generatePdf(_priceListData!);
//
//       if (widget.showShareOptions) {
//         if (mounted) {
//           showModalBottomSheet(
//               context: context,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                 builder: (context) => ShareOptionsBottomSheet(
//                   pdfFile: pdfFile,
//                   priceListData: _priceListData!,
//                 ),
//               );
//               }
//               } else {
//           await ShareHelper.sharePdf(context, pdfFile, _priceListData!);
//           }
//           } catch (e) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Error creating PDF: ${e.toString()}')),
//               );
//             }
//           } finally {
//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Price List'),
//         backgroundColor: Colors.indigo,
//         actions: [
//           if (!_isLoading && _priceListData != null)
//             IconButton(
//               icon: _isProcessing
//                   ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//                   : const Icon(Icons.share),
//               onPressed: _isProcessing ? null : _sharePriceList,
//               tooltip: 'Share',
//             ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadPriceList,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Error: $_errorMessage',
//                 style: const TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               CustomButton(
//                 text: 'Retry',
//                 onPressed: _loadPriceList,
//               ),
//             ],
//           ),
//         ),
//       )
//           : _priceListData == null ||
//           (_priceListData!['products'] as List).isEmpty
//           ? const Center(
//         child: Text('No products found. Add some products!'),
//       )
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _priceListData!['shop_name'],
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _priceListData!['shop_address'],
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Products Price List',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (widget.showShareOptions)
//                   ElevatedButton.icon(
//                     onPressed: _isProcessing ? null : _sharePriceList,
//                     icon: const Icon(Icons.share, size: 18),
//                     label: const Text('Share'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.indigo,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Table(
//                   columnWidths: const {
//                     0: FlexColumnWidth(3),
//                     1: FlexColumnWidth(2),
//                   },
//                   border: TableBorder.all(
//                     color: Colors.grey.shade300,
//                     width: 1,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   children: [
//                     TableRow(
//                       decoration: BoxDecoration(
//                         color: Colors.indigo.shade50,
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(8),
//                           topRight: Radius.circular(8),
//                         ),
//                       ),
//                       children: const [
//                         Padding(
//                           padding: EdgeInsets.all(12),
//                           child: Text(
//                             'Product',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(12),
//                           child: Text(
//                             'Price',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                             textAlign: TextAlign.right,
//                           ),
//                         ),
//                       ],
//                     ),
//                     for (var product in _priceListData!['products'])
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               product['name'],
//                               style: const TextStyle(fontSize: 15),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               '\$${product['selling_price'].toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.green,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               textAlign: TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 32),
//             Center(
//               child: Text(
//                 'Total Products: ${(_priceListData!['products'] as List).length}',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey.shade700,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             if (widget.showShareOptions)
//               Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: CustomButton(
//                     text: 'Generate PDF & Share',
//                     onPressed: _isProcessing ? null : _sharePriceList,
//                     isLoading: _isProcessing,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../services/api_service.dart';
// import '../widgets/custom_button.dart';
// import '../utils/sharing_utils.dart';
//
// class PriceListScreen extends StatefulWidget {
//   static const routeName = '/price-list';
//   final bool showShareOptions;
//
//   const PriceListScreen({Key? key, this.showShareOptions = false}) : super(key: key);
//
//   @override
//   State<PriceListScreen> createState() => _PriceListScreenState();
// }
//
// class _PriceListScreenState extends State<PriceListScreen> {
//   final ApiService _apiService = ApiService();
//   Map<String, dynamic>? _priceListData;
//   bool _isLoading = true;
//   bool _isProcessing = false;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPriceList();
//   }
//
//   void _loadPriceList() {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     _apiService.getProductPriceList().then((data) {
//       if (mounted) {
//         setState(() {
//           _priceListData = data;
//           _isLoading = false;
//         });
//       }
//     }).catchError((error) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = error.toString();
//           _isLoading = false;
//         });
//       }
//     });
//   }
//
//   void _sharePriceList() {
//     if (_priceListData == null || _isProcessing) return;
//
//     setState(() {
//       _isProcessing = true;
//     });
//
//     // Generate PDF using the utility class
//     SharingUtils.generatePriceListPdf(
//       shopName: _priceListData!['shop_name'],
//       shopAddress: _priceListData!['shop_address'],
//       shopId: _priceListData!['shop_id'],
//       products: _priceListData!['products'],
//     ).then((pdfFile) {
//       // If we want to show sharing options
//       if (widget.showShareOptions) {
//         if (mounted) {
//           SharingUtils.showSharingOptions(
//               context,
//               pdfFile,
//               'Price List - ${_priceListData!['shop_name']}'
//           );
//         }
//       } else {
//         // Just share the PDF directly
//         SharingUtils.shareFile(
//             context,
//             pdfFile,
//             'Price List - ${_priceListData!['shop_name']}'
//         );
//       }
//     }).catchError((error) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error creating PDF: ${error.toString()}')),
//         );
//       }
//     }).whenComplete(() {
//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Price List'),
//         backgroundColor: Colors.indigo,
//         actions: [
//           if (!_isLoading && _priceListData != null)
//             IconButton(
//               icon: _isProcessing
//                   ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//                   : const Icon(Icons.share),
//               onPressed: _isProcessing ? null : _sharePriceList,
//               tooltip: 'Share',
//             ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadPriceList,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Error: $_errorMessage',
//                 style: const TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               CustomButton(
//                 text: 'Retry',
//                 onPressed: _loadPriceList,
//               ),
//             ],
//           ),
//         ),
//       )
//           : _priceListData == null || (_priceListData!['products'] as List).isEmpty
//           ? const Center(
//         child: Text('No products found. Add some products!'),
//       )
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Shop info card
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _priceListData!['shop_name'],
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _priceListData!['shop_address'],
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             // Products price list heading
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Products Price List',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 // Share button
//                 if (widget.showShareOptions)
//                   ElevatedButton.icon(
//                     onPressed: _isProcessing ? null : _sharePriceList,
//                     icon: const Icon(Icons.share, size: 18),
//                     label: const Text('Share'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.indigo,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//
//             // Products Table
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Table(
//                   columnWidths: const {
//                     0: FlexColumnWidth(3),
//                     1: FlexColumnWidth(2),
//                   },
//                   border: TableBorder.all(
//                     color: Colors.grey.shade300,
//                     width: 1,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   children: [
//                     // Table header
//                     TableRow(
//                       decoration: BoxDecoration(
//                         color: Colors.indigo.shade50,
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(8),
//                           topRight: Radius.circular(8),
//                         ),
//                       ),
//                       children: const [
//                         Padding(
//                           padding: EdgeInsets.all(12),
//                           child: Text(
//                             'Product',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(12),
//                           child: Text(
//                             'Price',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                             textAlign: TextAlign.right,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     // Table rows for each product
//                     for (var product in _priceListData!['products'])
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               product['name'],
//                               style: const TextStyle(fontSize: 15),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Text(
//                               '\$${product['selling_price'].toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.green,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               textAlign: TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Footer
//             const SizedBox(height: 32),
//             Center(
//               child: Text(
//                 'Total Products: ${(_priceListData!['products'] as List).length}',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey.shade700,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             if (widget.showShareOptions)
//               Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: CustomButton(
//                     text: 'Generate PDF & Share',
//                     onPressed: _isProcessing ? null : _sharePriceList,
//                     isLoading: _isProcessing,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }
// }











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

  @override
  void initState() {
    super.initState();
    _loadPriceList();
  }

  // Synchronous wrapper methods
  void _handleShareButtonPress() {
    _sharePriceList();
  }

  void _handleRefreshButtonPress() {
    _loadPriceList();
  }

  void _handleRetryButtonPress() {
    _loadPriceList();
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
    if (_priceListData == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate PDF using the utility class
      final pdfFile = await SharingUtils.generatePriceListPdf(
        shopName: _priceListData!['shop_name'],
        shopAddress: _priceListData!['shop_address'],
        shopId: _priceListData!['shop_id'],
        products: _priceListData!['products'],
      );

      // If we want to show sharing options
      if (widget.showShareOptions) {
        if (mounted) {
          SharingUtils.showSharingOptions(
              context,
              pdfFile,
              'Price List - ${_priceListData!['shop_name']}'
          );
        }
      } else {
        // Just share the PDF directly
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
              onPressed: _isProcessing ? null : _handleShareButtonPress,
              tooltip: 'Share',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefreshButtonPress,
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
                onPressed: _handleRetryButtonPress,
              ),
            ],
          ),
        ),
      )
          : _priceListData == null || (_priceListData!['products'] as List).isEmpty
          ? const Center(
        child: Text('No products found. Add some products!'),
      )
          : SingleChildScrollView(
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

            // Products price list heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products Price List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Share button
                if (widget.showShareOptions)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleShareButtonPress,
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

            // Products Table
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
                    1: FlexColumnWidth(2),
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    // Table rows for each product
                    for (var product in _priceListData!['products'])
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              product['name'],
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '\$${product['selling_price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Total Products: ${(_priceListData!['products'] as List).length}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.showShareOptions)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomButton(
                    text: 'Generate PDF & Share',
                    onPressed: _isProcessing ? null : _handleShareButtonPress,
                    isLoading: _isProcessing,
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}