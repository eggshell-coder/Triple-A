// lib/screens/customer/collection_products_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class CollectionProductsScreen extends ConsumerStatefulWidget {
  final String slug;
  const CollectionProductsScreen({super.key, required this.slug});

  @override
  ConsumerState<CollectionProductsScreen> createState() =>
      _CollectionProductsScreenState();
}

class _CollectionProductsScreenState
    extends ConsumerState<CollectionProductsScreen> {
  Map<String, dynamic>? _collection;
  List<dynamic> _products = [];
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
      final data = await apiService.getCollectionProducts(widget.slug);
      if (mounted) setState(() {
        _collection = data['collection'] as Map<String, dynamic>?;
        _products = (data['products'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.secondary),
                      const SizedBox(height: 12),
                      Text('Failed to load collection',
                          style: GoogleFonts.manrope(
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('RETRY')),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Collection header banner
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        color: AppColors.primaryContainer,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 80 : 24,
                          vertical: 40,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_collection?['badge'] != null)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _collection!['badge'],
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    (_collection?['name'] ?? 'Collection')
                                        .toString(),
                                    style: GoogleFonts.newsreader(
                                      fontSize: isWide ? 40 : 28,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  if (_collection?['description'] != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _collection!['description'],
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Text(
                                    '${_products.length} item${_products.length == 1 ? '' : 's'}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: Colors.white54,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Products grid
                    _products.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 56, color: AppColors.outline),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products in this collection yet',
                                    style: GoogleFonts.manrope(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: () =>
                                        context.go('/products'),
                                    child: Text(
                                      'BROWSE ALL PRODUCTS',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 40 : 16,
                              vertical: 32,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 4 : 2,
                                crossAxisSpacing: isWide ? 24 : 12,
                                mainAxisSpacing: isWide ? 32 : 16,
                                childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  final p =
                                      _products[i] as Map<String, dynamic>;
                                  return ProductCard(
                                    product: p,
                                    onTap: () =>
                                        context.go('/products/${p['id']}'),
                                  );
                                },
                                childCount: _products.length,
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }
}