// // // import 'package:flutter/material.dart';
// // // import '../models/user.dart';
// // // import '../services/api_service.dart';
// // //
// // // class AuthProvider extends ChangeNotifier {
// // //   final ApiService _apiService = ApiService();
// // //   User? _user;
// // //   bool _isLoading = false;
// // //   String? _errorMessage;
// // //
// // //   User? get user => _user;
// // //   bool get isLoading => _isLoading;
// // //   String? get errorMessage => _errorMessage;
// // //   bool get isLoggedIn => _user != null;
// // //   bool get isAdmin => _user?.role == 'admin';
// // //
// // //   // Initialize provider - check if user is already logged in
// // //   Future<void> initialize() async {
// // //     _setLoading(true);
// // //     try {
// // //       final isValid = await _apiService.verifyToken();
// // //       if (isValid) {
// // //         _user = await _apiService.getCurrentUser();
// // //       } else {
// // //         await _apiService.logout();
// // //         _user = null;
// // //       }
// // //     } catch (e) {
// // //       _setError(e.toString());
// // //     } finally {
// // //       _setLoading(false);
// // //     }
// // //   }
// // //
// // //   // Register a shop and admin user
// // //   Future<String?> registerShop({
// // //     required String name,
// // //     required String address,
// // //     required String ownerName,
// // //     required String licenseNumber,
// // //     required String email,
// // //     required String password,
// // //     required String confirmPassword,
// // //   }) async {
// // //     _setLoading(true);
// // //     _clearError();
// // //
// // //     try {
// // //       final result = await _apiService.registerShop(
// // //         name: name,
// // //         address: address,
// // //         ownerName: ownerName,
// // //         licenseNumber: licenseNumber,
// // //         email: email,
// // //         password: password,
// // //         confirmPassword: confirmPassword,
// // //       );
// // //
// // //       return result['shop_id'];
// // //     } catch (e) {
// // //       _setError(e.toString());
// // //       return null;
// // //     } finally {
// // //       _setLoading(false);
// // //     }
// // //   }
// // //
// // //   // Login user
// // //   Future<bool> login({
// // //     required String shopId,
// // //     required String email,
// // //     required String password,
// // //   }) async {
// // //     _setLoading(true);
// // //     _clearError();
// // //
// // //     try {
// // //       final result = await _apiService.login(
// // //         shopId: shopId,
// // //         email: email,
// // //         password: password,
// // //       );
// // //
// // //       _user = User.fromJson(result['user']);
// // //       notifyListeners();
// // //       return true;
// // //     } catch (e) {
// // //       _setError(e.toString());
// // //       return false;
// // //     } finally {
// // //       _setLoading(false);
// // //     }
// // //   }
// // //
// // //
// // //   // Register a sales person (for admin)
// // //   // Future<bool> registerSalesPerson({
// // //   //   required String name,
// // //   //   required String designation,
// // //   //   required String sellerId,
// // //   //   required String email,
// // //   //   required String password,
// // //   // }) async {
// // //   //   if (!isAdmin) {
// // //   //     _setError('Only admins can register sales persons');
// // //   //     return false;
// // //   //   }
// // //
// // //   Future<bool> registerSalesPerson({
// // //     required String name,
// // //     required String designation,
// // //     required String sellerId,
// // //     required String email,
// // //     required String password,
// // //   }) async {
// // //     // Change this line
// // //     if (user?.role != 'admin' && user?.role != 'owner') {
// // //       _setError('Only admins and owners can register sales persons');
// // //       return false;
// // //     }
// // //
// // //
// // //
// // //
// // //
// // //     _setLoading(true);
// // //     _clearError();
// // //
// // //     try {
// // //       await _apiService.registerSalesPerson(
// // //         name: name,
// // //         designation: designation,
// // //         sellerId: sellerId,
// // //         email: email,
// // //         password: password,
// // //       );
// // //
// // //       return true;
// // //     } catch (e) {
// // //       _setError(e.toString());
// // //       return false;
// // //     } finally {
// // //       _setLoading(false);
// // //     }
// // //   }
// // //
// // //   // Register another admin (for admin)
// // //   Future<bool> registerAdmin({
// // //     required String name,
// // //     required String email,
// // //     required String password,
// // //   }) async {
// // //     if (!isAdmin) {
// // //       _setError('Only admins can register other admins');
// // //       return false;
// // //     }
// // //
// // //     _setLoading(true);
// // //     _clearError();
// // //
// // //     try {
// // //       await _apiService.registerAdmin(
// // //         name: name,
// // //         email: email,
// // //         password: password,
// // //       );
// // //
// // //       return true;
// // //     } catch (e) {
// // //       _setError(e.toString());
// // //       return false;
// // //     } finally {
// // //       _setLoading(false);
// // //     }
// // //   }
// // //
// // //   // Logout user
// // //   Future<void> logout() async {
// // //     _setLoading(true);
// // //     try {
// // //       await _apiService.logout();
// // //       _user = null;
// // //     } catch (e) {
// // //       _setError(e.toString());
// // //     } finally {
// // //       _setLoading(false);
// // //     }
// // //   }
// // //
// // //   // Set loading state
// // //   void _setLoading(bool loading) {
// // //     _isLoading = loading;
// // //     notifyListeners();
// // //   }
// // //
// // //   // Set error message
// // //   void _setError(String error) {
// // //     _errorMessage = error;
// // //     notifyListeners();
// // //   }
// // //
// // //   // Clear error message
// // //   void _clearError() {
// // //     _errorMessage = null;
// // //     notifyListeners();
// // //   }
// // // }
// // //
// //
// //
// //
// //
// //
// //
// //
// // import 'package:flutter/material.dart';
// // import '../models/user.dart';
// // import '../services/api_service.dart';
// //
// // class AuthProvider extends ChangeNotifier {
// //   final ApiService _apiService = ApiService();
// //   User? _user;
// //   bool _isLoading = false;
// //   String? _errorMessage;
// //
// //   User? get user => _user;
// //   bool get isLoading => _isLoading;
// //   String? get errorMessage => _errorMessage;
// //   bool get isLoggedIn => _user != null;
// //   bool get isAdmin => _user?.role == 'admin';
// //   bool get isOwner => _user?.role == 'owner';  // Added new getter for owner check
// //
// //   // Initialize provider - check if user is already logged in
// //   Future<void> initialize() async {
// //     _setLoading(true);
// //     try {
// //       final isValid = await _apiService.verifyToken();
// //       if (isValid) {
// //         _user = await _apiService.getCurrentUser();
// //         print('User initialized with role: ${_user?.role}');  // Debug print
// //       } else {
// //         await _apiService.logout();
// //         _user = null;
// //       }
// //     } catch (e) {
// //       _setError(e.toString());
// //     } finally {
// //       _setLoading(false);
// //     }
// //   }
// //
// //   // Register a shop and admin user
// //   Future<String?> registerShop({
// //     required String name,
// //     required String address,
// //     required String ownerName,
// //     required String licenseNumber,
// //     required String email,
// //     required String password,
// //     required String confirmPassword,
// //   }) async {
// //     _setLoading(true);
// //     _clearError();
// //     try {
// //       final result = await _apiService.registerShop(
// //         name: name,
// //         address: address,
// //         ownerName: ownerName,
// //         licenseNumber: licenseNumber,
// //         email: email,
// //         password: password,
// //         confirmPassword: confirmPassword,
// //       );
// //       return result['shop_id'];
// //     } catch (e) {
// //       _setError(e.toString());
// //       return null;
// //     } finally {
// //       _setLoading(false);
// //     }
// //   }
// //
// //   // Login user
// //   Future<bool> login({
// //     required String shopId,
// //     required String email,
// //     required String password,
// //   }) async {
// //     _setLoading(true);
// //     _clearError();
// //     try {
// //       final result = await _apiService.login(
// //         shopId: shopId,
// //         email: email,
// //         password: password,
// //       );
// //       _user = User.fromJson(result['user']);
// //       print('Logged in user role: ${_user?.role}');  // Debug print
// //       notifyListeners();
// //       return true;
// //     } catch (e) {
// //       _setError(e.toString());
// //       return false;
// //     } finally {
// //       _setLoading(false);
// //     }
// //   }
// //
// //   // Register a sales person (for admin or owner)
// //   Future<bool> registerSalesPerson({
// //     required String name,
// //     required String designation,
// //     required String sellerId,
// //     required String email,
// //     required String password,
// //   }) async {
// //     // UPDATED: Check for both admin and owner roles
// //     if (_user?.role != 'admin' && _user?.role != 'owner') {
// //       _setError('Only admins and owners can register sales persons');
// //       return false;
// //     }
// //
// //     _setLoading(true);
// //     _clearError();
// //     try {
// //       await _apiService.registerSalesPerson(
// //         name: name,
// //         designation: designation,
// //         sellerId: sellerId,
// //         email: email,
// //         password: password,
// //       );
// //       return true;
// //     } catch (e) {
// //       _setError(e.toString());
// //       return false;
// //     } finally {
// //       _setLoading(false);
// //     }
// //   }
// //
// //   // Register another admin (for admin or owner)
// //   Future<bool> registerAdmin({
// //     required String name,
// //     required String email,
// //     required String password,
// //   }) async {
// //     // UPDATED: Check for both admin and owner roles
// //     if (_user?.role != 'admin' && _user?.role != 'owner') {
// //       _setError('Only admins and owners can register other admins');
// //       return false;
// //     }
// //
// //     _setLoading(true);
// //     _clearError();
// //     try {
// //       await _apiService.registerAdmin(
// //         name: name,
// //         email: email,
// //         password: password,
// //       );
// //       return true;
// //     } catch (e) {
// //       _setError(e.toString());
// //       return false;
// //     } finally {
// //       _setLoading(false);
// //     }
// //   }
// //
// //   // Logout user
// //   Future<void> logout() async {
// //     _setLoading(true);
// //     try {
// //       await _apiService.logout();
// //       _user = null;
// //     } catch (e) {
// //       _setError(e.toString());
// //     } finally {
// //       _setLoading(false);
// //     }
// //   }
// //
// //   // Set loading state
// //   void _setLoading(bool loading) {
// //     _isLoading = loading;
// //     notifyListeners();
// //   }
// //
// //   // Set error message
// //   void _setError(String error) {
// //     _errorMessage = error;
// //     notifyListeners();
// //   }
// //
// //   // Clear error message
// //   void _clearError() {
// //     _errorMessage = null;
// //     notifyListeners();
// //   }
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// import 'dart:io';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../models/user.dart';
// import '../services/api_service.dart';
//
// class AuthProvider extends ChangeNotifier {
//   final ApiService _apiService = ApiService();
//   User? _user;
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   User? get user => _user;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   bool get isLoggedIn => _user != null;
//   bool get isAdmin => _user?.role == 'admin';
//   bool get isOwner => _user?.role == 'owner';  // Added new getter for owner check
//
//   // Initialize provider - check if user is already logged in
//   Future<void> initialize() async {
//     _setLoading(true);
//     try {
//       final isValid = await _apiService.verifyToken();
//       if (isValid) {
//         _user = await _apiService.getCurrentUser();
//         print('User initialized with role: ${_user?.role}');  // Debug print
//       } else {
//         await _apiService.logout();
//         _user = null;
//       }
//     } on SocketException {
//       _setError('Network error: Unable to connect to the server');
//       await _apiService.logout();
//       _user = null;
//     } on TimeoutException {
//       _setError('Network timeout: The server took too long to respond');
//       await _apiService.logout();
//       _user = null;
//     } catch (e) {
//       _setError(e.toString());
//       await _apiService.logout();
//       _user = null;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Register a shop and admin user
//   Future<String?> registerShop({
//     required String name,
//     required String address,
//     required String ownerName,
//     required String licenseNumber,
//     required String email,
//     required String password,
//     required String confirmPassword,
//   }) async {
//     _setLoading(true);
//     _clearError();
//     try {
//       final result = await _apiService.registerShop(
//         name: name,
//         address: address,
//         ownerName: ownerName,
//         licenseNumber: licenseNumber,
//         email: email,
//         password: password,
//         confirmPassword: confirmPassword,
//       );
//       return result['shop_id'];
//     } on SocketException {
//       _setError('Network error: Unable to connect to the server. Please check your internet connection.');
//       return null;
//     } on TimeoutException {
//       _setError('Network timeout: The server took too long to respond. Please try again later.');
//       return null;
//     } catch (e) {
//       _setError(e.toString());
//       return null;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Login user
//   Future<bool> login({
//     required String shopId,
//     required String email,
//     required String password,
//   }) async {
//     _setLoading(true);
//     _clearError();
//     try {
//       final result = await _apiService.login(
//         shopId: shopId,
//         email: email,
//         password: password,
//       );
//       _user = User.fromJson(result['user']);
//       print('Logged in user role: ${_user?.role}');  // Debug print
//       notifyListeners();
//       return true;
//     } on SocketException {
//       _setError('Network error: Unable to connect to the server. Please check your internet connection.');
//       return false;
//     } on TimeoutException {
//       _setError('Network timeout: The server took too long to respond. Please try again later.');
//       return false;
//     } catch (e) {
//       _setError(e.toString());
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Register a sales person (for admin or owner)
//   Future<bool> registerSalesPerson({
//     required String name,
//     required String designation,
//     required String sellerId,
//     required String email,
//     required String password,
//   }) async {
//     // UPDATED: Check for both admin and owner roles
//     if (_user?.role != 'admin' && _user?.role != 'owner') {
//       _setError('Only admins and owners can register sales persons');
//       return false;
//     }
//
//     _setLoading(true);
//     _clearError();
//     try {
//       await _apiService.registerSalesPerson(
//         name: name,
//         designation: designation,
//         sellerId: sellerId,
//         email: email,
//         password: password,
//       );
//       return true;
//     } on SocketException {
//       _setError('Network error: Unable to connect to the server. Please check your internet connection.');
//       return false;
//     } on TimeoutException {
//       _setError('Network timeout: The server took too long to respond. Please try again later.');
//       return false;
//     } catch (e) {
//       _setError(e.toString());
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Register another admin (for admin or owner)
//   Future<bool> registerAdmin({
//     required String name,
//     required String email,
//     required String password,
//   }) async {
//     // UPDATED: Check for both admin and owner roles
//     if (_user?.role != 'admin' && _user?.role != 'owner') {
//       _setError('Only admins and owners can register other admins');
//       return false;
//     }
//
//     _setLoading(true);
//     _clearError();
//     try {
//       await _apiService.registerAdmin(
//         name: name,
//         email: email,
//         password: password,
//       );
//       return true;
//     } on SocketException {
//       _setError('Network error: Unable to connect to the server. Please check your internet connection.');
//       return false;
//     } on TimeoutException {
//       _setError('Network timeout: The server took too long to respond. Please try again later.');
//       return false;
//     } catch (e) {
//       _setError(e.toString());
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Logout user
//   Future<void> logout() async {
//     _setLoading(true);
//     try {
//       await _apiService.logout();
//       _user = null;
//     } catch (e) {
//       _setError(e.toString());
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // Set loading state
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
//
//   // Set error message
//   void _setError(String error) {
//     _errorMessage = error;
//     notifyListeners();
//   }
//
//   // Clear error message
//   void _clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }
// }





