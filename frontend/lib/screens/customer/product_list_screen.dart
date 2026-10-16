// product_list_screen.dart — FIXED
// Removed: package:provider dependency, wrong import paths
// Added: initialCategoryId, initialCategoryName, initialGender, initialType params (expected by router.dart)
// Uses: apiService singleton directly

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../config/responsive.dart';
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

          // ── Result count ───────────────────────────────────────────────
          if (!_loading && _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text(
                _total > 1 ? '$_total products' : '$_total product',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
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
                        gridDelegate: Responsive.productGrid(context),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          return ProductCard(
                            product: p,
                            onTap: () => context.go('/products/${p['id']}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
