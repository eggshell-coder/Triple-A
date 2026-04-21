// lib/widgets/admin_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class AdminSidebar extends ConsumerWidget {
  final String activePath;
  const AdminSidebar({super.key, required this.activePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Container(
      width: 240,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TRIPLE A', style: GoogleFonts.newsreader(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 3,
              )),
              Text('Admin Panel', style: GoogleFonts.manrope(
                fontSize: 11, color: Colors.white38, letterSpacing: 1,
              )),
            ]),
          ),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 16),

          // Nav items
          _NavItem(icon: Icons.dashboard_outlined,         label: 'Dashboard',   path: '/admin/dashboard',   active: activePath == '/admin/dashboard'),
          _NavItem(icon: Icons.inventory_2_outlined,       label: 'Products',    path: '/admin/products',    active: activePath == '/admin/products'),
          _NavItem(icon: Icons.collections_bookmark_outlined, label: 'Collections', path: '/admin/collections', active: activePath == '/admin/collections'),  // ← NEW
          _NavItem(icon: Icons.receipt_long_outlined,      label: 'Orders',      path: '/admin/orders',      active: activePath == '/admin/orders'),

          const Spacer(),
          Container(height: 1, color: Colors.white10),

          // User + logout
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?['full_name'] ?? 'Admin', style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(user?['role'] ?? 'admin', style: GoogleFonts.manrope(
                  fontSize: 11, color: Colors.white38, letterSpacing: 1,
                )),
              ])),
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: Colors.white54, size: 18),
                tooltip: 'Logout',
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  apiService.clearToken();
                  context.go('/admin/login');
                },
              ),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool active;
  const _NavItem({required this.icon, required this.label, required this.path, required this.active});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go(path),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Icon(icon, color: active ? Colors.white : Colors.white54, size: 18),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? Colors.white : Colors.white60,
        )),
        if (active) ...[
          const Spacer(),
          Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
        ],
      ]),
    ),
  );
}

// Admin scaffold wrapper
class AdminScaffold extends StatelessWidget {
  final String title;
  final String activePath;
  final Widget body;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.activePath,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      drawer: isWide ? null : Drawer(child: AdminSidebar(activePath: activePath)),
      appBar: isWide ? null : AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(title, style: GoogleFonts.newsreader(color: Colors.white, fontSize: 20)),
        actions: actions,
      ),
      body: isWide
          ? Row(children: [
              AdminSidebar(activePath: activePath),
              Expanded(child: Column(children: [
                Container(
                  color: AppColors.surfaceLowest,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Row(children: [
                    Text(title, style: GoogleFonts.newsreader(fontSize: 26, fontWeight: FontWeight.w400, color: AppColors.onSurface)),
                    const Spacer(),
                    if (actions != null) ...actions!,
                  ]),
                ),
                Expanded(child: body),
              ])),
            ])
          : body,
    );
  }
}