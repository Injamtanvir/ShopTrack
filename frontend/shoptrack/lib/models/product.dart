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
    // The backend stores half the actual on-hold quantity due to our adjustment
    // So we need to multiply by 2 to show the real quantity to the user
    int rawOnHold = json['quantity_on_hold'] ?? 0;
    int correctedOnHold = rawOnHold * 2;
    
    return Product(
      id: json['_id'],
      name: json['name'],
      quantity: json['quantity'],
      quantityOnHold: correctedOnHold,
      availableQuantity: json['available_quantity'] ?? json['quantity'],
      buyingPrice: json['buying_price'].toDouble(),
      sellingPrice: json['selling_price'].toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    // When sending to backend, divide by 2 again to match what backend expects
    return {
      '_id': id,
      'name': name,
      'quantity': quantity,
      'quantity_on_hold': quantityOnHold ~/ 2, // Convert back to what backend expects
      'available_quantity': availableQuantity,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}