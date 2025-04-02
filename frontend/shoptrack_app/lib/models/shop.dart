class Shop {
  final String shopId;
  final String name;
  final String address;
  final String ownerName;
  final String licenseNumber;

  Shop({
    required this.shopId,
    required this.name,
    required this.address,
    required this.ownerName,
    required this.licenseNumber,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      shopId: json['shop_id'],
      name: json['name'],
      address: json['address'],
      ownerName: json['owner_name'],
      licenseNumber: json['license_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'name': name,
      'address': address,
      'owner_name': ownerName,
      'license_number': licenseNumber,
    };
  }
}