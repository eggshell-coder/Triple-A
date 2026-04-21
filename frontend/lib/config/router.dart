// lib/config/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/customer/home_screen.dart';
import '../screens/customer/product_list_screen.dart';
import '../screens/customer/shop_categories_screen.dart';
import '../screens/customer/product_detail_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/order_confirm_screen.dart';
import '../screens/customer/collection_products_screen.dart';
import '../screens/customer/about_screen.dart';
import '../screens/customer/order_tracking_screen.dart';
import '../screens/customer/login_screen.dart';
import '../screens/customer/signup_screen.dart';
import '../screens/customer/my_orders_screen.dart';
import '../screens/customer/wishlist_screen.dart';
import '../screens/our_story_screen.dart';

import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/product_management_screen.dart';
import '../screens/admin/collection_management_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/admin_wishlist_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',

    onException: (context, state, router) {
      router.go('/login');
    },

    routes: [
      // ── Customer ──────────────────────────────────────────────────────
      GoRoute(path: '/',     builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/shop', builder: (_, __) => const ShopCategoriesScreen()),

      GoRoute(
        path: '/products',
        builder: (_, state) => ProductListScreen(
          initialCategoryId:   state.uri.queryParameters['category_id'],
          initialCategoryName: state.uri.queryParameters['category_name'] != null
              ? Uri.decodeComponent(state.uri.queryParameters['category_name']!)
              : null,
          initialGender: state.uri.queryParameters['gender'],
          initialType:   state.uri.queryParameters['type'],
        ),
      ),

      GoRoute(
        path: '/products/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      GoRoute(path: '/cart',     builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),

      GoRoute(
        path: '/order-success/:orderId',
        builder: (_, state) => OrderConfirmScreen(
          orderId:           state.pathParameters['orderId']!,
          estimatedDelivery: state.uri.queryParameters['est'],
        ),
      ),

      GoRoute(
        path: '/collections/:slug',
        builder: (_, state) =>
            CollectionProductsScreen(slug: state.pathParameters['slug']!),
      ),

      GoRoute(path: '/about',     builder: (_, __) => const OurStoryScreen()),
      GoRoute(path: '/our-story', builder: (_, __) => const OurStoryScreen()),
      GoRoute(path: '/track-order', builder: (_, __) => const OrderTrackingScreen()),
      GoRoute(path: '/wishlist',    builder: (_, __) => const WishlistScreen()),

      // ── Customer Auth ─────────────────────────────────────────────────
      GoRoute(path: '/login',     builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',    builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/my-orders', builder: (_, __) => const MyOrdersScreen()),

      // ── Admin ─────────────────────────────────────────────────────────
      GoRoute(path: '/admin/login',        builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard',    builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/products',     builder: (_, __) => const ProductManagementScreen()),
      GoRoute(path: '/admin/collections',  builder: (_, __) => const CollectionManagementScreen()),
      GoRoute(path: '/admin/orders',       builder: (_, __) => const OrderManagementScreen()),
      GoRoute(path: '/admin/wishlist',     builder: (_, __) => const AdminWishlistScreen()),
    ],
  );
});