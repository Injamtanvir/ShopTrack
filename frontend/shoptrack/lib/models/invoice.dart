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
    return InvoiceItem(
      productId: json['product_id'],
      productName: json['name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
    );
  }
}

class Invoice {
  final String? id; // MongoDB will generate this
  final String invoiceNumber;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String shopLicense;
  final String customerName;
  final String customerAddress;
  final DateTime date;
  final List<InvoiceItem> items;
  final double totalAmount;
  final String status; // "pending" or "completed"
  final String createdBy; // User email who created this

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
  }) : totalAmount = items.fold(0, (sum, item) => sum + item.totalPrice);

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
      'total_amount': totalAmount,
      'status': status,
      'created_by': createdBy,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
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
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      status: json['status'],
      createdBy: json['created_by'],
    );
  }

  String getFormattedDate() {
    return DateFormat('MMMM dd, yyyy').format(date);
  }
}