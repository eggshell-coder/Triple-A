// lib/config/api_config.dart

class ApiConfig {
  // Inject API_BASE_URL at build time for staging/custom deployments.
  // Local development can still override this with --dart-define.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://triple-a-six.vercel.app/api',
  );

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
