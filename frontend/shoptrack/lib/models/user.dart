// // //
// // // class User {
// // //   final String? id;
// // //   final String shopId;
// // //   final String name;
// // //   final String email;
// // //   final String role;
// // //   final String? designation;
// // //   final String? sellerId;
// // //   final String? shopName;
// // //
// // //   User({
// // //     this.id,
// // //     required this.shopId,
// // //     required this.name,
// // //     required this.email,
// // //     required this.role,
// // //     this.designation,
// // //     this.sellerId,
// // //     this.shopName,
// // //   });
// // //
// // //   factory User.fromJson(Map<String, dynamic> json) {
// // //     return User(
// // //       id: json['_id'],
// // //       shopId: json['shop_id'],
// // //       name: json['name'],
// // //       email: json['email'],
// // //       role: json['role'],
// // //       designation: json['designation'],
// // //       sellerId: json['seller_id'],
// // //       shopName: json['shop_name'],
// // //     );
// // //   }
// // //
// // //   Map<String, dynamic> toJson() {
// // //     return {
// // //       'shop_id': shopId,
// // //       'name': name,
// // //       'email': email,
// // //       'role': role,
// // //       'designation': designation,
// // //       'seller_id': sellerId,
// // //       'shop_name': shopName,
// // //     };
// // //   }
// // // }
// //
// //
// //
// // class User {
// //   final String? id;
// //   final String shopId;
// //   final String name;
// //   final String email;
// //   final String role;
// //   final String? designation;
// //   final String? sellerId;
// //   final String? shopName;
// //
// //   User({
// //     this.id,
// //     required this.shopId,
// //     required this.name,
// //     required this.email,
// //     required this.role,
// //     this.designation,
// //     this.sellerId,
// //     this.shopName,
// //   });
// //
// //   factory User.fromJson(Map<String, dynamic> json) {
// //     return User(
// //       id: json['_id'],
// //       shopId: json['shop_id'],
// //       name: json['name'],
// //       email: json['email'],
// //       role: json['role'],
// //       // Make sure to properly extract these values, even if they're null
// //       designation: json['designation'],
// //       sellerId: json['seller_id'],
// //       shopName: json['shop_name'],
// //     );
// //   }
// //
// //   Map<String, dynamic> toJson() {
// //     return {
// //       '_id': id,
// //       'shop_id': shopId,
// //       'name': name,
// //       'email': email,
// //       'role': role,
// //       'designation': designation,
// //       'seller_id': sellerId,
// //       'shop_name': shopName,
// //     };
// //   }
// // }
//
//
// class User {
//   final String? id;
//   final String shopId;
//   final String name;
//   final String email;
//   final String role;
//   final String? designation;
//   final String? sellerId;
//   final String? shopName;
//
//   User({
//     this.id,
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
//     // Print the raw JSON for debugging
//     print('Raw user JSON: $json');
//
//     return User(
//       id: json['_id'],
//       shopId: json['shop_id'],
//       name: json['name'],
//       email: json['email'],
//       role: json['role'],
//       // Handle both direct fields and nested fields for compatibility
//       designation: json['designation'] ??
//           (json.containsKey('user') ? json['user']['designation'] : null),
//       sellerId: json['seller_id'] ??
//           (json.containsKey('user') ? json['user']['seller_id'] : null),
//       shopName: json['shop_name'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
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
  final String? id;
  final String shopId;
  final String name;
  final String email;
  final String role;
  final String? designation;
  final String? sellerId;
  final String? shopName;

  User({
    this.id,
    required this.shopId,
    required this.name,
    required this.email,
    required this.role,
    this.designation,
    this.sellerId,
    this.shopName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Print the raw JSON for debugging
    print('Raw user JSON: $json');

    return User(
      id: json['_id'],
      shopId: json['shop_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      // Handle both direct fields and nested fields for compatibility
      designation: json['designation'] ??
          (json.containsKey('user') ? json['user']['designation'] : null),
      sellerId: json['seller_id'] ??
          (json.containsKey('user') ? json['user']['seller_id'] : null),
      shopName: json['shop_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
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