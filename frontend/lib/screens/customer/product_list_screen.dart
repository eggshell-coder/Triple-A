// product_list_screen.dart — FIXED
// Removed: package:provider dependency, wrong import paths
// Added: initialCategoryId, initialCategoryName, initialGender, initialType params (expected by router.dart)
// Uses: apiService singleton directly

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class ProductListScreen extends StatefulWidget {
  final String? gender;
  final String? collectionSlug;
  final String? initialCategoryId;
  final String? initialCategoryName;
  final String? initialGender;
  final String? initialType;

  const ProductListScreen({
    super.key,
    this.gender,
    this.collectionSlug,
    this.initialCategoryId,
    this.initialCategoryName,
    this.initialGender,
    this.initialType,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedGender;
  String? _selectedType;
  String  _searchQuery = '';
  Timer?  _debounce;

  List<dynamic> _products = [];
  bool          _loading  = true;
  int           _total    = 0;

  static const List<String> _types = [
    'oversized', 'polo', 'full-sleeve', 'half-sleeve', 'drop-shoulder', 'basic',
  ];

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender ?? widget.gender;
    _selectedType   = widget.initialType;
    _fetchProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (reset) {
      _products = [];
    }
    setState(() => _loading = true);

    try {
      final result = await apiService.getProducts(
        gender:         _selectedGender,
        type:           _selectedType,
        collectionSlug: widget.collectionSlug,
        categoryId:     widget.initialCategoryId,
        search:         _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _products = result['data'] as List<dynamic>? ?? [];
          _total    = result['count'] as int? ?? _products.length;
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _fetchProducts(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initialCategoryName ??
        (widget.collectionSlug != null
            ? widget.collectionSlug!.replaceAll('-', ' ').toUpperCase()
            : _selectedGender != null
                ? '${_selectedGender!.toUpperCase()}\'S T-SHIRTS'
                : 'ALL T-SHIRTS');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search T-shirts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),

          // ── Gender chips ───────────────────────────────────────────────
          if (widget.collectionSlug == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [null, 'men', 'women'].map((g) {
                  final label = g == null ? 'All' : g == 'men' ? "Men's" : "Women's";
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _selectedGender == g,
                      onSelected: (_) {
                        setState(() => _selectedGender = g);
                        _fetchProducts(reset: true);
                      },
                      selectedColor: const Color(0xFF1A1A1A),
                      labelStyle: TextStyle(
                        color: _selectedGender == g ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 4),

          // ── Type chips ─────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [null, ..._types].map((t) {
                final label = t == null ? 'All Types' : t[0].toUpperCase() + t.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _selectedType == t,
                    onSelected: (_) {
                      setState(() => _selectedType = t);
                      _fetchProducts(reset: true);
                    },
                    selectedColor: const Color(0xFF8B5A6B),
                    labelStyle: TextStyle(
                      color: _selectedType == t ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Product grid ───────────────────────────────────────────────
          Expanded(
            child: _loading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) => _ProductCard(product: _products[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final id    = product['id'];
    final name  = product['name'] as String? ?? '';
    final price = product['price'];
    final image = product['image_url'] as String? ?? product['image'] as String?;
    final type  = product['type'] as String?;

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
                  if (type != null)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                        child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
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
