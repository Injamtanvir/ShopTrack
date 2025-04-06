class ApiConstants {
  // Base URL - Production Render URL
  static const String baseUrl = 'https://shoptrack-w8wu.onrender.com/api';

  // For local development (comment out when using production)
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // For web/iOS

  // Existing endpoints
  static const String registerShop = '$baseUrl/register-shop/';
  static const String login = '$baseUrl/login/';
  static const String registerSalesPerson = '$baseUrl/register-sales-person/';
  static const String registerAdmin = '$baseUrl/register-admin/';
  static const String verifyToken = '$baseUrl/verify-token/';
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
}