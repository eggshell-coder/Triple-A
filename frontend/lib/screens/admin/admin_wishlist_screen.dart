// admin_wishlist_screen.dart — FIXED
// Removed: package:provider dependency, wrong import path, non-existent api.get() method
// Uses: apiService singleton with correct method names

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminWishlistScreen extends StatefulWidget {
  const AdminWishlistScreen({super.key});
  @override
  State<AdminWishlistScreen> createState() => _AdminWishlistScreenState();
}

class _AdminWishlistScreenState extends State<AdminWishlistScreen> {
  List<dynamic> _summary = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final data = await apiService.getWishlistSummaryAdmin();
      if (mounted) setState(() { _summary = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('WISHLIST ANALYTICS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _summary.isEmpty
              ? const Center(child: Text('No wishlist data yet.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${_summary.length} products have been wishlisted',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _summary.length,
                        itemBuilder: (ctx, i) {
                          final item      = _summary[i];
                          final product   = item['product'];
                          final count     = (item['count'] ?? 0) as int;
                          final productId = (item['product_id'] ?? product?['id'] ?? '').toString();
                          final imgUrl    = product?['image_url'] as String? ?? product?['image'] as String?;

                          return ListTile(
                            leading: imgUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(imgUrl, width: 48, height: 48, fit: BoxFit.cover),
                                  )
                                : Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: const Color(0xFFE5E5E5), borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.image_outlined),
                                  ),
                            title: Text(product?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Row(
                              children: [
                                const Icon(Icons.favorite, color: Color(0xFFE57373), size: 14),
                                const SizedBox(width: 4),
                                Text('$count ${count == 1 ? 'person' : 'people'} saved this'),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showWishlisters(context, productId, product?['name'] ?? ''),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showWishlisters(BuildContext context, String productId, String productName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _WishlistersList(productId: productId, productName: productName),
    );
  }
}

// ── Bottom sheet: users who saved a specific product ────────────────────────
class _WishlistersList extends StatefulWidget {
  final String productId;
  final String productName;
  const _WishlistersList({required this.productId, required this.productName});
  @override
  State<_WishlistersList> createState() => _WishlistersListState();
}

class _WishlistersListState extends State<_WishlistersList> {
  List<dynamic> _users   = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await apiService.getWishlistersForProduct(widget.productId);
      final users = data['data'] as List<dynamic>? ?? data['users'] as List<dynamic>? ?? [];
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_users.length} users have saved this', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('No users have saved this product.'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: _users.length,
                        itemBuilder: (ctx, i) {
                          final entry = _users[i];
                          final user  = entry['users'] ?? entry;
                          final name  = user['full_name'] as String? ?? 'Unknown';
                          final email = user['email']     as String? ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1A1A1A),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
