import 'dart:io';
import 'dart:async';
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
  bool get isOwner => _user?.role == 'owner';

  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isValid = await _apiService.verifyToken();
      if (isValid) {
        _user = await _apiService.getCurrentUser();
        // print('User initialized with role: ${_user?.role}');
      } else {
        await _apiService.logout();
        _user = null;
      }
    } on SocketException {
      _setError('Network error: Unable to connect to the server');
      await _apiService.logout();
      _user = null;
    } on TimeoutException {
      _setError('Network timeout: The server took too long to respond');
      await _apiService.logout();
      _user = null;
    } catch (e) {
      _setError(e.toString());
      await _apiService.logout();
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

// Register
  Future<String?> registerShop({
    required String name,
    required String address,
    required String ownerName,
    required String licenseNumber,
    required String email,
    required String password,
    required String confirmPassword,
    required String mobileNumber,
    required String nidNumber,
    String? ownerPhotoPath,
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
        mobileNumber: mobileNumber,
        nidNumber: nidNumber,
        ownerPhotoPath: ownerPhotoPath,
      );
      return result['shop_id'];
    } on SocketException {
      _setError('Network error: Unable to connect to the server. Please check your internet connection.');
      return null;
    } on TimeoutException {
      _setError('Network timeout: The server took too long to respond. Please try again later.');
      return null;
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
      // print('Logged in user role: ${_user?.role}');
      notifyListeners();
      return true;
    } on SocketException {
      _setError('Network error: Unable to connect to the server. Please check your internet connection.');
      return false;
    } on TimeoutException {
      _setError('Network timeout: The server took too long to respond. Please try again later.');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register a sales person (for admin or owner)
  Future<bool> registerSalesPerson({
    required String name,
    required String designation,
    required String sellerId,
    required String email,
    required String password,
  }) async {
    if (_user?.role != 'admin' && _user?.role != 'owner') {
      _setError('Only admins and owners can register sales persons');
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
    } on SocketException {
      _setError('Network error: Unable to connect to the server. Please check your internet connection.');
      return false;
    } on TimeoutException {
      _setError('Network timeout: The server took too long to respond. Please try again later.');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register another admin (for admin or owner)
  Future<bool> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_user?.role != 'admin' && _user?.role != 'owner') {
      _setError('Only admins and owners can register other admins');
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
    } on SocketException {
      _setError('Network error: Unable to connect to the server. Please check your internet connection.');
      return false;
    } on TimeoutException {
      _setError('Network timeout: The server took too long to respond. Please try again later.');
      return false;
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
