// Create a new file: lib/services/stats_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/invoice.dart';

class StatsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get today's sales statistics
  Future<Map<String, dynamic>> getTodaySalesStats(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getTodayStats}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get today\'s statistics');
      }
    } catch (e) {
      print('Error getting today\'s statistics: $e');
      rethrow;
    }
  }

  // Get today's invoices
  Future<List<Invoice>> getTodayInvoices(String shopId) async {
    final token = await _storage.read(key: 'token') ?? '';
    if (token.isEmpty) {
      throw Exception('Authorization token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.getTodayInvoices}$shopId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        try {
          return data.map((item) => Invoice.fromJson(item)).toList();
        } catch (parseError) {
          print('Error parsing today\'s invoices: $parseError');
          throw Exception('Failed to parse invoice data: $parseError');
        }
      } else {
        if (response.body.contains('<!DOCTYPE') || response.body.contains('<html>')) {
          throw Exception('Server returned HTML instead of JSON. Check URL configuration.');
        }
        throw Exception('Failed to get today\'s invoices');
      }
    } catch (e) {
      print('Error fetching today\'s invoices: $e');
      rethrow;
    }
  }
}