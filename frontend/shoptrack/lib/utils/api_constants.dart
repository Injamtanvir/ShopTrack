class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://shoptrack-api.onrender.com/api';
  
  // Authentication endpoints
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String registerSalesperson = '$baseUrl/auth/register-salesperson/';
  static const String registerAdmin = '$baseUrl/auth/register-admin/';
  static const String verifyEmail = '$baseUrl/auth/verify-email/';
  static const String verifyToken = '$baseUrl/auth/verify-token/';
  static const String resendOtp = '$baseUrl/auth/resend-otp/';
  
  // Product endpoints
  static const String products = '$baseUrl/products/';
  static const String addProduct = '$baseUrl/products/add/';
  static const String deleteProduct = '$baseUrl/products/delete/';
  static const String updateProductPrice = '$baseUrl/products/update-price/';
  
  // Invoice endpoints
  static const String invoices = '$baseUrl/invoices/';
  static const String createInvoice = '$baseUrl/invoices/create/';
  static const String pendingInvoices = '$baseUrl/invoices/pending/';
  
  // User management
  static const String shopUsers = '$baseUrl/shop/users/';
  static const String deleteUser = '$baseUrl/shop/delete-user/';
  static const String userStats = '$baseUrl/shop/user-stats/';
  
  // Premium status and subscription
  static const String premiumStatus = '$baseUrl/premium/status/';
  static const String premiumSubscribe = '$baseUrl/premium/subscribe/';
  static const String rechargeHistory = '$baseUrl/premium/recharge-history/';
  
  // Branch management
  static const String branches = '$baseUrl/branches/';
  static const String createBranch = '$baseUrl/branches/create/';
  static const String assignUserToBranch = '$baseUrl/branches/assign-user/';
  
  // Returned products
  static const String returnProduct = '$baseUrl/products/return/';
  static const String returnedProducts = '$baseUrl/products/returned/';
  
  // Premium analytics
  static const String premiumSalesAnalytics = '$baseUrl/premium/analytics/sales/';
  static const String productProfitAnalytics = '$baseUrl/premium/analytics/products/';
  
  // Shop settings
  static const String shopSettings = '$baseUrl/shop/settings/';
  static const String uploadShopLogo = '$baseUrl/shop/upload-logo/';
}