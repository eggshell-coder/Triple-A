// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/shared_widgets.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = DashboardStats.fromJson(data['data']);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dashboard',
      activePath: '/admin/dashboard',
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _stats == null
              ? const Center(child: Text('Failed to load stats'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Low stock alert — shown first if there are issues
                          if (_stats!.lowStockProducts.isNotEmpty) ...[
                            _LowStockAlert(
                                products: _stats!.lowStockProducts),
                            const SizedBox(height: 32),
                          ],

                          // Stat cards
                          _StatsGrid(stats: _stats!),
                          const SizedBox(height: 40),

                          // Revenue highlight
                          _RevenueCard(revenue: _stats!.totalRevenue),
                          const SizedBox(height: 40),

                          // Recent orders
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Recent Orders',
                                    style: GoogleFonts.newsreader(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.onSurface)),
                                TextButton(
                                  onPressed: () =>
                                      context.go('/admin/orders'),
                                  child: Text('View All',
                                      style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: AppColors.primary)),
                                ),
                              ]),
                          const SizedBox(height: 16),
                          _RecentOrdersTable(
                              orders: _stats!.recentOrders),
                        ]),
                  ),
                ),
    );
  }
}

// ─── Low Stock Alert ──────────────────────────────────────────────────────────
class _LowStockAlert extends StatefulWidget {
  final List<dynamic> products;
  const _LowStockAlert({required this.products});

  @override
  State<_LowStockAlert> createState() => _LowStockAlertState();
}

class _LowStockAlertState extends State<_LowStockAlert> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final outOfStock = widget.products.where((p) => (p['stock'] ?? 0) == 0).length;
    final lowStock = widget.products.where((p) => (p['stock'] ?? 0) > 0).length;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFB74D)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFFFFF8E1),
              child: Row(children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Color(0xFFF57C00), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: const Color(0xFF5D4037)),
                      children: [
                        if (outOfStock > 0)
                          TextSpan(
                            text: '$outOfStock out of stock',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        if (outOfStock > 0 && lowStock > 0)
                          const TextSpan(text: ' · '),
                        if (lowStock > 0)
                          TextSpan(text: '$lowStock low stock (≤5 units)'),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFFF57C00),
                  size: 20,
                ),
              ]),
            ),
          ),

          // Expanded product list
          if (_expanded)
            Container(
              color: const Color(0xFFFFFDE7),
              child: Column(
                children: widget.products.map((p) {
                  final stock = p['stock'] ?? 0;
                  final isOut = stock == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: const Color(0xFFFFB74D)
                                    .withOpacity(0.3)))),
                    child: Row(children: [
                      // Thumbnail
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: p['image_url'] != null
                            ? Image.network(p['image_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    size: 16,
                                    color: AppColors.outline))
                            : const Icon(Icons.image_outlined,
                                size: 16, color: AppColors.outline),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(p['name'] ?? '—',
                              style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (p['categories'] != null)
                            Text(p['categories']['name'] ?? '',
                                style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOut
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          isOut ? 'OUT OF STOCK' : '$stock left',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isOut
                                ? AppColors.secondary
                                : const Color(0xFFF57C00),
                          ),
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (stats.totalProducts.toString(), 'Total Products',
          Icons.inventory_2_outlined, AppColors.primary),
      (stats.totalOrders.toString(), 'Total Orders',
          Icons.receipt_long_outlined, AppColors.secondary),
      (stats.pendingOrders.toString(), 'Pending',
          Icons.pending_outlined, AppColors.pending),
      (stats.processingOrders.toString(), 'Processing',
          Icons.sync_outlined, AppColors.processing),
      (stats.completedOrders.toString(), 'Completed',
          Icons.check_circle_outline, AppColors.completed),
      (stats.cancelledOrders.toString(), 'Cancelled',
          Icons.cancel_outlined, AppColors.cancelled),
    ];

    return LayoutBuilder(builder: (_, constraints) {
      final cols = constraints.maxWidth > 900
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 2.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final (value, label, icon, color) = cards[i];
          return Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.surfaceLowest,
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(value,
                        style: GoogleFonts.newsreader(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface)),
                    Text(label,
                        style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ]),
            ]),
          );
        },
      );
    });
  }
}

// ─── Revenue Card ─────────────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final double revenue;
  const _RevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer]),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL REVENUE',
              style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white60)),
          const SizedBox(height: 8),
          Text('৳ ${NumberFormat('#,##0').format(revenue)}',
              style: GoogleFonts.newsreader(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Colors.white)),
          Text('From completed orders',
              style:
                  GoogleFonts.manrope(fontSize: 12, color: Colors.white60)),
        ]),
        const Spacer(),
        Icon(Icons.trending_up_outlined,
            color: Colors.white.withOpacity(0.3), size: 80),
      ]),
    );
  }
}

// ─── Recent Orders Table ──────────────────────────────────────────────────────
class _RecentOrdersTable extends StatelessWidget {
  final List<dynamic> orders;
  const _RecentOrdersTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        color: AppColors.surfaceLowest,
        child: Center(
            child: Text('No orders yet',
                style:
                    GoogleFonts.manrope(color: AppColors.outline))),
      );
    }

    return Container(
      color: AppColors.surfaceLowest,
      child: Column(children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: AppColors.surfaceLow,
          child: Row(children: [
            _HeaderCell('ORDER ID', flex: 2),
            _HeaderCell('CUSTOMER', flex: 3),
            _HeaderCell('AMOUNT', flex: 2),
            _HeaderCell('DELIVERY', flex: 2),
            _HeaderCell('STATUS', flex: 2),
            _HeaderCell('DATE', flex: 3),
          ]),
        ),
        ...orders.map((order) {
          final customer = order['customers'];
          final date = order['created_at'] != null
              ? DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(order['created_at']))
              : '—';
          final deliveryCharge =
              (order['delivery_charge'] ?? 0).toDouble();
          final district = order['district'] as String?;

          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color:
                            AppColors.outlineVariant.withOpacity(0.2)))),
            child: Row(children: [
              _Cell(
                  text: order['id']
                          ?.toString()
                          .substring(0, 8)
                          .toUpperCase() ??
                      '—',
                  flex: 2,
                  bold: true),
              _Cell(text: customer?['full_name'] ?? '—', flex: 3),
              _Cell(
                  text:
                      '৳ ${(order['total_amount'] ?? 0).toStringAsFixed(0)}',
                  flex: 2),
              _Cell(
                  text: district != null
                      ? '৳${deliveryCharge.toStringAsFixed(0)} ($district)'
                      : '৳${deliveryCharge.toStringAsFixed(0)}',
                  flex: 2,
                  secondary: true),
              Expanded(
                  flex: 2,
                  child: StatusChip(order['status'] ?? 'pending')),
              _Cell(text: date, flex: 3, secondary: true),
            ]),
          );
        }),
      ]),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant)),
      );
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final bool secondary;
  const _Cell(
      {required this.text,
      required this.flex,
      this.bold = false,
      this.secondary = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: secondary
                  ? AppColors.onSurfaceVariant
                  : AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      );
}