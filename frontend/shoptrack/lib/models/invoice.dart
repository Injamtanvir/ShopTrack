// // // import 'package:intl/intl.dart';
// // //
// // // class InvoiceItem {
// // //   final String productId;
// // //   final String productName;
// // //   final int quantity;
// // //   final double unitPrice;
// // //   final double totalPrice;
// // //
// // //   InvoiceItem({
// // //     required this.productId,
// // //     required this.productName,
// // //     required this.quantity,
// // //     required this.unitPrice,
// // //   }) : totalPrice = quantity * unitPrice;
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'product_id': productId,
// // //       'name': productName,
// // //       'quantity': quantity,
// // //       'unit_price': unitPrice,
// // //       'total_price': totalPrice,
// // //     };
// // //   }
// // //
// // //   factory InvoiceItem.fromJson(Map<String, dynamic> json) {
// // //     return InvoiceItem(
// // //       productId: json['product_id'],
// // //       productName: json['name'],
// // //       quantity: json['quantity'],
// // //       unitPrice: json['unit_price'],
// // //     );
// // //   }
// // // }
// // //
// // // class Invoice {
// // //   final String? id; // MongoDB will generate this
// // //   final String invoiceNumber;
// // //   final String shopId;
// // //   final String shopName;
// // //   final String shopAddress;
// // //   final String shopLicense;
// // //   final String customerName;
// // //   final String customerAddress;
// // //   final DateTime date;
// // //   final List<InvoiceItem> items;
// // //   final double totalAmount;
// // //   final String status; // "pending" or "completed"
// // //   final String createdBy; // User email who created this
// // //
// // //   Invoice({
// // //     this.id,
// // //     required this.invoiceNumber,
// // //     required this.shopId,
// // //     required this.shopName,
// // //     required this.shopAddress,
// // //     required this.shopLicense,
// // //     required this.customerName,
// // //     required this.customerAddress,
// // //     required this.date,
// // //     required this.items,
// // //     required this.status,
// // //     required this.createdBy,
// // //   }) : totalAmount = items.fold(0, (sum, item) => sum + item.totalPrice);
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'invoice_number': invoiceNumber,
// // //       'shop_id': shopId,
// // //       'shop_name': shopName,
// // //       'shop_address': shopAddress,
// // //       'shop_license': shopLicense,
// // //       'customer_name': customerName,
// // //       'customer_address': customerAddress,
// // //       'date': date.toIso8601String(),
// // //       'items': items.map((item) => item.toJson()).toList(),
// // //       'total_amount': totalAmount,
// // //       'status': status,
// // //       'created_by': createdBy,
// // //       'created_at': DateTime.now().toIso8601String(),
// // //     };
// // //   }
// // //
// // //   factory Invoice.fromJson(Map<String, dynamic> json) {
// // //     return Invoice(
// // //       id: json['_id'],
// // //       invoiceNumber: json['invoice_number'],
// // //       shopId: json['shop_id'],
// // //       shopName: json['shop_name'],
// // //       shopAddress: json['shop_address'],
// // //       shopLicense: json['shop_license'],
// // //       customerName: json['customer_name'],
// // //       customerAddress: json['customer_address'],
// // //       date: DateTime.parse(json['date']),
// // //       items: (json['items'] as List)
// // //           .map((item) => InvoiceItem.fromJson(item))
// // //           .toList(),
// // //       status: json['status'],
// // //       createdBy: json['created_by'],
// // //     );
// // //   }
// // //
// // //   String getFormattedDate() {
// // //     return DateFormat('MMMM dd, yyyy').format(date);
// // //   }
// // // }
// //
// //
// //
// //
// //
// // import 'package:intl/intl.dart';
// //
// // class InvoiceItem {
// //   final String productId;
// //   final String productName;
// //   final int quantity;
// //   final double unitPrice;
// //   final double totalPrice;
// //
// //   InvoiceItem({
// //     required this.productId,
// //     required this.productName,
// //     required this.quantity,
// //     required this.unitPrice,
// //   }) : totalPrice = quantity * unitPrice;
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'product_id': productId,
// //       'name': productName,
// //       'quantity': quantity,
// //       'unit_price': unitPrice,
// //       'total_price': totalPrice,
// //     };
// //   }
// //
// //   factory InvoiceItem.fromJson(Map<String, dynamic> json) {
// //     // Ensure proper type conversion
// //     final int quantity = json['quantity'] is int
// //         ? json['quantity']
// //         : int.parse(json['quantity'].toString());
// //
// //     final double unitPrice = json['unit_price'] is double
// //         ? json['unit_price']
// //         : double.parse(json['unit_price'].toString());
// //
// //     return InvoiceItem(
// //       productId: json['product_id'],
// //       productName: json['name'],
// //       quantity: quantity,
// //       unitPrice: unitPrice,
// //     );
// //   }
// // }
// //
// // class Invoice {
// //   final String? id; // MongoDB will generate this
// //   final String invoiceNumber;
// //   final String shopId;
// //   final String shopName;
// //   final String shopAddress;
// //   final String shopLicense;
// //   final String customerName;
// //   final String customerAddress;
// //   final DateTime date;
// //   final List<InvoiceItem> items;
// //   final double totalAmount;
// //   final String status; // "pending" or "completed"
// //   final String createdBy; // User email who created this
// //
// //   Invoice({
// //     this.id,
// //     required this.invoiceNumber,
// //     required this.shopId,
// //     required this.shopName,
// //     required this.shopAddress,
// //     required this.shopLicense,
// //     required this.customerName,
// //     required this.customerAddress,
// //     required this.date,
// //     required this.items,
// //     required this.status,
// //     required this.createdBy,
// //     double? providedTotalAmount,
// //   }) : totalAmount = providedTotalAmount ?? items.fold(0, (sum, item) => sum + item.totalPrice);
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       'invoice_number': invoiceNumber,
// //       'shop_id': shopId,
// //       'shop_name': shopName,
// //       'shop_address': shopAddress,
// //       'shop_license': shopLicense,
// //       'customer_name': customerName,
// //       'customer_address': customerAddress,
// //       'date': date.toIso8601String(),
// //       'items': items.map((item) => item.toJson()).toList(),
// //       'total_amount': totalAmount,
// //       'status': status,
// //       'created_by': createdBy,
// //       'created_at': DateTime.now().toIso8601String(),
// //     };
// //   }
// //
// //   factory Invoice.fromJson(Map<String, dynamic> json) {
// //     // Parse items with proper error handling
// //     List<InvoiceItem> parseItems(List<dynamic> itemsJson) {
// //       return itemsJson.map((item) => InvoiceItem.fromJson(item)).toList();
// //     }
// //
// //     // Safely convert total_amount to double
// //     double parseAmount(dynamic amount) {
// //       if (amount is int) {
// //         return amount.toDouble();
// //       } else if (amount is double) {
// //         return amount;
// //       } else if (amount is String) {
// //         return double.parse(amount);
// //       }
// //       return 0.0;
// //     }
// //
// //     return Invoice(
// //       id: json['_id'],
// //       invoiceNumber: json['invoice_number'],
// //       shopId: json['shop_id'],
// //       shopName: json['shop_name'],
// //       shopAddress: json['shop_address'],
// //       shopLicense: json['shop_license'],
// //       customerName: json['customer_name'],
// //       customerAddress: json['customer_address'],
// //       date: DateTime.parse(json['date']),
// //       items: parseItems(json['items'] as List),
// //       status: json['status'],
// //       createdBy: json['created_by'],
// //       providedTotalAmount: parseAmount(json['total_amount']),
// //     );
// //   }
// //
// //   String getFormattedDate() {
// //     return DateFormat('MMMM dd, yyyy').format(date);
// //   }
// // }
//
//

