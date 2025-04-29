class Batch {
  final String id;
  final String productId;
  final String purchaseDate;
  final int quantityPurchased;
  final int remaining;
  final double costPrice;

  Batch({
    required this.id,
    required this.productId,
    required this.purchaseDate,
    required this.quantityPurchased,
    required this.remaining,
    required this.costPrice,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['_id'],
      productId: json['productId'],
      purchaseDate: json['purchaseDate'],
      quantityPurchased: json['quantityPurchased'],
      remaining: json['remaining'],
      costPrice: json['costPrice'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'purchaseDate': purchaseDate,
      'quantityPurchased': quantityPurchased,
      'remaining': remaining,
      'costPrice': costPrice,
    };
  }
} 