// lib/screens/customer/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});
  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _order;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final id = _ctrl.text.trim();
    if (id.isEmpty) return;
    setState(() { _loading = true; _error = null; _order = null; });
    try {
      final data = await apiService.trackOrder(id);
      if (mounted) setState(() { _order = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 96 : 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track Your Order',
                style: GoogleFonts.newsreader(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text('Enter your order ID to check the status.',
                style: GoogleFonts.manrope(
                    fontSize: 14, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 40),

            // Search bar
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Order ID',
                    hintText: 'e.g. A1B2C3D4...',
                    hintStyle: GoogleFonts.manrope(
                        color: AppColors.outline, fontSize: 13),
                    prefixIcon: const Icon(Icons.receipt_long_outlined,
                        size: 20, color: AppColors.outline),
                  ),
                  onSubmitted: (_) => _track(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _loading ? null : _track,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 18)),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('TRACK'),
              ),
            ]),

            const SizedBox(height: 48),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFFFFEBEE),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.manrope(
                              fontSize: 13, color: AppColors.secondary))),
                ]),
              ),

            // Order result
            if (_order != null) _OrderResult(order: _order!),
          ],
        ),
      ),
    );
  }
}

class _OrderResult extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderResult({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = (order['order_items'] as List?) ?? [];
    final deliveryCharge =
        (order['delivery_charge'] ?? 0).toDouble();
    final total = (order['total_amount'] ?? 0).toDouble();
    final productsTotal = total - deliveryCharge;
    final district = order['district'] as String?;
    final date = order['created_at'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(DateTime.parse(order['created_at']))
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status timeline
        _StatusTimeline(status: status),
        const SizedBox(height: 32),

        // Order info card
        Container(
          padding: const EdgeInsets.all(28),
          color: AppColors.surfaceLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ORDER DETAILS',
                      style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.onSurfaceVariant)),
                  _StatusBadge(status),
                ],
              ),
              const SizedBox(height: 20),
              _InfoRow('Order ID',
                  order['id']?.toString().substring(0, 8).toUpperCase() ??
                      '—'),
              _InfoRow('Placed On', date),
              if (customer != null) ...[
                _InfoRow('Name', customer['full_name'] ?? '—'),
                _InfoRow('Phone', customer['phone'] ?? '—'),
                _InfoRow('Address', customer['address'] ?? '—'),
              ],
              if (district != null) _InfoRow('District', district),
              const SizedBox(height: 20),
              Container(
                  height: 1,
                  color: AppColors.outlineVariant.withOpacity(0.3)),
              const SizedBox(height: 20),

              // Items
              Text('ITEMS',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 16),
              ...items.map((item) {
                final product =
                    item['products'] as Map<String, dynamic>?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: 48,
                        height: 56,
                        child: product?['image_url'] != null
                            ? Image.network(product!['image_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surfaceHigh))
                            : Container(color: AppColors.surfaceHigh),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product?['name'] ?? '—',
                            style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Qty: ${item['quantity']}',
                            style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant)),
                      ],
                    )),
                    Text(
                        '৳ ${((item['unit_price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface)),
                  ]),
                );
              }),

              Container(
                  height: 1,
                  color: AppColors.outlineVariant.withOpacity(0.3)),
              const SizedBox(height: 16),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Products',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant)),
                    Text('৳ ${productsTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant)),
                  ]),
              const SizedBox(height: 6),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery${district != null ? ' ($district)' : ''}',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant)),
                    Text('৳ ${deliveryCharge.toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant)),
                  ]),
              const SizedBox(height: 10),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                    Text('৳ ${total.toStringAsFixed(0)}',
                        style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface))),
        ]),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': (AppColors.pending, const Color(0xFFFFF8E1)),
      'processing': (AppColors.processing, const Color(0xFFE3F2FD)),
      'completed': (AppColors.completed, const Color(0xFFE8F5E9)),
      'cancelled': (AppColors.cancelled, const Color(0xFFFFEBEE)),
    };
    final (fg, bg) =
        colors[status] ?? (AppColors.outline, AppColors.surfaceLow);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: fg)),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  int get _currentStep {
    switch (status) {
      case 'pending':
        return 0;
      case 'processing':
        return 1;
      case 'completed':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFFFEBEE),
        child: Row(children: [
          const Icon(Icons.cancel_outlined,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: 12),
          Text('This order has been cancelled.',
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary)),
        ]),
      );
    }

    final steps = [
      (Icons.check_circle_outline, 'Order Placed'),
      (Icons.sync_outlined, 'Processing'),
      (Icons.local_shipping_outlined, 'Shipped'),
      (Icons.home_outlined, 'Delivered'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surfaceLow,
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label) = e.value;
          final isDone = i <= _currentStep;
          final isActive = i == _currentStep;

          return Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.completed.withOpacity(0.15)
                          : AppColors.surfaceHigh,
                      border: isActive
                          ? Border.all(
                              color: AppColors.completed, width: 2)
                          : null,
                    ),
                    child: Icon(icon,
                        size: 20,
                        color: isDone
                            ? AppColors.completed
                            : AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: isDone
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isDone
                              ? AppColors.completed
                              : AppColors.outline)),
                ]),
              ),
              if (i < steps.length - 1)
                Container(
                    width: 24,
                    height: 1.5,
                    color: i < _currentStep
                        ? AppColors.completed
                        : AppColors.outlineVariant),
            ]),
          );
        }).toList(),
      ),
    );
  }
}