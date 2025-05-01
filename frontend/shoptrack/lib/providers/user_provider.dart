import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isManager => _user?.role == 'manager';
  bool get isOwner => _user?.role == 'owner';
  bool get canDeleteProducts => isManager || isOwner;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
  
  void updateUserRole(String role) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        shopId: _user!.shopId,
        name: _user!.name,
        email: _user!.email,
        role: role,
        designation: _user!.designation,
        sellerId: _user!.sellerId,
        shopName: _user!.shopName,
        address: _user!.address,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    }
  }
} 