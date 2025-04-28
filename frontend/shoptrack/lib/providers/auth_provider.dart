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
  bool get isManager => _user?.role == 'manager';
  bool get isAdmin => _user?.role == 'manager';
  bool get isOwner => _user?.role == 'owner';

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
    required String ownerPhone,
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
        ownerPhone: ownerPhone,
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

  // Register another admin (for admin)
  Future<bool> registerAdmin({
    required String name,
    required String designation,
    required String employeeId,
    required String email,
    required String password,
    String? imageBase64,
    required String idNumber,
    required DateTime dateOfBirth,
    required String address,
    required String phoneNumber,
    required double salary,
  }) async {
    if (!isManager && !isOwner) {
      _setError('Only managers and owners can register managers');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _apiService.registerManager(
        name: name,
        designation: designation,
        employeeId: employeeId,
        email: email,
        password: password,
        imageBase64: imageBase64,
        idNumber: idNumber,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        salary: salary,
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
  Future<bool> registerManager({
    required String name,
    required String designation,
    required String employeeId,
    required String email,
    required String password,
    String? imageBase64,
    required String idNumber,
    required DateTime dateOfBirth,
    required String address,
    required String phoneNumber,
    required double salary,
  }) async {
    if (!isManager && !isOwner) {
      _setError('Only managers and owners can register managers');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _apiService.registerManager(
        name: name,
        designation: designation,
        employeeId: employeeId,
        email: email,
        password: password,
        imageBase64: imageBase64,
        idNumber: idNumber,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        salary: salary,
      );

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
    required String employeeId,
    required String email,
    required String password,
    String? imageBase64,
    required String idNumber,
    required DateTime dateOfBirth,
    required String address,
    required String phoneNumber,
    required double salary,
  }) async {
    if (!isManager && !isOwner) {
      _setError('Only managers and owners can register sales persons');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _apiService.registerSalesPerson(
        name: name,
        designation: designation,
        employeeId: employeeId,
        email: email,
        password: password,
        imageBase64: imageBase64,
        idNumber: idNumber,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        salary: salary,
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

  // Get all users for the shop
  Future<List<dynamic>> getShopUsers() async {
    _setLoading(true);
    _clearError();

    try {
      final users = await _apiService.getShopUsers();
      return users;
    } catch (e) {
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Delete a user (for owner)
  Future<bool> deleteUser(String userId) async {
    if (!isOwner) {
      _setError('Only owners can delete users');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _apiService.deleteUser(userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

