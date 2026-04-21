// lib/screens/customer/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/shared_widgets.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold<double>(0, (s, i) => s + i.subtotal);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: cart.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.outline),
              const SizedBox(height: 24),
              Text('Your cart is empty', style: GoogleFonts.newsreader(fontSize: 28, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/products'), child: const Text('CONTINUE SHOPPING')),
            ]))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final cartList = ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => Container(height: 1, color: AppColors.outlineVariant.withOpacity(0.2)),
                    itemBuilder: (_, i) => _CartItemRow(item: cart[i], ref: ref),
                  );
                  final summary = _OrderSummary(total: total, itemCount: cart.length);

                  if (isWide) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 3, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Cart', style: GoogleFonts.newsreader(fontSize: 36)),
                          const SizedBox(height: 32),
                          cartList,
                        ],
                      )),
                      const SizedBox(width: 64),
                      SizedBox(width: 320, child: summary),
                    ]);
                  }
                  return SingleChildScrollView(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Cart', style: GoogleFonts.newsreader(fontSize: 36)),
                      const SizedBox(height: 32),
                      cartList,
                      const SizedBox(height: 32),
                      summary,
                    ],
                  ));
                },
              ),
            ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final WidgetRef ref;
  const _CartItemRow({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 80, height: 96,
            child: p.imageUrl != null
                ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                : Container(color: AppColors.surfaceLow),
          ),
        ),
        const SizedBox(width: 20),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.w500)),
          if (p.color != null) Text(p.color!, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(children: [
            _QtyBtn(icon: Icons.remove, onTap: () => ref.read(cartProvider.notifier).updateQuantity(p.id, item.quantity - 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${item.quantity}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            _QtyBtn(icon: Icons.add, onTap: () => ref.read(cartProvider.notifier).updateQuantity(p.id, item.quantity + 1)),
          ]),
        ])),
        // Price + remove
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('৳ ${item.subtotal.toStringAsFixed(0)}',
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => ref.read(cartProvider.notifier).removeItem(p.id),
            child: Text('Remove', style: GoogleFonts.manrope(
              fontSize: 11, color: AppColors.secondary,
              decoration: TextDecoration.underline,
            )),
          ),
        ]),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5))),
      child: Icon(icon, size: 14, color: AppColors.onSurface),
    ),
  );
}

class _OrderSummary extends ConsumerWidget {
  final double total;
  final int itemCount;
  const _OrderSummary({required this.total, required this.itemCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: AppColors.surfaceLow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ORDER SUMMARY', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Subtotal ($itemCount items)', style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurfaceVariant)),
          Text('৳ ${total.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Delivery', style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurfaceVariant)),
          Text('To be confirmed', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline)),
        ]),
        const SizedBox(height: 20),
        Container(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('৳ ${total.toStringAsFixed(0)}', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/checkout'),
            child: const Text('PROCEED TO CHECKOUT'),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: TextButton(
          onPressed: () => context.go('/products'),
          child: Text('Continue Shopping', style: GoogleFonts.manrope(
            fontSize: 12, color: AppColors.onSurfaceVariant,
            decoration: TextDecoration.underline,
          )),
        )),
      ]),
    );
  }
}
