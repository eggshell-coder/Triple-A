// lib/screens/customer/order_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';

class OrderConfirmScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String? estimatedDelivery;
  const OrderConfirmScreen({
    super.key,
    required this.orderId,
    this.estimatedDelivery,
  });

  @override
  ConsumerState<OrderConfirmScreen> createState() =>
      _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends ConsumerState<OrderConfirmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      return DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final shortId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F5E9),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 48, color: AppColors.completed),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fade,
                child: Column(children: [
                  Text('Order Placed!',
                      style: GoogleFonts.newsreader(
                          fontSize: 40,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 16),
                  Text(
                    'Thank you for your order. We will contact you\nshortly to confirm and arrange delivery.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
                        height: 1.6),
                  ),

                  // Order ID box
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    color: AppColors.surfaceLow,
                    child: Column(children: [
                      Text('ORDER ID',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text(shortId,
                          style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 3)),
                      // Estimated delivery
                      if (widget.estimatedDelivery != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: AppColors.outlineVariant.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.local_shipping_outlined,
                              size: 16, color: AppColors.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated delivery: ${_formatDate(widget.estimatedDelivery)}',
                            style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tertiary),
                          ),
                        ]),
                      ],
                    ]),
                  ),

                  const SizedBox(height: 32),
                  _StatusTimeline(),
                  const SizedBox(height: 32),

                  // If logged in, prompt to view orders
                  if (user.isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFF0F7F1),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: AppColors.completed),
                        const SizedBox(width: 8),
                        Text('This order is saved to your account.',
                            style: GoogleFonts.manrope(
                                fontSize: 12, color: AppColors.completed)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('BACK TO HOME'),
                    ),
                    const SizedBox(width: 16),
                    if (user.isLoggedIn)
                      OutlinedButton(
                        onPressed: () => context.go('/my-orders'),
                        child: const Text('MY ORDERS'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => context.go('/products'),
                        child: const Text('SHOP MORE'),
                      ),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.check_circle_outline, 'Order Received', true),
      (Icons.phone_outlined, 'We\'ll Call You', false),
      (Icons.local_shipping_outlined, 'Delivery', false),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final (icon, label, done) = e.value;
        return Row(children: [
          Column(children: [
            Icon(icon,
                color: done ? AppColors.completed : AppColors.outline,
                size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        done ? AppColors.completed : AppColors.outline)),
          ]),
          if (i < steps.length - 1) ...[
            const SizedBox(width: 12),
            Container(width: 48, height: 1, color: AppColors.outlineVariant),
            const SizedBox(width: 12),
          ],
        ]);
      }).toList(),
    );
  }
}