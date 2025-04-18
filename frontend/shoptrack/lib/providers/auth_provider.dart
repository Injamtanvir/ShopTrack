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
  bool get isPremium => _user?.isPremium ?? false;

  // Premium related getters and methods
  String? get branchId => _user?.branchId;
  bool get hasBranch => _user?.branchId != null;

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

  // Verify Email OTP
  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.verifyEmail(
        email: email,
        otp: otp,
      );
      return result['message'] != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Resend OTP
  Future<bool> resendOtp({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.resendOtp(
        email: email,
      );
      return result['message'] != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get premium status details
  Future<Map<String, dynamic>?> getPremiumStatus() async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return null;
    }
    
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.getPremiumStatus(
        shopId: _user!.shopId,
      );
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Subscribe to premium with simplified transaction handling
  Future<bool> subscribeToPremium({
    required String transactionId,
  }) async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    try {
      // Simple transaction validation
      final result = await _apiService.subscribeToPremium(
        transactionId: transactionId,
      );
      
      if (result['is_premium'] == true) {
        // Update user with premium status
        if (_user != null) {
          _user = User(
            id: _user!.id,
            shopId: _user!.shopId,
            name: _user!.name,
            email: _user!.email,
            role: _user!.role,
            designation: _user!.designation,
            sellerId: _user!.sellerId,
            shopName: _user!.shopName,
            isPremium: true,
            branchId: _user!.branchId,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get recharge history
  Future<List<dynamic>?> getRechargeHistory() async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return null;
    }
    
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.getRechargeHistory(
        shopId: _user!.shopId,
      );
      return result is List ? result : [];
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get shop branches
  Future<List<dynamic>?> getShopBranches() async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return null;
    }
    
    if (!isPremium) {
      _setError('Premium subscription required');
      return null;
    }
    
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.getShopBranches(
        shopId: _user!.shopId,
      );
      return result is List ? result : [];
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Create branch
  Future<Map<String, dynamic>?> createBranch({
    required String name,
    required String address,
    String? managerEmail,
  }) async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return null;
    }
    
    if (!isPremium) {
      _setError('Premium subscription required');
      return null;
    }
    
    if (!isOwner) {
      _setError('Only shop owners can create branches');
      return null;
    }
    
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.createBranch(
        name: name,
        address: address,
        managerEmail: managerEmail,
      );
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Assign user to branch
  Future<bool> assignUserToBranch({
    required String userEmail,
    required String branchId,
  }) async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return false;
    }
    
    if (!isPremium) {
      _setError('Premium subscription required');
      return false;
    }
    
    if (!isOwner && !isAdmin) {
      _setError('Only shop owners and admins can assign users to branches');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.assignUserToBranch(
        userEmail: userEmail,
        branchId: branchId,
      );
      return result['message'] != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Upload shop logo
  Future<bool> uploadShopLogo({
    required String logoUrl,
  }) async {
    if (!isLoggedIn || !_user!.shopId.isNotEmpty) {
      _setError('User not logged in');
      return false;
    }
    
    if (!isPremium) {
      _setError('Premium subscription required');
      return false;
    }
    
    if (!isOwner) {
      _setError('Only shop owners can upload shop logo');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    try {
      final result = await _apiService.uploadShopLogo(
        shopId: _user!.shopId,
        logoUrl: logoUrl,
      );
      return result['message'] != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
