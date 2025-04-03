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

    final response = await http.get(
      Uri.parse('${ApiConstants.getNextInvoiceNumber}/$shopId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['next_invoice_number'];
    } else {
      throw Exception('Failed to get next invoice number');
    }
  }

  // Save invoice as pending
  Future<Map<String, dynamic>> savePendingInvoice(Invoice invoice) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.saveInvoice),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(invoice.toJson()),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to save invoice');
    }
  }

  // Generate invoice (changes status and updates inventory)
  Future<Map<String, dynamic>> generateInvoice(String invoiceId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.generateInvoice}/$invoiceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to generate invoice');
    }
  }

  // Get all pending invoices for a shop
  Future<List<Invoice>> getPendingInvoices(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.getPendingInvoices}/$shopId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Invoice.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get pending invoices');
    }
  }

  // Get completed invoices (history)
  Future<List<Invoice>> getInvoiceHistory(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.getInvoiceHistory}/$shopId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Invoice.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get invoice history');
    }
  }

  // Get a specific invoice by ID
  Future<Invoice> getInvoiceById(String invoiceId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.getInvoice}/$invoiceId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Invoice.fromJson(data);
    } else {
      throw Exception('Failed to get invoice');
    }
  }

  // Search for products by name (for autocomplete)
  Future<List<Map<String, dynamic>>> searchProducts(String shopId, String query) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.searchProducts}/$shopId?query=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search products');
    }
  }
}