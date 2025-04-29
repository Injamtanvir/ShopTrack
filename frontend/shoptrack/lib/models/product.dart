class Product {
  final String id;
  final String name;
  final int quantity;
  final int quantityOnHold;
  final int availableQuantity;
  final double buyingPrice;
  final double sellingPrice;
  final String createdAt;
  final String updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    this.quantityOnHold = 0,
    required this.availableQuantity,
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
      quantityOnHold: json['quantity_on_hold'] ?? 0,
      availableQuantity: json['available_quantity'] ?? json['quantity'],
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
      'quantity_on_hold': quantityOnHold,
      'available_quantity': availableQuantity,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}