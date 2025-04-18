class ApiConstants {
  // Base URL--> Render URL
  static const String baseUrl = 'https://shoptrack-w8wu.onrender.com/api';

  // For local development (comment out when using production)
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; //Android

  // API Endpoints
  static const String registerShop = '$baseUrl/register-shop/';
  static const String login = '$baseUrl/login/';
  static const String registerSalesPerson = '$baseUrl/register-sales-person/';
  static const String registerAdmin = '$baseUrl/register-admin/';
  static const String verifyToken = '$baseUrl/verify-token/';
  static const String verifyEmail = '$baseUrl/verify-email/';
  static const String resendOtp = '$baseUrl/resend-otp/';
  static const String products = '$baseUrl/products/';
  static const String updateProductPrice = '$baseUrl/update-product-price/';
  static const String productPriceList = '$baseUrl/product-price-list/';
  static const String getNextInvoiceNumber = '$baseUrl/next-invoice-number/';
  static const String saveInvoice = '$baseUrl/invoices/';
  static const String generateInvoice = '$baseUrl/generate-invoice/';
  static const String getPendingInvoices = '$baseUrl/pending-invoices/';
  static const String getInvoiceHistory = '$baseUrl/invoice-history/';
  static const String getInvoice = '$baseUrl/invoice/';
  static const String searchProducts = '$baseUrl/search-products/';
  static const String deletePendingInvoice = '$baseUrl/delete-invoice/';
  static const String deleteProduct = '$baseUrl/delete-product/';
  static const String getTodayStats = '$baseUrl/today-stats/';
  static const String getTodayInvoices = '$baseUrl/today-invoices/';
  static const String getShopUsers = '$baseUrl/shop-users/';
  static const String shopUsers = '$baseUrl/shop/users/';
  static const String deleteUser = '$baseUrl/delete-user/';
  
  // Premium features
  static const String premiumStatus = '$baseUrl/premium/status/';
  static const String premiumSubscribe = '$baseUrl/premium/activate/';
  static const String rechargeHistory = '$baseUrl/premium/recharge-history/';
  static const String premiumSalesAnalytics = '$baseUrl/premium/analytics/sales/';
  static const String productProfitAnalytics = '$baseUrl/premium/analytics/products/';
  
  // Branch management
  static const String branches = '$baseUrl/branches/';
  static const String createBranch = '$baseUrl/branches/create/';
  static const String assignUserToBranch = '$baseUrl/branches/assign-user/';
  
  // Returned products
  static const String returnProduct = '$baseUrl/products/return/';
  static const String returnedProducts = '$baseUrl/products/returned/';
  
  // Shop settings
  static const String shopSettings = '$baseUrl/shop/settings/';
  static const String uploadShopLogo = '$baseUrl/shop/upload-logo/';
}