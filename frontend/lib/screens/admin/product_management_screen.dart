// lib/screens/admin/product_management_screen.dart
// Based on the original working version with three changes:
//   1. collection_id type fixed: int? → String? (UUIDs are strings)
//   2. Image field replaced with device picker + Supabase upload
//   3. ProductManagementScreen wraps the form with a product list + add/delete

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT MANAGEMENT SCREEN  (list + add/delete — shown at /admin/products)
// ─────────────────────────────────────────────────────────────────────────────
class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});
  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  List<dynamic> _products = [];
  bool   _loading = true;
  String _search  = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getAllProductsAdmin();
      if (mounted) {
        final all = data['data'] as List<dynamic>? ?? [];
        setState(() {
          _products = _search.trim().isEmpty
              ? all
              : all.where((p) => (p['name'] ?? '').toString().toLowerCase().contains(_search.trim().toLowerCase())).toList();
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(dynamic product) async {
    final name = product['name']?.toString() ?? 'this product';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Delete Product',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text('Delete "$name"? This cannot be undone.',
            style: GoogleFonts.manrope(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.manrope(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            child: Text('Delete',
                style: GoogleFonts.manrope(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiService.deleteProduct(product['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" deleted'),
          backgroundColor: Colors.green,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _openForm({Map<String, dynamic>? product}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminProductFormScreen(existingProduct: product),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _search.trim().isEmpty
        ? _products
        : _products.where((p) {
            final n = (p['name'] ?? '').toString().toLowerCase();
            return n.contains(_search.trim().toLowerCase());
          }).toList();

    return AdminScaffold(
      title: 'Products',
      activePath: '/admin/products',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: Text('ADD PRODUCT',
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
      body: Column(children: [
        // ── Search bar ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search products…',
                  hintStyle: GoogleFonts.manrope(
                      fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, size: 18,
                      color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8F5F0),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text('${shown.length} product${shown.length == 1 ? '' : 's'}',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: Colors.grey[500])),
          ]),
        ),

        // ── Product grid ────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : shown.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'No products yet.\nTap ADD PRODUCT to create one.'
                              : 'No products match "$_search".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: Colors.grey[500]),
                        ),
                      ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _ProductCard(
                          product:  shown[i],
                          onEdit:   () => _openForm(product: shown[i]),
                          onDelete: () => _confirmDelete(shown[i]),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final dynamic     product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard(
      {required this.product,
       required this.onEdit,
       required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name     = product['name']?.toString() ?? '';
    final price    = product['price'];
    final gender   = product['gender']?.toString() ?? '';
    final type     = product['type']?.toString()   ?? '';
    final imageUrl = product['image_url']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
        Expanded(
          child: Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: imageUrl != null
                  ? Image.network(imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            // Edit / Delete buttons
            Positioned(
              top: 6, right: 6,
              child: Column(children: [
                _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF1A1A1A),
                    onTap: onEdit),
                const SizedBox(height: 6),
                _ActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: onDelete),
              ]),
            ),
          ]),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Text('৳ $price',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A))),
              const Spacer(),
              if (type.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE8),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(type,
                      style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600])),
                ),
            ]),
            if (gender.isNotEmpty)
              Text(gender == 'men' ? "Men's" : "Women's",
                  style: GoogleFonts.manrope(
                      fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF0EDE8),
        child: const Center(
            child: Icon(Icons.image_outlined,
                size: 36, color: Color(0xFFCCCCCC))),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12), blurRadius: 4)
              ]),
          child: Icon(icon, size: 15, color: color),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN PRODUCT FORM SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdminProductFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingProduct;
  const AdminProductFormScreen({super.key, this.existingProduct});
  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  String? _selectedGender;
  String? _selectedType;
  String? _selectedCollectionId;
  bool    _submitting = false;

  String?    _uploadedImageUrl;
  Uint8List? _previewBytes;
  bool       _uploadingImage = false;
  String?    _imageError;

  List<dynamic> _collections        = [];
  bool          _loadingCollections = true;

  static const List<String> _genders = ['men', 'women'];
  static const List<String> _types   = [
    'oversized', 'polo', 'full-sleeve',
    'half-sleeve', 'drop-shoulder', 'basic',
  ];

  bool get _isEdit => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
    if (_isEdit) {
      final p = widget.existingProduct!;
      _nameCtrl.text         = p['name']?.toString()        ?? '';
      _priceCtrl.text        = p['price']?.toString()       ?? '';
      _stockCtrl.text        = p['stock']?.toString()       ?? '0';
      _descCtrl.text         = p['description']?.toString() ?? '';
      _selectedGender        = p['gender']?.toString();
      _selectedType          = p['type']?.toString();
      _selectedCollectionId  = p['collection_id']?.toString();
      _uploadedImageUrl      = p['image_url']?.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCollections() async {
    try {
      final data = await apiService.getCollectionsAdmin();
      if (mounted) {
        setState(() {
          _collections        = data;
          _loadingCollections = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCollections = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _imageError = null);

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source:       ImageSource.gallery,
      maxWidth:     1200,
      maxHeight:    1200,
      imageQuality: 88,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _previewBytes     = bytes;
      _uploadingImage   = true;
      _uploadedImageUrl = null;
    });

    try {
      final url = await apiService.uploadProductImage(bytes, picked.name);
      if (mounted) {
        setState(() {
          _uploadedImageUrl = url;
          _uploadingImage   = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageError     = 'Upload failed: $e';
          _uploadingImage = false;
          _previewBytes   = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showError('Please select a gender');
      return;
    }
    if (_selectedType == null) {
      _showError('Please select a T-shirt type');
      return;
    }
    if (_uploadingImage) {
      _showError('Image is still uploading, please wait');
      return;
    }

    setState(() => _submitting = true);

    final payload = {
      'name':          _nameCtrl.text.trim(),
      'gender':        _selectedGender,
      'type':          _selectedType,
      'collection_id': _selectedCollectionId,
      'price':         double.tryParse(_priceCtrl.text.trim()),
      'stock':         int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'image_url':     _uploadedImageUrl,
      'description':   _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await apiService.updateProduct(
            widget.existingProduct!['id'].toString(), payload);
      } else {
        await apiService.createProduct(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Product updated!' : 'Product created!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _isEdit ? 'EDIT PRODUCT' : 'ADD PRODUCT',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildImagePicker(),
              const SizedBox(height: 14),

              _buildTextField(_nameCtrl, 'Product Name', required: true),
              const SizedBox(height: 14),

              _buildTextField(
                _priceCtrl, 'Price (৳)',
                required: true,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _buildTextField(
                _stockCtrl, 'Stock Quantity',
                required: true,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final value = int.tryParse(v);
                  if (value == null || value < 0) return 'Enter a valid stock quantity';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _buildStringDropdown(
                label: 'Gender',
                value: _selectedGender,
                items: _genders,
                itemLabel: (g) => g == 'men' ? "Men's" : "Women's",
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 14),

              _buildStringDropdown(
                label: 'T-shirt Type',
                value: _selectedType,
                items: _types,
                itemLabel: (t) => t[0].toUpperCase() + t.substring(1),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 14),

              _loadingCollections
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _buildCollectionDropdown(),
              const SizedBox(height: 14),

              _buildTextField(_descCtrl, 'Description (optional)',
                  required: false, maxLines: 4),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(
                          _isEdit ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                          style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_uploadingImage) {
      return _imageBox(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 12),
          Text('Uploading image…',
              style: GoogleFonts.manrope(
                  fontSize: 13, color: Colors.grey[500])),
        ]),
      );
    }

    if (_previewBytes != null || _uploadedImageUrl != null) {
      return Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _previewBytes != null
              ? Image.memory(_previewBytes!,
                  width: double.infinity, height: 200, fit: BoxFit.cover)
              : Image.network(_uploadedImageUrl!,
                  width: double.infinity, height: 200, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imageBox(
                      child: const Icon(Icons.broken_image_outlined,
                          size: 40, color: Colors.grey))),
        ),
        Positioned(
          top: 8, right: 48,
          child: _overlayBtn(Icons.edit, 'Change',
              const Color(0xFF1A1A1A), _pickAndUploadImage),
        ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () => setState(() {
              _uploadedImageUrl = null;
              _previewBytes     = null;
            }),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        if (_uploadedImageUrl != null)
          Positioned(
            bottom: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text('Uploaded',
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]);
    }

    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: _imageBox(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE), shape: BoxShape.circle),
            child: const Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text('Tap to upload image',
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('JPG, PNG or WebP · max 5 MB',
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
          if (_imageError != null) ...[
            const SizedBox(height: 10),
            Text(_imageError!,
                style: GoogleFonts.manrope(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }

  Widget _imageBox({required Widget child}) => Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: _imageError != null
                  ? Colors.red.shade300
                  : const Color(0xFFDDDDDD),
              width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );

  Widget _overlayBtn(
      IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: color.withOpacity(0.88),
              borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _buildCollectionDropdown() {
    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text('None', style: GoogleFonts.manrope(fontSize: 13)),
      ),
      ..._collections.map((c) => DropdownMenuItem<String?>(
            value: c['id']?.toString(),
            child: Text(c['name']?.toString() ?? '',
                style: GoogleFonts.manrope(fontSize: 13)),
          )),
    ];

    return DropdownButtonFormField<String?>(
      value: _selectedCollectionId,
      decoration: _inputDecoration('Collection (optional)'),
      items: items,
      onChanged: (v) => setState(() => _selectedCollectionId = v),
      isExpanded: true,
    );
  }

  Widget _buildStringDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) itemLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(itemLabel(s),
                    style: GoogleFonts.manrope(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      );
}