//
// import 'package:intl/intl.dart';
//
// class InvoiceItem {
//   final String productId;
//   final String productName;
//   final int quantity;
//   final double unitPrice;
//   final double totalPrice;
//
//   InvoiceItem({
//     required this.productId,
//     required this.productName,
//     required this.quantity,
//     required this.unitPrice,
//   }) : totalPrice = quantity * unitPrice;
//
//   Map<String, dynamic> toJson() {
//     return {
//       'product_id': productId,
//       'name': productName,
//       'quantity': quantity,
//       'unit_price': unitPrice,
//       'total_price': totalPrice,
//     };
//   }
//
//   factory InvoiceItem.fromJson(Map<String, dynamic> json) {
//     // Ensure proper type conversion
//     final int quantity = json['quantity'] is int
//         ? json['quantity']
//         : int.parse(json['quantity'].toString());
//
//     final double unitPrice = json['unit_price'] is double
//         ? json['unit_price']
//         : double.parse(json['unit_price'].toString());
//
//     return InvoiceItem(
//       productId: json['product_id'],
//       productName: json['name'],
//       quantity: quantity,
//       unitPrice: unitPrice,
//     );
//   }
// }
//
// class Invoice {
//   final String? id; // MongoDB will generate this
//   final String invoiceNumber;
//   final String shopId;
//   final String shopName;
//   final String shopAddress;
//   final String shopLicense;
//   final String customerName;
//   final String customerAddress;
//   final DateTime date;
//   final List<InvoiceItem> items;
//   final double subtotalAmount;
//   final double discountAmount;
//   final double totalAmount;
//   final String status; // "pending" or "completed"
//   final String createdBy; // User email who created this
//
//   Invoice({
//     this.id,
//     required this.invoiceNumber,
//     required this.shopId,
//     required this.shopName,
//     required this.shopAddress,
//     required this.shopLicense,
//     required this.customerName,
//     required this.customerAddress,
//     required this.date,
//     required this.items,
//     required this.status,
//     required this.createdBy,
//     double? providedTotalAmount,
//     double? providedSubtotalAmount,
//     double? providedDiscountAmount,
//   }) :
//         subtotalAmount = providedSubtotalAmount ?? items.fold(0, (sum, item) => sum + item.totalPrice),
//         discountAmount = providedDiscountAmount ?? 0,
//         totalAmount = providedTotalAmount ??
//             (providedSubtotalAmount ?? items.fold(0, (sum, item) => sum + item.totalPrice)) - (providedDiscountAmount ?? 0);
//
//
//
//
//
//   Map<String, dynamic> toJson() {
//     return {
//       'invoice_number': invoiceNumber,
//       'shop_id': shopId,
//       'shop_name': shopName,
//       'shop_address': shopAddress,
//       'shop_license': shopLicense,
//       'customer_name': customerName,
//       'customer_address': customerAddress,
//       'date': date.toIso8601String(),
//       'items': items.map((item) => item.toJson()).toList(),
//       'subtotal_amount': subtotalAmount,
//       'discount_amount': discountAmount,
//       'total_amount': totalAmount,
//       'status': status,
//       'created_by': createdBy,
//       'created_at': DateTime.now().toIso8601String(),
//     };
//   }
//
//   factory Invoice.fromJson(Map<String, dynamic> json) {
//     // Parse items with proper error handling
//     List<InvoiceItem> parseItems(List<dynamic> itemsJson) {
//       return itemsJson.map((item) => InvoiceItem.fromJson(item)).toList();
//     }
//
//     // Safely convert amount values to double
//     double parseAmount(dynamic amount) {
//       if (amount is int) {
//         return amount.toDouble();
//       } else if (amount is double) {
//         return amount;
//       } else if (amount is String) {
//         return double.parse(amount);
//       }
//       return 0.0;
//     }
//
//     return Invoice(
//       id: json['_id'],
//       invoiceNumber: json['invoice_number'],
//       shopId: json['shop_id'],
//       shopName: json['shop_name'],
//       shopAddress: json['shop_address'],
//       shopLicense: json['shop_license'],
//       customerName: json['customer_name'],
//       customerAddress: json['customer_address'],
//       date: DateTime.parse(json['date']),
//       items: parseItems(json['items'] as List),
//       status: json['status'],
//       createdBy: json['created_by'],
//       providedSubtotalAmount: json.containsKey('subtotal_amount') ? parseAmount(json['subtotal_amount']) : null,
//       providedDiscountAmount: json.containsKey('discount_amount') ? parseAmount(json['discount_amount']) : null,
//       providedTotalAmount: json.containsKey('total_amount') ? parseAmount(json['total_amount']) : null,
//     );
//   }
//
//   String getFormattedDate() {
//     return DateFormat('MMMM dd, yyyy').format(date);
//   }
// }