import 'dart:io';
import 'dart:async';
import 'dart:convert';
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
  bool get isSeller => _user?.role == 'seller';

  // Initialize provider with enhanced debugging
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isValid = await _apiService.verifyToken();
      if (isValid) {
        // Get stored user data for debugging
        final rawUserData = await _apiService.getRawUserData();
        print('AuthProvider.initialize - Raw user data: $rawUserData');

        // Try to parse it directly
        if (rawUserData != null) {
          try {
            Map<String, dynamic> userData = jsonDecode(rawUserData);
            print('AuthProvider.initialize - Parsed user data:');
            userData.forEach((key, value) {
              print('  $key: $value');
            });
          } catch (e) {
            print('AuthProvider.initialize - Error parsing stored user data: $e');
          }
        }

        // Get the user through the API service
        _user = await _apiService.getCurrentUser();
        if (_user != null) {
          print('AuthProvider.initialize - User loaded successfully:');
          print('  Name: ${_user!.name}');
          print('  Role: ${_user!.role}');
          print('  Designation: ${_user!.designation}');
          print('  Seller ID: ${_user!.sellerId}');
        } else {
          print('AuthProvider.initialize - User object is null after getCurrentUser');
        }
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

  // Login user with enhanced error handling and debugging
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

      // Debug the user data structure
      print('AuthProvider.login - User data from login response:');
      if (result.containsKey('user')) {
        print('  User object structure: ${result['user']}');
      }

      // Create and store the user object
      _user = User.fromJson(result['user']);

      // Verify the user object was created properly
      print('AuthProvider.login - Created user object:');
      print('  Name: ${_user!.name}');
      print('  Role: ${_user!.role}');
      print('  Designation: ${_user!.designation}');
      print('  Seller ID: ${_user!.sellerId}');

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
    // UPDATED: Check for both admin and owner roles
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
    // UPDATED: Check for both admin and owner roles
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