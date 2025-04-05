
import 'dart:convert';
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
      print('Fetching next invoice number from: ${ApiConstants.getNextInvoiceNumber}$shopId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getNextInvoiceNumber}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['next_invoice_number'];
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get invoice number: ${response.body}');
      }
    } catch (e) {
      print('Error getting invoice number: $e');
      rethrow;
    }
  }

  // Save invoice as pending
  Future<Map<String, dynamic>> savePendingInvoice(Invoice invoice) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
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
    }
  }

  // Generate invoice (changes status and updates inventory)
  Future<Map<String, dynamic>> generateInvoice(String invoiceId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
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
    }
  }

  // Get all pending invoices for a shop
  Future<List<Invoice>> getPendingInvoices(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Fetching pending invoices: ${ApiConstants.getPendingInvoices}$shopId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getPendingInvoices}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Invoice.fromJson(item)).toList();
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get pending invoices');
      }
    } catch (e) {
      print('Error fetching pending invoices: $e');
      rethrow;
    }
  }

  // Get completed invoices (history)
  Future<List<Invoice>> getInvoiceHistory(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Fetching invoice history: ${ApiConstants.getInvoiceHistory}$shopId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getInvoiceHistory}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Invoice.fromJson(item)).toList();
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get invoice history');
      }
    } catch (e) {
      print('Error fetching invoice history: $e');
      rethrow;
    }
  }

  // Get a specific invoice by ID
  Future<Invoice> getInvoiceById(String invoiceId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Fetching invoice: ${ApiConstants.getInvoice}$invoiceId/');
      final response = await http.get(
        Uri.parse('${ApiConstants.getInvoice}$invoiceId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Invoice.fromJson(data);
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get invoice');
      }
    } catch (e) {
      print('Error fetching invoice: $e');
      rethrow;
    }
  }

  // Search for products by name (for autocomplete)
  Future<List<Map<String, dynamic>>> searchProducts(String shopId, String query) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      print('Searching products: ${ApiConstants.searchProducts}$shopId/?query=$query');
      final response = await http.get(
        Uri.parse('${ApiConstants.searchProducts}$shopId/?query=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to search products');
      }
    } catch (e) {
      print('Error searching products: $e');
      rethrow;
    }
  }
}