//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../constants/api_constants.dart';
// import '../models/invoice.dart';
//
<<<<<<< HEAD
=======
//
>>>>>>> master
// class InvoiceService {
//   final FlutterSecureStorage _storage = const FlutterSecureStorage();
//
//   // Generate a new invoice number (6 digits)
//   Future<String> getNextInvoiceNumber(String shopId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getNextInvoiceNumber}/$shopId'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['next_invoice_number'];
//     } else {
//       throw Exception('Failed to get next invoice number');
//     }
//   }
//
//   // Save invoice as pending
//   Future<Map<String, dynamic>> savePendingInvoice(Invoice invoice) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.post(
//       Uri.parse(ApiConstants.saveInvoice),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode(invoice.toJson()),
//     );
//
//     if (response.statusCode == 201) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to save invoice');
//     }
//   }
//
//   // Generate invoice (changes status and updates inventory)
//   Future<Map<String, dynamic>> generateInvoice(String invoiceId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.post(
//       Uri.parse('${ApiConstants.generateInvoice}/$invoiceId'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to generate invoice');
//     }
//   }
//
//   // Get all pending invoices for a shop
//   Future<List<Invoice>> getPendingInvoices(String shopId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getPendingInvoices}/$shopId'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((item) => Invoice.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to get pending invoices');
//     }
//   }
//
//   // Get completed invoices (history)
//   Future<List<Invoice>> getInvoiceHistory(String shopId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getInvoiceHistory}/$shopId'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((item) => Invoice.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to get invoice history');
//     }
//   }
//
//   // Get a specific invoice by ID
//   Future<Invoice> getInvoiceById(String invoiceId) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse('${ApiConstants.getInvoice}/$invoiceId'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return Invoice.fromJson(data);
//     } else {
//       throw Exception('Failed to get invoice');
//     }
//   }
//
//   // Search for products by name (for autocomplete)
//   Future<List<Map<String, dynamic>>> searchProducts(String shopId, String query) async {
//     final token = await _storage.read(key: 'token') ?? '';
//     if (token.isEmpty) {
//       throw Exception('Authorization token not found');
//     }
//
//     final response = await http.get(
//       Uri.parse('${ApiConstants.searchProducts}/$shopId?query=$query'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.cast<Map<String, dynamic>>();
//     } else {
//       throw Exception('Failed to search products');
//     }
//   }
// }



<<<<<<< HEAD
=======

>>>>>>> master

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../models/invoice.dart';

class InvoiceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Generate a new invoice number (6 digits)
  Future<String> getNextInvoiceNumber(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug URL
      final url = '${ApiConstants.getNextInvoiceNumber}/$shopId';
      print('Fetching next invoice number from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Debug response
      print('Next invoice number response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check if response is HTML
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

=======
      print('Fetching next invoice number from: ${ApiConstants.getNextInvoiceNumber}$shopId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getNextInvoiceNumber}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
>>>>>>> master
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['next_invoice_number'];
      } else {
<<<<<<< HEAD
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to get next invoice number');
        } catch (e) {
          throw Exception('Failed to get next invoice number. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error getting next invoice number: $e');
      throw Exception('Error: $e');
=======
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get invoice number: ${response.body}');
      }
    } catch (e) {
      print('Error getting invoice number: $e');
      rethrow;
>>>>>>> master
    }
  }

  // Save invoice as pending
  Future<Map<String, dynamic>> savePendingInvoice(Invoice invoice) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug info
      print('Saving invoice: ${invoice.invoiceNumber}');
      print('API URL: ${ApiConstants.saveInvoice}');

      final response = await http.post(
        Uri.parse(ApiConstants.saveInvoice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(invoice.toJson()),
      );

      // Debug response
      print('Save invoice response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check for HTML response
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to save invoice');
        } catch (e) {
          throw Exception('Failed to save invoice. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error saving invoice: $e');
      throw Exception('Error: $e');
=======
      print('Saving invoice to: ${ApiConstants.saveInvoice}');
      final response = await http.post(
        Uri.parse(ApiConstants.saveInvoice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(invoice.toJson()),
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to save invoice');
      }
    } catch (e) {
      print('Error saving invoice: $e');
      rethrow;
>>>>>>> master
    }
  }

  // Generate invoice (changes status and updates inventory)
  Future<Map<String, dynamic>> generateInvoice(String invoiceId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug info
      final url = '${ApiConstants.generateInvoice}/$invoiceId';
      print('Generating invoice: $invoiceId');
      print('API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug response
      print('Generate invoice response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check for HTML response
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to generate invoice');
        } catch (e) {
          throw Exception('Failed to generate invoice. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error generating invoice: $e');
      throw Exception('Error: $e');
=======
      print('Generating invoice: ${ApiConstants.generateInvoice}$invoiceId/');
      final response = await http.post(
        Uri.parse('${ApiConstants.generateInvoice}$invoiceId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to generate invoice');
      }
    } catch (e) {
      print('Error generating invoice: $e');
      rethrow;
>>>>>>> master
    }
  }

  // Get all pending invoices for a shop
  Future<List<Invoice>> getPendingInvoices(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug info
      final url = '${ApiConstants.getPendingInvoices}/$shopId';
      print('Fetching pending invoices for shop: $shopId');
      print('API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Debug response
      print('Pending invoices response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check for HTML response
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

=======
      print('Fetching pending invoices: ${ApiConstants.getPendingInvoices}$shopId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getPendingInvoices}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
>>>>>>> master
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Invoice.fromJson(item)).toList();
      } else {
<<<<<<< HEAD
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to get pending invoices');
        } catch (e) {
          throw Exception('Failed to get pending invoices. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error getting pending invoices: $e');
      throw Exception('Error: $e');
=======
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get pending invoices');
      }
    } catch (e) {
      print('Error fetching pending invoices: $e');
      rethrow;
>>>>>>> master
    }
  }

  // Get completed invoices (history)
  Future<List<Invoice>> getInvoiceHistory(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug info
      final url = '${ApiConstants.getInvoiceHistory}/$shopId';
      print('Fetching invoice history for shop: $shopId');
      print('API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Debug response
      print('Invoice history response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check for HTML response
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

=======
      print('Fetching invoice history: ${ApiConstants.getInvoiceHistory}$shopId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getInvoiceHistory}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
>>>>>>> master
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Invoice.fromJson(item)).toList();
      } else {
<<<<<<< HEAD
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to get invoice history');
        } catch (e) {
          throw Exception('Failed to get invoice history. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error getting invoice history: $e');
      throw Exception('Error: $e');
=======
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get invoice history');
      }
    } catch (e) {
      print('Error fetching invoice history: $e');
      rethrow;
>>>>>>> master
    }
  }

  // Get a specific invoice by ID
  Future<Invoice> getInvoiceById(String invoiceId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug info
      final url = '${ApiConstants.getInvoice}/$invoiceId';
      print('Fetching invoice: $invoiceId');
      print('API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Debug response
      print('Invoice details response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check for HTML response
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

=======
      print('Fetching invoice: ${ApiConstants.getInvoice}$invoiceId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getInvoice}$invoiceId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
>>>>>>> master
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Invoice.fromJson(data);
      } else {
<<<<<<< HEAD
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to get invoice');
        } catch (e) {
          throw Exception('Failed to get invoice. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error getting invoice: $e');
      throw Exception('Error: $e');
=======
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get invoice');
      }
    } catch (e) {
      print('Error fetching invoice: $e');
      rethrow;
>>>>>>> master
    }
  }

  // Search for products by name (for autocomplete)
  // Search for products by name (for autocomplete)
  Future<List<Map<String, dynamic>>> searchProducts(String shopId, String query) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
<<<<<<< HEAD
      // Debug info
      final url = '${ApiConstants.searchProducts}/$shopId?query=$query';
      print('Searching products in shop: $shopId, query: $query');
      print('API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Debug response
      print('Search products response [${response.statusCode}]: ${response.body.substring(0, min(100, response.body.length))}...');

      // Check for HTML response
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        throw Exception('Received HTML response instead of JSON. Server error or invalid endpoint.');
      }

=======
      print('Searching products: ${ApiConstants.searchProducts}$shopId/?query=$query');
      final response = await http.get(
        Uri.parse('${ApiConstants.searchProducts}$shopId/?query=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
>>>>>>> master
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
<<<<<<< HEAD
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to search products');
        } catch (e) {
          throw Exception('Failed to search products. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Error: $e');
=======
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to search products');
      }
    } catch (e) {
      print('Error searching products: $e');
      rethrow;
>>>>>>> master
    }
  }
}