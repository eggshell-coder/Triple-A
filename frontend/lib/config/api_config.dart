// lib/config/api_config.dart

class ApiConfig {
  // Backend runs on port 5000 via .env, routes mounted under /api
  static const String baseUrl = 'https://triple-a-gkpq.onrender.com/api';

  // Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String products = '$baseUrl/products';
  static const String productsAdmin = '$baseUrl/products/admin/all';
  static const String categories = '$baseUrl/categories';
  static const String orders = '$baseUrl/orders';
  static const String dashboard = '$baseUrl/dashboard/stats';
  static const String upload = '$baseUrl/upload';

  static String productById(String id) => '$baseUrl/products/$id';
  static String orderById(String id) => '$baseUrl/orders/$id';
  static String updateOrderStatus(String id) => '$baseUrl/orders/$id/status';
}
