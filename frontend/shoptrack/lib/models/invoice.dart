import 'package:intl/intl.dart';

class InvoiceItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  }) : totalPrice = quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': totalPrice,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    // Ensure proper type conversion
    final int quantity = json['quantity'] is int
        ? json['quantity']
        : int.parse(json['quantity'].toString());

    final double unitPrice = json['unit_price'] is double
        ? json['unit_price']
        : double.parse(json['unit_price'].toString());

    return InvoiceItem(
      productId: json['product_id'],
      productName: json['name'],
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String shopLicense;
  final String shopVatLicense;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final DateTime date;
  final List<InvoiceItem> items;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final String? completedBy;
  final DateTime? completedAt;
  final double providedSubtotalAmount;
  final double providedDiscountAmount;
  final double providedTotalAmount;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopLicense,
    required this.shopVatLicense,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.date,
    required this.items,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.completedBy,
    this.completedAt,
    required this.providedSubtotalAmount,
    required this.providedDiscountAmount,
    required this.providedTotalAmount,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    try {
      // Create a safe getter for JSON fields
      T getField<T>(String key, T defaultValue) {
        final value = json[key];
        if (value == null) return defaultValue;
        if (value is T) return value;
        return defaultValue;
      }

      // Parse date fields safely
      DateTime parseDate(String key, DateTime defaultValue) {
        final value = json[key];
        if (value == null) return defaultValue;
        
        try {
          if (value is String) {
            return DateTime.parse(value);
          } else if (value is Map) {
            // Handle MongoDB ISODate format if it comes as an object
            final timestamp = value['\$date'];
            if (timestamp != null) {
              return DateTime.fromMillisecondsSinceEpoch(timestamp);
            }
          }
        } catch (e) {
          print('Error parsing date $key: $e');
        }
        
        return defaultValue;
      }

      // Parse items list safely
      List<InvoiceItem> parseItems() {
        final items = json['items'];
        if (items == null || items is! List) return [];
        
        return items.map((item) {
          try {
            return InvoiceItem.fromJson(item);
          } catch (e) {
            print('Error parsing invoice item: $e');
            return InvoiceItem(
              productId: '',
              productName: 'Error item',
              quantity: 0,
              unitPrice: 0,
            );
          }
        }).toList();
      }

      return Invoice(
        id: getField('_id', ''),
        invoiceNumber: getField('invoice_number', ''),
        shopId: getField('shop_id', ''),
        shopName: getField('shop_name', ''),
        shopAddress: getField('shop_address', ''),
        shopLicense: getField('shop_license', ''),
        shopVatLicense: getField('shop_vat_license', ''),
        customerName: getField('customer_name', ''),
        customerAddress: getField('customer_address', ''),
        customerPhone: getField('customer_phone', ''),
        date: parseDate('date', DateTime.now()),
        items: parseItems(),
        status: getField('status', 'pending'),
        createdBy: getField('created_by', ''),
        createdAt: parseDate('created_at', DateTime.now()),
        completedBy: getField('completed_by', null),
        completedAt: json['completed_at'] != null ? parseDate('completed_at', DateTime.now()) : null,
        providedSubtotalAmount: (json['total_amount'] ?? 0).toDouble(),
        providedDiscountAmount: (json['discount_amount'] ?? 0).toDouble(),
        providedTotalAmount: (json['final_amount'] ?? 0).toDouble(),
      );
    } catch (e) {
      print('Error parsing invoice: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'shop_id': shopId,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_license': shopLicense,
      'shop_vat_license': shopVatLicense,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_phone': customerPhone,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'created_by': createdBy,
      'total_amount': providedSubtotalAmount,
      'discount_amount': providedDiscountAmount,
      'final_amount': providedTotalAmount,
    };
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => providedDiscountAmount;
  double get totalWithDiscount => subtotal - discountAmount;

  String getFormattedDate() {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  String getFormattedDateTime() {
    return DateFormat('MMMM dd, yyyy HH:mm').format(date);
  }
}