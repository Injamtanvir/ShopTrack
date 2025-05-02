class Batch {
  final String id;
  final String productId;
  final String productName;
  final String purchaseDate;
  final int quantityPurchased;
  final int remaining;
  final double costPrice;
  final String? shopId;
  final String createdAt;
  final double? sellingPrice;
  final bool isInitialBatch;

  Batch({
    required this.id,
    required this.productId,
    this.productName = 'Unknown Product',
    required this.purchaseDate,
    required this.quantityPurchased,
    required this.remaining,
    required this.costPrice,
    this.shopId,
    required this.createdAt,
    this.sellingPrice,
    this.isInitialBatch = false,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    try {
      return Batch(
        id: json['_id'] ?? json['id'] ?? '',
        productId: json['product_id'] ?? '',
        productName: json['product_name'] ?? 'Unknown Product',
        purchaseDate: json['purchase_date'] ?? '',
        quantityPurchased: json['quantity_purchased'] ?? json['quantity'] ?? 0,
        remaining: json['remaining'] ?? 0,
        costPrice: (json['cost_price'] is num) ? json['cost_price'].toDouble() : 0.0,
        shopId: json['shop_id'],
        createdAt: json['created_at'] ?? '',
        sellingPrice: (json['selling_price'] is num) ? json['selling_price'].toDouble() : null,
        isInitialBatch: json['is_initial_batch'] ?? false,
      );
    } catch (e) {
      print('Error parsing batch data: $e');
      print('Problematic JSON: $json');
      // Return a default batch with empty/zero values to avoid null errors
      return Batch(
        id: '',
        productId: '',
        productName: 'Unknown Product', 
        purchaseDate: '',
        quantityPurchased: 0,
        remaining: 0,
        costPrice: 0.0,
        createdAt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product_id': productId,
      'product_name': productName,
      'purchase_date': purchaseDate,
      'quantity_purchased': quantityPurchased,
      'remaining': remaining,
      'cost_price': costPrice,
      'shop_id': shopId,
      'created_at': createdAt,
      'selling_price': sellingPrice,
      'is_initial_batch': isInitialBatch,
    };
  }

  // Helper method to get sold quantity
  int get soldQuantity => quantityPurchased - remaining;

  // Helper method to get profit margin percentage if selling price is available
  double? get profitMarginPercentage {
    if (sellingPrice == null) return null;
    return ((sellingPrice! - costPrice) / costPrice) * 100;
  }

  // Helper method to get total cost
  double get totalCost => costPrice * quantityPurchased;

  // Helper method to get potential revenue if selling price is available
  double? get potentialRevenue {
    if (sellingPrice == null) return null;
    return sellingPrice! * quantityPurchased;
  }

  // Helper method to get potential profit if selling price is available
  double? get potentialProfit {
    if (sellingPrice == null) return null;
    return (sellingPrice! - costPrice) * quantityPurchased;
  }
} 