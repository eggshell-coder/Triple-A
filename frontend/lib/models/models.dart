// lib/models/models.dart
class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? size;
  final String? color;
  final String? imageUrl;
  final bool isActive;
  final String? categoryId;
  final Map<String, dynamic>? category;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.size,
    this.color,
    this.imageUrl,
    this.isActive = true,
    this.categoryId,
    this.category,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        price: (json['price'] ?? 0).toDouble(),
        stock: json['stock'] ?? 0,
        size: json['size'],
        color: json['color'],
        imageUrl: json['image_url'],
        isActive: json['is_active'] ?? true,
        categoryId: json['category_id'],
        category: json['categories'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'size': size,
        'color': color,
        'image_url': imageUrl,
        'category_id': categoryId,
        'is_active': isActive,
      };

  String get categoryName => category?['name'] ?? 'Uncategorized';
  bool get inStock => stock > 0;
}

class Category {
  final String id;
  final String name;
  const Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'] ?? '', name: json['name'] ?? '');
}

class Order {
  final String id;
  final double totalAmount;
  final double deliveryCharge;
  final String? district;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final Map<String, dynamic>? customer;
  final List<dynamic>? items;

  const Order({
    required this.id,
    required this.totalAmount,
    this.deliveryCharge = 0,
    this.district,
    required this.status,
    this.note,
    this.createdAt,
    this.customer,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] ?? '',
        totalAmount: (json['total_amount'] ?? 0).toDouble(),
        deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
        district: json['district'],
        status: json['status'] ?? 'pending',
        note: json['note'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        customer: json['customers'],
        items: json['order_items'],
      );

  String get customerName => customer?['full_name'] ?? 'Unknown';
  String get customerPhone => customer?['phone'] ?? '';
  String get customerAddress => customer?['address'] ?? '';
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Convenience getters used by checkout_screen and other screens
  String get productId => product.id;
  String get name      => product.name;
  double get price     => product.price;

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toOrderItem() => {
        'product_id': product.id,
        'quantity': quantity,
      };
}

class DashboardStats {
  final int totalProducts;
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final List<dynamic> recentOrders;
  final List<dynamic> lowStockProducts;

  const DashboardStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.recentOrders,
    required this.lowStockProducts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      DashboardStats(
        totalProducts: json['total_products'] ?? 0,
        totalOrders: json['total_orders'] ?? 0,
        pendingOrders: json['pending_orders'] ?? 0,
        processingOrders: json['processing_orders'] ?? 0,
        completedOrders: json['completed_orders'] ?? 0,
        cancelledOrders: json['cancelled_orders'] ?? 0,
        totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
        recentOrders: json['recent_orders'] ?? [],
        lowStockProducts: json['low_stock_products'] ?? [],
      );
}