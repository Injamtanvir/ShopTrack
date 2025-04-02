// class ApiConstants {
//   // Base URL - Production Render URL
//   static const String baseUrl = 'https://shoptrack-w8wu.onrender.com';
//
//   // For local development (comment out when using production)
//   // static const String baseUrl = 'http://10.0.2.2:8000/api'; // For Android emulator
//   // static const String baseUrl = 'http://localhost:8000/api'; // For web/iOS
//
//   // Endpoints
//   static const String registerShop = '$baseUrl/register-shop/';
//   static const String login = '$baseUrl/login/';
//   static const String registerSalesPerson = '$baseUrl/register-sales-person/';
//   static const String registerAdmin = '$baseUrl/register-admin/';
//   static const String verifyToken = '$baseUrl/verify-token/';
// }




class ApiConstants {
  // Base URL - Production Render URL
  static const String baseUrl = 'https://shoptrack-w8wu.onrender.com/api';

  // For local development (comment out when using production)
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // For web/iOS

  // Endpoints
  static const String registerShop = '$baseUrl/register-shop/';
  static const String login = '$baseUrl/login/';
  static const String registerSalesPerson = '$baseUrl/register-sales-person/';
  static const String registerAdmin = '$baseUrl/register-admin/';
  static const String verifyToken = '$baseUrl/verify-token/';
}