// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  String? _token;
  String? _refreshToken;
  String? _userToken;

  // ─── Admin token management ──────────────────────────────────────────────

  void setToken(String token, {String? refreshToken}) {
    _token = token;
    SharedPreferences.getInstance().then((p) {
      p.setString('admin_token', token);
      if (refreshToken != null) p.setString('admin_refresh_token', refreshToken);
    });
  }

  void clearToken() {
    _token = null;
    _refreshToken = null;
    SharedPreferences.getInstance().then((p) {
      p.remove('admin_token');
      p.remove('admin_refresh_token');
    });
  }

  bool get isAuthenticated => _token != null;

  /// Call once at app startup to restore persisted admin tokens.
  Future<void> restoreAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
    _refreshToken = prefs.getString('admin_refresh_token');
  }

  // ─── Silent token refresh ────────────────────────────────────────────────

  Future<bool> _refreshAdminSession() async {
    final rt = _refreshToken;
    if (rt == null) return false;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/admin/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        _token = data['token'] as String;
        _refreshToken = data['refresh_token'] as String?;
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('admin_token', _token!);
        if (_refreshToken != null) {
          prefs.setString('admin_refresh_token', _refreshToken!);
        }
        return true;
      }
    } catch (_) {}

    return false;
  }

  // ─── Admin-authenticated request wrapper ─────────────────────────────────

  /// Runs [request]; if 401, silently refreshes once and retries.
  Future<http.Response> _adminRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = _adminHeaders;
    var res = await request(headers);

    if (res.statusCode == 401) {
      final refreshed = await _refreshAdminSession();
      if (refreshed) {
        headers = _adminHeaders;
        res = await request(headers);
      }
    }

    return res;
  }

  // ─── Customer token management ───────────────────────────────────────────

  void setUserToken(String token) => _userToken = token;
  void clearUserToken() => _userToken = null;

  // ─── Headers ────────────────────────────────────────────────────────────

  Map<String, String> get _adminHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get _userHeaders => {
        'Content-Type': 'application/json',
        if (_userToken != null) 'Authorization': 'Bearer $_userToken',
      };

  // ─── Response handler ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException(
          'Invalid server response',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      body['message']?.toString() ??
          body['error']?.toString() ??
          'Request failed',
      statusCode: response.statusCode,
    );
  }

  // ─── Image Upload ────────────────────────────────────────────────────────

  Future<String> uploadProductImage(List<int> fileBytes, String fileName) async {
    final uri = Uri.parse(ApiConfig.upload);

    Future<http.StreamedResponse> doUpload(String? token) async {
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      String mimeType = 'image/jpeg';
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'png') mimeType = 'image/png';
      if (ext == 'webp') mimeType = 'image/webp';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
      return request.send();
    }

    var streamed = await doUpload(_token);
    var response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      final refreshed = await _refreshAdminSession();
      if (refreshed) {
        streamed = await doUpload(_token);
        response = await http.Response.fromStream(streamed);
      }
    }

    final data = await _handleResponse(response);
    return data['data']['url'] as String;
  }

  // ─── Admin Auth ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = await _handleResponse(res);
    final token = data['data']['token'] as String;
    final refreshToken = data['data']['refresh_token'] as String?;
    _refreshToken = refreshToken;
    setToken(token, refreshToken: refreshToken);
    return data['data'];
  }

  // ─── Customer Auth ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> customerSignup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/customer/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );

    final data = await _handleResponse(res);
    if (data['data'] != null && data['data']['token'] != null) {
      setUserToken(data['data']['token'] as String);
    }
    return data['data'];
  }

  Future<Map<String, dynamic>> customerLogin({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/customer/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = await _handleResponse(res);
    setUserToken(data['data']['token'] as String);
    return data['data'];
  }

  // ─── My Orders ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getMyOrders() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/customer/my-orders'),
      headers: _userHeaders,
    );

    final data = await _handleResponse(res);
    return (data['data'] as List<dynamic>?) ?? [];
  }

  // ─── Products (public) ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProducts({
    String? search,
    String? categoryId,
    String? gender,
    String? type,
    String? collectionSlug,
    double? minPrice,
    double? maxPrice,
    int page = 1,
  }) async {
    final params = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (gender != null) 'gender': gender,
      if (type != null) 'type': type,
      if (collectionSlug != null) 'collection_slug': collectionSlug,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };

    final res = await http.get(
      Uri.parse(ApiConfig.products).replace(queryParameters: params),
      headers: {'Content-Type': 'application/json'},
    );

    return _handleResponse(res);
  }

  Future<List<dynamic>> getFeaturedProducts() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/featured'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = await _handleResponse(res);
    if (data['data'] != null) return data['data'] as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>> getProductById(String id) async {
    final res = await http.get(
      Uri.parse(ApiConfig.productById(id)),
      headers: {'Content-Type': 'application/json'},
    );
    return _handleResponse(res);
  }

  // ─── Products (admin) ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAllProductsAdmin() async {
    final res = await _adminRequest(
      (h) => http.get(Uri.parse(ApiConfig.productsAdmin), headers: h),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _adminRequest(
      (h) => http.post(
        Uri.parse(ApiConfig.products),
        headers: h,
        body: jsonEncode(data),
      ),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _adminRequest(
      (h) => http.put(
        Uri.parse(ApiConfig.productById(id)),
        headers: h,
        body: jsonEncode(data),
      ),
    );
    return _handleResponse(res);
  }

  Future<void> deleteProduct(String id) async {
    final res = await _adminRequest(
      (h) => http.delete(Uri.parse(ApiConfig.productById(id)), headers: h),
    );
    await _handleResponse(res);
  }

  // ─── Categories (public) ─────────────────────────────────────────────────

  Future<List<dynamic>> getCategories() async {
    final res = await http.get(
      Uri.parse(ApiConfig.categories),
      headers: {'Content-Type': 'application/json'},
    );
    final data = await _handleResponse(res);
    return data['data'] as List<dynamic>;
  }

  // ─── Categories (admin) ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> createCategory(String name) async {
    final res = await _adminRequest(
      (h) => http.post(
        Uri.parse(ApiConfig.categories),
        headers: h,
        body: jsonEncode({'name': name}),
      ),
    );
    return _handleResponse(res);
  }

  Future<List<dynamic>> getAllCategoriesAdmin() async {
    final res = await _adminRequest(
      (h) => http.get(
        Uri.parse('${ApiConfig.baseUrl}/categories/admin/all'),
        headers: h,
      ),
    );
    final data = await _handleResponse(res);
    return data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> updates) async {
    final res = await _adminRequest(
      (h) => http.patch(
        Uri.parse('${ApiConfig.baseUrl}/categories/$id'),
        headers: h,
        body: jsonEncode(updates),
      ),
    );
    return _handleResponse(res);
  }

  Future<void> deleteCategory(String id) async {
    final res = await _adminRequest(
      (h) => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/categories/$id'),
        headers: h,
      ),
    );
    await _handleResponse(res);
  }

  // ─── Orders ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
    String? note,
    String? district,
    String? upazila,
    double deliveryCharge = 0,
    String? userId,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.orders),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customer': customer,
        'items': items,
        'note': note,
        'district': district,
        'upazila': upazila,
        'delivery_charge': deliveryCharge,
        'user_id': userId,
      }),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.orders}/track/$orderId'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = await _handleResponse(res);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductOrdersSummary() async {
    final res = await _adminRequest(
      (h) => http.get(
        Uri.parse('${ApiConfig.orders}/product-summary'),
        headers: h,
      ),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getOrders({
    String? status,
    int page = 1,
  }) async {
    final params = {
      'page': page.toString(),
      if (status != null && status != 'all') 'status': status,
    };
    final res = await _adminRequest(
      (h) => http.get(
        Uri.parse(ApiConfig.orders).replace(queryParameters: params),
        headers: h,
      ),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getOrderById(String id) async {
    final res = await _adminRequest(
      (h) => http.get(Uri.parse(ApiConfig.orderById(id)), headers: h),
    );
    return _handleResponse(res);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final res = await _adminRequest(
      (h) => http.patch(
        Uri.parse(ApiConfig.updateOrderStatus(id)),
        headers: h,
        body: jsonEncode({'status': status}),
      ),
    );
    await _handleResponse(res);
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _adminRequest(
      (h) => http.get(Uri.parse(ApiConfig.dashboard), headers: h),
    );
    return _handleResponse(res);
  }

  // ─── Collections (public) ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCollections() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/collections'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = await _handleResponse(res);
    if (data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getCollectionProducts(String slug) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/collections/$slug/products'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = await _handleResponse(res);
    if (data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  // ─── Collections (admin) ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCollectionsAdmin() async {
    final res = await _adminRequest(
      (h) => http.get(
        Uri.parse('${ApiConfig.baseUrl}/collections/admin/all'),
        headers: h,
      ),
    );
    final data = await _handleResponse(res);
    if (data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createCollection(
      Map<String, dynamic> data) async {
    final res = await _adminRequest(
      (h) => http.post(
        Uri.parse('${ApiConfig.baseUrl}/collections'),
        headers: h,
        body: jsonEncode(data),
      ),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateCollection(
      String id, Map<String, dynamic> data) async {
    final res = await _adminRequest(
      (h) => http.patch(
        Uri.parse('${ApiConfig.baseUrl}/collections/$id'),
        headers: h,
        body: jsonEncode(data),
      ),
    );
    return _handleResponse(res);
  }

  Future<void> deleteCollection(String id) async {
    final res = await _adminRequest(
      (h) => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/collections/$id'),
        headers: h,
      ),
    );
    await _handleResponse(res);
  }

  // ─── Wishlist (customer) ─────────────────────────────────────────────────

  Future<bool> toggleWishlist(String productId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/wishlist/toggle'),
      headers: _userHeaders,
      body: jsonEncode({'product_id': productId}),
    );
    final data = await _handleResponse(res);
    return data['wishlisted'] as bool;
  }

  Future<bool> checkWishlist(String productId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/wishlist/check/$productId'),
      headers: _userHeaders,
    );
    final data = await _handleResponse(res);
    return data['wishlisted'] as bool;
  }

  Future<List<dynamic>> getMyWishlist() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/wishlist/my'),
      headers: _userHeaders,
    );
    final data = await _handleResponse(res);
    if (data['data'] != null) return data['data'] as List<dynamic>;
    return [];
  }

  // ─── Wishlist (admin) ────────────────────────────────────────────────────

  Future<List<dynamic>> getWishlistSummaryAdmin() async {
    final res = await _adminRequest(
      (h) => http.get(
        Uri.parse('${ApiConfig.baseUrl}/wishlist/admin/summary'),
        headers: h,
      ),
    );
    final data = await _handleResponse(res);
    if (data['data'] != null) return data['data'] as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>> getWishlistersForProduct(
      String productId) async {
    final res = await _adminRequest(
      (h) => http.get(
        Uri.parse('${ApiConfig.baseUrl}/wishlist/admin/product/$productId'),
        headers: h,
      ),
    );
    return _handleResponse(res);
  }
}

final apiService = ApiService();