//
// import 'package:intl/intl.dart';
//
// class InvoiceItem {
//   final String productId;
//   final String productName;
//   final int quantity;
//   final double unitPrice;
//   final double totalPrice;
//
//   InvoiceItem({
//     required this.productId,
//     required this.productName,
//     required this.quantity,
//     required this.unitPrice,
//   }) : totalPrice = quantity * unitPrice;
//
//   Map<String, dynamic> toJson() {
//     return {
//       'product_id': productId,
//       'name': productName,
//       'quantity': quantity,
//       'unit_price': unitPrice,
//       'total_price': totalPrice,
//     };
//   }
//
//   factory InvoiceItem.fromJson(Map<String, dynamic> json) {
//     // Ensure proper type conversion
//     final int quantity = json['quantity'] is int
//         ? json['quantity']
//         : int.parse(json['quantity'].toString());
//
//     final double unitPrice = json['unit_price'] is double
//         ? json['unit_price']
//         : double.parse(json['unit_price'].toString());
//
//     return InvoiceItem(
//       productId: json['product_id'],
//       productName: json['name'],
//       quantity: quantity,
//       unitPrice: unitPrice,
//     );
//   }
// }
//
// class Invoice {
//   final String? id; // MongoDB will generate this
//   final String invoiceNumber;
//   final String shopId;
//   final String shopName;
//   final String shopAddress;
//   final String shopLicense;
//   final String customerName;
//   final String customerAddress;
//   final DateTime date;
//   final List<InvoiceItem> items;
//   final double subtotalAmount;
//   final double discountAmount;
//   final double totalAmount;
//   final String status; // "pending" or "completed"
//   final String createdBy; // User email who created this
//
//   // Regular constructor with all fields required
//   Invoice({
//     required this.id,
//     required this.invoiceNumber,
//     required this.shopId,
//     required this.shopName,
//     required this.shopAddress,
//     required this.shopLicense,
//     required this.customerName,
//     required this.customerAddress,
//     required this.date,
//     required this.items,
//     required this.subtotalAmount,
//     required this.discountAmount,
//     required this.totalAmount,
//     required this.status,
//     required this.createdBy,
//   });
//
//   // Factory constructor to handle the calculation logic
//   factory Invoice.create({
//     String? id,
//     required String invoiceNumber,
//     required String shopId,
//     required String shopName,
//     required String shopAddress,
//     required String shopLicense,
//     required String customerName,
//     required String customerAddress,
//     required DateTime date,
//     required List<InvoiceItem> items,
//     required String status,
//     required String createdBy,
//     double? providedSubtotalAmount,
//     double? providedDiscountAmount,
//     double? providedTotalAmount,
//   }) {
//     // Calculate subtotal if not provided
//     final double subtotal;
//     if (providedSubtotalAmount != null) {
//       subtotal = providedSubtotalAmount;
//     } else {
//       subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
//     }
//
//     // Use provided discount or default to 0
//     final double discount = providedDiscountAmount ?? 0.0;
//
//     // Calculate total if not provided (subtotal - discount)
//     final double total;
//     if (providedTotalAmount != null) {
//       total = providedTotalAmount;
//     } else {
//       total = subtotal - discount;
//     }
//
//     return Invoice(
//       id: id,
//       invoiceNumber: invoiceNumber,
//       shopId: shopId,
//       shopName: shopName,
//       shopAddress: shopAddress,
//       shopLicense: shopLicense,
//       customerName: customerName,
//       customerAddress: customerAddress,
//       date: date,
//       items: items,
//       subtotalAmount: subtotal,
//       discountAmount: discount,
//       totalAmount: total,
//       status: status,
//       createdBy: createdBy,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'invoice_number': invoiceNumber,
//       'shop_id': shopId,
//       'shop_name': shopName,
//       'shop_address': shopAddress,
//       'shop_license': shopLicense,
//       'customer_name': customerName,
//       'customer_address': customerAddress,
//       'date': date.toIso8601String(),
//       'items': items.map((item) => item.toJson()).toList(),
//       'subtotal_amount': subtotalAmount,
//       'discount_amount': discountAmount,
//       'total_amount': totalAmount,
//       'status': status,
//       'created_by': createdBy,
//       'created_at': DateTime.now().toIso8601String(),
//     };
//   }
//
//   factory Invoice.fromJson(Map<String, dynamic> json) {
//     // Parse items with proper error handling
//     List<InvoiceItem> parseItems(List<dynamic> itemsJson) {
//       return itemsJson.map((item) => InvoiceItem.fromJson(item)).toList();
//     }
//
//     // Safely convert amount values to double
//     double parseAmount(dynamic amount) {
//       if (amount is int) {
//         return amount.toDouble();
//       } else if (amount is double) {
//         return amount;
//       } else if (amount is String) {
//         return double.parse(amount);
//       }
//       return 0.0;
//     }
//
//     // Extract all the values from JSON with proper parsing
//     final String? idValue = json['_id'];
//     final String invoiceNumber = json['invoice_number'];
//     final String shopId = json['shop_id'];
//     final String shopName = json['shop_name'];
//     final String shopAddress = json['shop_address'];
//     final String shopLicense = json['shop_license'];
//     final String customerName = json['customer_name'];
//     final String customerAddress = json['customer_address'];
//     final DateTime date = DateTime.parse(json['date']);
//     final List<InvoiceItem> items = parseItems(json['items'] as List);
//     final String status = json['status'];
//     final String createdBy = json['created_by'];
//
//     // Parse amounts with proper handling
//     final double subtotalAmount = json.containsKey('subtotal_amount')
//         ? parseAmount(json['subtotal_amount'])
//         : items.fold(0.0, (sum, item) => sum + item.totalPrice);
//
//     final double discountAmount = json.containsKey('discount_amount')
//         ? parseAmount(json['discount_amount'])
//         : 0.0;
//
//     final double totalAmount = json.containsKey('total_amount')
//         ? parseAmount(json['total_amount'])
//         : (subtotalAmount - discountAmount);
//
//     return Invoice(
//       id: idValue,
//       invoiceNumber: invoiceNumber,
//       shopId: shopId,
//       shopName: shopName,
//       shopAddress: shopAddress,
//       shopLicense: shopLicense,
//       customerName: customerName,
//       customerAddress: customerAddress,
//       date: date,
//       items: items,
//       subtotalAmount: subtotalAmount,
//       discountAmount: discountAmount,
//       totalAmount: totalAmount,
//       status: status,
//       createdBy: createdBy,
//     );
//   }
//
//   String getFormattedDate() {
//     return DateFormat('MMMM dd, yyyy').format(date);
//   }
// }




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
  final double subtotalAmount;
  final double discountAmount;
  final double totalAmount;
  final String status; // "pending" or "completed"
  final String createdBy; // User email who created this

  // Constructor with calculated fields handled properly for null safety
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
  // Calculate subtotal safely
        subtotalAmount = providedSubtotalAmount != null
            ? providedSubtotalAmount
            : items.fold(0.0, (sum, item) => sum + item.totalPrice),

  // Set discount amount
        discountAmount = providedDiscountAmount ?? 0.0,

  // Calculate total amount safely
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
    // Parse items with proper error handling
    List<InvoiceItem> parseItems(List<dynamic> itemsJson) {
      return itemsJson.map((item) => InvoiceItem.fromJson(item)).toList();
    }

    // Safely convert amount values to double
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