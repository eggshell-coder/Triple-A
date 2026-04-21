// lib/screens/customer/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/shared_widgets.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _quantity = 1;
  bool _addedToCart = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final data = await apiService.getProductById(widget.productId);
      if (mounted) setState(() { _product = Product.fromJson(data['data']); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addToCart() {
    if (_product == null || !_product!.inStock) return;
    ref.read(cartProvider.notifier).addItem(_product!, quantity: _quantity);
    setState(() => _addedToCart = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.tertiary,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addedToCart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _product == null
              ? Center(child: Text('Product not found', style: GoogleFonts.newsreader(fontSize: 20)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                    child: isWide
                        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Image
                            Expanded(flex: 5, child: _ProductImage(imageUrl: _product!.imageUrl)),
                            const SizedBox(width: 64),
                            // Details
                            Expanded(flex: 4, child: _ProductInfo(
                              product: _product!,
                              quantity: _quantity,
                              addedToCart: _addedToCart,
                              onQuantityChange: (q) => setState(() => _quantity = q),
                              onAddToCart: _addToCart,
                              onBuyNow: () {
                                _addToCart();
                                context.go('/checkout');
                              },
                            )),
                          ])
                        : Column(children: [
                            _ProductImage(imageUrl: _product!.imageUrl),
                            const SizedBox(height: 32),
                            _ProductInfo(
                              product: _product!,
                              quantity: _quantity,
                              addedToCart: _addedToCart,
                              onQuantityChange: (q) => setState(() => _quantity = q),
                              onAddToCart: _addToCart,
                              onBuyNow: () {
                                _addToCart();
                                context.go('/checkout');
                              },
                            ),
                          ]),
                  ),
                ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: AspectRatio(
        aspectRatio: 0.8,
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceLow))
            : Container(color: AppColors.surfaceLow,
                child: const Icon(Icons.image_outlined, size: 64, color: AppColors.outline)),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  final int quantity;
  final bool addedToCart;
  final Function(int) onQuantityChange;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const _ProductInfo({
    required this.product,
    required this.quantity,
    required this.addedToCart,
    required this.onQuantityChange,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Category tag
      Text(
        product.categoryName.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 2.5, color: AppColors.tertiary,
        ),
      ),
      const SizedBox(height: 12),
      // Name
      Text(product.name, style: GoogleFonts.newsreader(
        fontSize: 36, fontWeight: FontWeight.w400,
        color: AppColors.onSurface, height: 1.1,
      )),
      const SizedBox(height: 20),
      // Price
      Text(
        '৳ ${product.price.toStringAsFixed(0)}',
        style: GoogleFonts.manrope(
          fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.onSurface,
        ),
      ),
      const SizedBox(height: 32),
      // Stock status
      Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: product.inStock ? AppColors.completed : AppColors.cancelled,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          product.inStock ? '${product.stock} in stock' : 'Out of stock',
          style: GoogleFonts.manrope(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
      ]),
      const SizedBox(height: 24),
      // Attributes
      if (product.size != null) _AttributeRow(label: 'SIZE', value: product.size!),
      if (product.color != null) _AttributeRow(label: 'COLOR', value: product.color!),
      const SizedBox(height: 24),
      // Description
      if (product.description != null) ...[
        Text('Description', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(product.description!, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.7)),
        const SizedBox(height: 32),
      ],
      // Quantity selector
      if (product.inStock) ...[
        Text('QUANTITY', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Row(children: [
          _QtyButton(icon: Icons.remove, onTap: () { if (quantity > 1) onQuantityChange(quantity - 1); }),
          SizedBox(
            width: 48,
            child: Text('$quantity', textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          _QtyButton(icon: Icons.add, onTap: () { if (quantity < product.stock) onQuantityChange(quantity + 1); }),
        ]),
        const SizedBox(height: 32),
      ],
      // CTAs
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: product.inStock ? onAddToCart : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: addedToCart ? AppColors.completed : AppColors.primary,
          ),
          child: Text(addedToCart ? '✓ ADDED TO CART' : 'ADD TO CART'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: product.inStock ? onBuyNow : null,
          child: const Text('BUY NOW'),
        ),
      ),
    ]);
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final String value;
  const _AttributeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(
        width: 64,
        child: Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.outline)),
      ),
      Text(value, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.onSurface)),
    ]),
  );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5))),
      child: Icon(icon, size: 18, color: AppColors.onSurface),
    ),
  );
}
