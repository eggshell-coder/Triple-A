// lib/config/api_config.dart

class ApiConfig {
  // Injected at build time so the same source deploys to staging or
  // production without a code change:
  //
  //   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api
  //   flutter build web --dart-define=API_BASE_URL=https://api.example.com/api
  //
  // The fallback below is the local dev default, used when the define is
  // absent (e.g. a plain `flutter run`).
  static const String _baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api');

  // Backend runs on port 5000 via .env, routes mounted under /api
  static const String baseUrl = _baseUrl;

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
