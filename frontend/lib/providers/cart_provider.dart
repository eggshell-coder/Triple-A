// lib/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = [...state];
      final existing = updated[existingIndex];
      final newQty = existing.quantity + quantity;
      if (newQty <= product.stock) {
        updated[existingIndex] = CartItem(product: product, quantity: newQty);
        state = updated;
      }
    } else {
      state = [...state, CartItem(product: product, quantity: quantity)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state.map((item) {
      if (item.product.id == productId) {
        return CartItem(product: item.product, quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

// Auth provider
class AuthNotifier extends StateNotifier<Map<String, dynamic>?> {
  AuthNotifier() : super(null);

  void login(Map<String, dynamic> user) => state = user;
  void logout() => state = null;
  bool get isLoggedIn => state != null;
}

final authProvider = StateNotifierProvider<AuthNotifier, Map<String, dynamic>?>(
  (ref) => AuthNotifier(),
);
