// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class UserState {
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  const UserState({this.token, this.refreshToken, this.user});

  bool get isLoggedIn => token != null && user != null;
  String get name => user?['full_name'] ?? user?['email'] ?? '';
  String get email => user?['email'] ?? '';
  String? get userId => user?['id']?.toString();

  UserState copyWith({String? token, String? refreshToken, Map<String, dynamic>? user}) =>
      UserState(
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
        user: user ?? this.user,
      );
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('customer_token');
      final refreshToken = prefs.getString('customer_refresh_token');
      final userStr = prefs.getString('customer_user');
      if (token != null && userStr != null) {
        state = UserState(
          token: token,
          refreshToken: refreshToken,
          user: jsonDecode(userStr) as Map<String, dynamic>,
        );
        // ← Critical: sync to apiService so _userHeaders are populated
        // after a page refresh (apiService is a fresh singleton each run)
        apiService.setUserToken(token, refreshToken: refreshToken);
      }
    } catch (_) {}
  }

  Future<void> login(
    String token,
    Map<String, dynamic> user, {
    String? refreshToken,
  }) async {
    state = UserState(token: token, refreshToken: refreshToken, user: user);
    // Keep apiService in sync so API calls work immediately after login
    apiService.setUserToken(token, refreshToken: refreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_token', token);
    await prefs.setString('customer_user', jsonEncode(user));
    if (refreshToken != null) {
      await prefs.setString('customer_refresh_token', refreshToken);
    }
  }

  Future<void> logout() async {
    state = const UserState();
    apiService.clearUserToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customer_token');
    await prefs.remove('customer_refresh_token');
    await prefs.remove('customer_user');
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
