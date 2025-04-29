class Batch {
  final String id;
  final String productId;
  final String purchaseDate;
  final int quantityPurchased;
  final int remaining;
  final double costPrice;
  final String? shopId;
  final String createdAt;
  final double? sellingPrice;

  Batch({
    required this.id,
    required this.productId,
    required this.purchaseDate,
    required this.quantityPurchased,
    required this.remaining,
    required this.costPrice,
    this.shopId,
    required this.createdAt,
    this.sellingPrice,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['_id'],
      productId: json['product_id'],
      purchaseDate: json['purchase_date'],
      quantityPurchased: json['quantity_purchased'],
      remaining: json['remaining'],
      costPrice: json['cost_price'].toDouble(),
      shopId: json['shop_id'],
      createdAt: json['created_at'],
      sellingPrice: json['selling_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product_id': productId,
      'purchase_date': purchaseDate,
      'quantity_purchased': quantityPurchased,
      'remaining': remaining,
      'cost_price': costPrice,
      'shop_id': shopId,
      'created_at': createdAt,
      'selling_price': sellingPrice,
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