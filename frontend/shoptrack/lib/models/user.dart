// class User {
//   final String shopId;
//   final String name;
//   final String email;
//   final String role;
//   final String? designation;
//   final String? sellerId;
//   final String? shopName;
//
//   User({
//     required this.shopId,
//     required this.name,
//     required this.email,
//     required this.role,
//     this.designation,
//     this.sellerId,
//     this.shopName,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       shopId: json['shop_id'],
//       name: json['name'],
//       email: json['email'],
//       role: json['role'],
//       designation: json['designation'],
//       sellerId: json['seller_id'],
//       shopName: json['shop_name'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'shop_id': shopId,
//       'name': name,
//       'email': email,
//       'role': role,
//       'designation': designation,
//       'seller_id': sellerId,
//       'shop_name': shopName,
//     };
//   }
// }




class User {
  final String shopId;
  final String name;
  final String email;
  final String role;
  final String? designation;
  final String? sellerId;
  final String? shopName;

  User({
    required this.shopId,
    required this.name,
    required this.email,
    required this.role,
    this.designation,
    this.sellerId,
    this.shopName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      shopId: json['shop_id'] ?? '', // Add null safety
      name: json['name'] ?? '', // Add null safety
      email: json['email'] ?? '', // Add null safety
      role: json['role'] ?? 'seller', // Provide a default role
      designation: json['designation'], // Keep as nullable
      sellerId: json['seller_id'], // Keep as nullable
      shopName: json['shop_name'], // Keep as nullable
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'name': name,
      'email': email,
      'role': role,
      'designation': designation,
      'seller_id': sellerId,
      'shop_name': shopName,
    };
  }
}