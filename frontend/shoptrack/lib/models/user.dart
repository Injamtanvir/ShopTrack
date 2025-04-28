class User {
  final String shopId;
  final String name;
  final String email;
  final String role;
  final String? designation;
  final String? sellerId;
  final String? shopName;
  final String id;
  final String? address;
  final String? createdAt;

  User({
    required this.shopId,
    required this.name,
    required this.email,
    required this.role,
    required this.id,
    this.designation,
    this.sellerId,
    this.shopName,
    this.address,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: json['shop_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      designation: json['designation'],
      sellerId: json['seller_id'],
      shopName: json['shop_name'],
      address: json['address'],
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'email': email,
      'role': role,
      'designation': designation,
      'seller_id': sellerId,
      'shop_name': shopName,
      'address': address,
      'created_at': createdAt,
    };
  }
}

