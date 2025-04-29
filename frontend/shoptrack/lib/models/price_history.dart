class PriceHistory {
  final String id;
  final String productId;
  final double oldPrice;
  final double newPrice;
  final String changeDate;
  final String changedBy;

  PriceHistory({
    required this.id,
    required this.productId,
    required this.oldPrice,
    required this.newPrice,
    required this.changeDate,
    required this.changedBy,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      id: json['_id'],
      productId: json['productId'],
      oldPrice: json['oldPrice'].toDouble(),
      newPrice: json['newPrice'].toDouble(),
      changeDate: json['changeDate'],
      changedBy: json['changed_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'changeDate': changeDate,
      'changed_by': changedBy,
    };
  }
} 