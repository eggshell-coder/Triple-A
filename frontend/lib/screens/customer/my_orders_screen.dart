// lib/screens/customer/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await apiService.getMyOrders();
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 80 : 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('My Orders',
                      style: GoogleFonts.newsreader(
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text('Welcome back, ${user.name}',
                      style: GoogleFonts.manrope(
                          fontSize: 14, color: AppColors.onSurfaceVariant)),
                ]),
              ),
              TextButton.icon(
                onPressed: () async {
                  await ref.read(userProvider.notifier).logout();
                  apiService.clearUserToken();
                  if (mounted) context.go('/');
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Sign Out'),
                style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              ),
            ]),
            const SizedBox(height: 40),

            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFFFFEBEE),
                child: Text(_error!,
                    style: GoogleFonts.manrope(color: AppColors.secondary)),
              )
            else if (_orders.isEmpty)
              Center(
                child: Column(children: [
                  const SizedBox(height: 40),
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.outline),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: GoogleFonts.newsreader(
                          fontSize: 24, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Your orders will appear here once you shop.',
                      style: GoogleFonts.manrope(
                          fontSize: 14, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/products'),
                    child: const Text('START SHOPPING'),
                  ),
                ]),
              )
            else
              Column(
                children: _orders.map((order) => _OrderCard(order: order)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    final items = (order['order_items'] as List?) ?? [];
    final total = (order['total_amount'] ?? 0).toDouble();
    final deliveryCharge = (order['delivery_charge'] ?? 0).toDouble();
    final district = order['district'] as String?;
    final estimatedDelivery = order['estimated_delivery'] as String?;
    final shortId = (order['id'] ?? '').toString().length >= 8
        ? (order['id'] ?? '').toString().substring(0, 8).toUpperCase()
        : (order['id'] ?? '').toString().toUpperCase();
    final date = order['created_at'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(order['created_at']))
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppColors.surfaceLow,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ORDER #$shortId',
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(date,
                      style: GoogleFonts.manrope(
                          fontSize: 11, color: AppColors.onSurfaceVariant)),
                ]),
              ),
              _StatusChip(status),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                ...items.take(3).map((item) {
                  final product = item['products'] as Map<String, dynamic>?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          width: 48,
                          height: 56,
                          child: product?['image_url'] != null
                              ? Image.network(product!['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: AppColors.surfaceHigh))
                              : Container(color: AppColors.surfaceHigh),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(product?['name'] ?? '—',
                              style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('Qty: ${item['quantity']}',
                              style: GoogleFonts.manrope(
                                  fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ]),
                      ),
                      Text(
                          '৳ ${((item['unit_price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  );
                }),
                if (items.length > 3)
                  Text('+${items.length - 3} more items',
                      style: GoogleFonts.manrope(
                          fontSize: 11, color: AppColors.onSurfaceVariant)),

                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Delivery info
                      if (district != null)
                        Row(children: [
                          const Icon(Icons.local_shipping_outlined,
                              size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                              '$district · ৳${deliveryCharge.toStringAsFixed(0)} delivery',
                              style: GoogleFonts.manrope(
                                  fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ]),
                      // Estimated delivery
                      if (estimatedDelivery != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(
                            status == 'completed'
                                ? Icons.check_circle_outline
                                : Icons.schedule_outlined,
                            size: 14,
                            color: status == 'completed'
                                ? AppColors.completed
                                : AppColors.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status == 'completed'
                                ? 'Delivered'
                                : 'Est. delivery: ${DateFormat('dd MMM').format(DateTime.parse(estimatedDelivery))}',
                            style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: status == 'completed'
                                    ? AppColors.completed
                                    : AppColors.tertiary),
                          ),
                        ]),
                      ],
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('TOTAL',
                        style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.onSurfaceVariant)),
                    Text('৳ ${total.toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ]),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': (AppColors.pending, const Color(0xFFFFF8E1)),
      'processing': (AppColors.processing, const Color(0xFFE3F2FD)),
      'completed': (AppColors.completed, const Color(0xFFE8F5E9)),
      'cancelled': (AppColors.cancelled, const Color(0xFFFFEBEE)),
    };
    final (fg, bg) = colors[status] ?? (AppColors.outline, AppColors.surfaceLow);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: fg)),
    );
  }
}