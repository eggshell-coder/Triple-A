// wishlist_screen.dart — FIXED
// Removed: package:provider dependency, wrong import path
// Uses: apiService singleton directly

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> _items   = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await apiService.getMyWishlist();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String productId) async {
    try {
      await apiService.toggleWishlist(productId);
      _fetch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('MY WISHLIST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Your wishlist is empty', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/products'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                        child: const Text('Browse Products', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final product = _items[i]['products'] ?? _items[i];
                    final productId = (product['id'] ?? '').toString();
                    return _WishlistProductCard(
                      product:  product,
                      onRemove: () => _remove(productId),
                    );
                  },
                ),
    );
  }
}

class _WishlistProductCard extends StatelessWidget {
  final dynamic      product;
  final VoidCallback onRemove;
  const _WishlistProductCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final id    = product['id'];
    final name  = product['name'] as String? ?? '';
    final price = product['price'];
    final image = product['image_url'] as String? ?? product['image'] as String?;

    return GestureDetector(
      onTap: () => context.go('/products/$id'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: image != null
                        ? Image.network(image, width: double.infinity, fit: BoxFit.cover)
                        : Container(color: const Color(0xFFE5E5E5), child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey)),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite, color: Color(0xFFE57373), size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('৳$price', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
