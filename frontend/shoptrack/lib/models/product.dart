class Product {
  final String id;
  final String name;
  final int quantity;
  final double buyingPrice;
  final double sellingPrice;
  final String createdAt;
  final String updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      quantity: json['quantity'],
      buyingPrice: json['buying_price'].toDouble(),
      sellingPrice: json['selling_price'].toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'quantity': quantity,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}