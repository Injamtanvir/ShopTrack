import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  // Initialize provider - check if user is already logged in
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isValid = await _apiService.verifyToken();
      if (isValid) {
        _user = await _apiService.getCurrentUser();
      } else {
        await _apiService.logout();
        _user = null;
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Register a shop and admin user
  Future<String?> registerShop({
    required String name,
    required String address,
    required String ownerName,
    required String licenseNumber,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.registerShop(
        name: name,
        address: address,
        ownerName: ownerName,
        licenseNumber: licenseNumber,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      return result['shop_id'];
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    required String shopId,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.login(
        shopId: shopId,
        email: email,
        password: password,
      );

      _user = User.fromJson(result['user']);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }


  // Register a sales person (for admin)
  Future<bool> registerSalesPerson({
    required String name,
    required String designation,
    required String sellerId,
    required String email,
    required String password,
  }) async {
    if (!isAdmin) {
      _setError('Only admins can register sales persons');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _apiService.registerSalesPerson(
        name: name,
        designation: designation,
        sellerId: sellerId,
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register another admin (for admin)
  Future<bool> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isAdmin) {
      _setError('Only admins can register other admins');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _apiService.registerAdmin(
        name: name,
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiService.logout();
      _user = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

