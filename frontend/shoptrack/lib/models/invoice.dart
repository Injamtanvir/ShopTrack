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
      'name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
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
  final String? id; // For MongoDB Generates
  final String invoiceNumber;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String shopLicense;
  final String customerName;
  final String customerAddress;
  final DateTime date;
  final List<InvoiceItem> items;
  final double subtotalAmount;
  final double discountAmount;
  final double totalAmount;
  final String status;
  final String createdBy;


  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopLicense,
    required this.customerName,
    required this.customerAddress,
    required this.date,
    required this.items,
    required this.status,
    required this.createdBy,
    double? providedTotalAmount,
    double? providedSubtotalAmount,
    double? providedDiscountAmount,
  }) :

        subtotalAmount = providedSubtotalAmount != null
            ? providedSubtotalAmount
            : items.fold(0.0, (sum, item) => sum + item.totalPrice),


        discountAmount = providedDiscountAmount ?? 0.0,


        totalAmount = providedTotalAmount != null
            ? providedTotalAmount
            : (providedSubtotalAmount != null
            ? providedSubtotalAmount
            : items.fold(0.0, (sum, item) => sum + item.totalPrice)) -
            (providedDiscountAmount ?? 0.0);

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'shop_id': shopId,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_license': shopLicense,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal_amount': subtotalAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'status': status,
      'created_by': createdBy,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> parseItems(List<dynamic> itemsJson) {
      return itemsJson.map((item) => InvoiceItem.fromJson(item)).toList();
    }

    double parseAmount(dynamic amount) {
      if (amount is int) {
        return amount.toDouble();
      } else if (amount is double) {
        return amount;
      } else if (amount is String) {
        return double.parse(amount);
      }
      return 0.0;
    }

    return Invoice(
      id: json['_id'],
      invoiceNumber: json['invoice_number'],
      shopId: json['shop_id'],
      shopName: json['shop_name'],
      shopAddress: json['shop_address'],
      shopLicense: json['shop_license'],
      customerName: json['customer_name'],
      customerAddress: json['customer_address'],
      date: DateTime.parse(json['date']),
      items: parseItems(json['items'] as List),
      status: json['status'],
      createdBy: json['created_by'],
      providedSubtotalAmount: json.containsKey('subtotal_amount') ? parseAmount(json['subtotal_amount']) : null,
      providedDiscountAmount: json.containsKey('discount_amount') ? parseAmount(json['discount_amount']) : null,
      providedTotalAmount: json.containsKey('total_amount') ? parseAmount(json['total_amount']) : null,
    );
  }

  String getFormattedDate() {
    return DateFormat('MMMM dd, yyyy').format(date);
  }
}