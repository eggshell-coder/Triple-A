// lib/screens/customer/shop_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class ShopCategoriesScreen extends ConsumerStatefulWidget {
  const ShopCategoriesScreen({super.key});
  @override
  ConsumerState<ShopCategoriesScreen> createState() => _ShopCategoriesScreenState();
}

class _ShopCategoriesScreenState extends ConsumerState<ShopCategoriesScreen> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiService.getCategories();
      if (mounted) setState(() { _categories = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Emoji per category name
  String _emoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('t-shirt') || n.contains('tshirt')) return '👕';
    if (n.contains('shirt')) return '👔';
    if (n.contains('pant') || n.contains('trouser') || n.contains('jeans')) return '👖';
    if (n.contains('hoodie') || n.contains('hoodi')) return '🧥';
    if (n.contains('polo')) return '🎽';
    if (n.contains('jacket')) return '🧣';
    if (n.contains('graphic') || n.contains('tee')) return '🎨';
    if (n.contains('oversized')) return '📦';
    if (n.contains('limited')) return '⭐';
    if (n.contains('dress')) return '👗';
    if (n.contains('skirt')) return '🩱';
    return '🛍️';
  }

  Color _bgColor(int index) {
    const colors = [
      Color(0xFFF0F4FF), Color(0xFFFFF0F4), Color(0xFFF0FFF4),
      Color(0xFFFFF8F0), Color(0xFFF4F0FF), Color(0xFFF0FAFF),
      Color(0xFFFFF0FB), Color(0xFFFAFFF0),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final cols = isWide ? 4 : 2;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 48, 40, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BROWSE BY CATEGORY',
                          style: GoogleFonts.manrope(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              letterSpacing: 3, color: AppColors.tertiary)),
                      const SizedBox(height: 8),
                      Text('Shop by Style',
                          style: GoogleFonts.newsreader(
                              fontSize: 36, fontWeight: FontWeight.w400,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 8),
                      Text('Tap a category to browse products.',
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 32),

                      // ── All Products shortcut ──
                      _AllProductsCard(isWide: isWide),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),

                // ── Category Grid ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 64),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.4 : 1.2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final cat = _categories[i];
                        return _CategoryCard(
                          name: cat['name'] ?? '',
                          emoji: _emoji(cat['name'] ?? ''),
                          bgColor: _bgColor(i),
                          onTap: () => context.go(
                            '/products?category_id=${cat['id']}&category_name=${Uri.encodeComponent(cat['name'] ?? '')}',
                          ),
                        );
                      },
                      childCount: _categories.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── All Products shortcut card ───────────────────────────────────────────────
class _AllProductsCard extends StatelessWidget {
  final bool isWide;
  const _AllProductsCard({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/products'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          const Text('🛍️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('All Products',
                  style: GoogleFonts.newsreader(
                      fontSize: 22, fontWeight: FontWeight.w400, color: Colors.white)),
              Text('Browse the full collection',
                  style: GoogleFonts.manrope(fontSize: 13, color: Colors.white60)),
            ]),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
        ]),
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final String name;
  final String emoji;
  final Color bgColor;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.name, required this.emoji,
    required this.bgColor, required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.4),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.newsreader(
                  fontSize: 18, fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text('SHOP NOW',
                    style: GoogleFonts.manrope(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}