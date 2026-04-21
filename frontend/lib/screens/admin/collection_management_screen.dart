// lib/screens/admin/collection_management_screen.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';

class CollectionManagementScreen extends ConsumerStatefulWidget {
  const CollectionManagementScreen({super.key});
  @override
  ConsumerState<CollectionManagementScreen> createState() =>
      _CollectionManagementScreenState();
}

class _CollectionManagementScreenState
    extends ConsumerState<CollectionManagementScreen> {
  List<dynamic> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getCollectionsAdmin();
      if (mounted) setState(() { _collections = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForm({Map<String, dynamic>? collection}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CollectionFormDialog(
        collection: collection,
        onSaved: _load,
      ),
    );
  }

  Future<void> _toggleActive(String id, String name, bool currentlyActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(currentlyActive ? 'Hide Collection' : 'Show Collection',
            style: GoogleFonts.newsreader(fontSize: 20)),
        content: Text(
          currentlyActive
              ? 'Hide "$name" from New Arrivals?'
              : 'Show "$name" in New Arrivals again?',
          style: GoogleFonts.manrope(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    currentlyActive ? AppColors.tertiary : AppColors.completed),
            child: Text(currentlyActive ? 'HIDE' : 'SHOW'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await apiService.updateCollection(id, {'is_active': !currentlyActive});
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(currentlyActive
                  ? '"$name" hidden from New Arrivals'
                  : '"$name" is now visible')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteCollection(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Delete Collection',
            style: GoogleFonts.newsreader(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permanently delete "$name"?',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFFEBEE),
              child: Text(
                'Products in this collection will not be deleted — they will just be unassigned.',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.secondary, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await apiService.deleteCollection(id);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Collection deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Collections',
      activePath: '/admin/collections',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('NEW COLLECTION'),
        ),
      ],
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _collections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.collections_bookmark_outlined,
                              size: 56, color: AppColors.outline),
                          const SizedBox(height: 16),
                          Text('No collections yet',
                              style: GoogleFonts.newsreader(
                                  fontSize: 20, color: AppColors.outline)),
                          const SizedBox(height: 8),
                          Text(
                              'Create collections like Summer 2026, Eid Special, Winter...',
                              style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('CREATE FIRST COLLECTION'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0xFFF0F7F1),
                            child: Row(children: [
                              const Icon(Icons.info_outline,
                                  size: 18, color: AppColors.completed),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Collections appear in New Arrivals. Assign products to a collection from the Products page using the Collection dropdown in the product form.',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.5),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            color: AppColors.surfaceLowest,
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                color: AppColors.surfaceLow,
                                child: Row(children: [
                                  _H('COLLECTION', flex: 4),
                                  _H('SLUG', flex: 3),
                                  _H('BADGE', flex: 2),
                                  _H('ORDER', flex: 1),
                                  _H('STATUS', flex: 2),
                                  _H('ACTIONS', flex: 3),
                                ]),
                              ),
                              ..._collections.map((c) => _CollectionRow(
                                    collection: c,
                                    onEdit: () => _openForm(collection: c),
                                    onToggleActive: () => _toggleActive(
                                        c['id'],
                                        c['name'],
                                        c['is_active'] == true),
                                    onDelete: () =>
                                        _deleteCollection(c['id'], c['name']),
                                  )),
                            ]),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}

// ─── Header Cell ──────────────────────────────────────────────────────────────
class _H extends StatelessWidget {
  final String text;
  final int flex;
  const _H(this.text, {required this.flex});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant)),
      );
}

// ─── Collection Row ───────────────────────────────────────────────────────────
class _CollectionRow extends StatelessWidget {
  final dynamic collection;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _CollectionRow({
    required this.collection,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = collection['is_active'] == true;
    final badge = collection['badge'] as String?;
    final imageUrl = (collection['image_url'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.2)))),
      child: Row(children: [
        Expanded(
            flex: 4,
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 18,
                            color: AppColors.outline))
                    : const Icon(Icons.image_outlined,
                        size: 18, color: AppColors.outline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(collection['name'] ?? '',
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (collection['description'] != null)
                    Text(collection['description'],
                        style: GoogleFonts.manrope(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ]),
              ),
            ])),
        Expanded(
            flex: 3,
            child: Text(collection['slug'] ?? '—',
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppColors.onSurfaceVariant))),
        Expanded(
            flex: 2,
            child: badge != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1)),
                  )
                : Text('—',
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.outline))),
        Expanded(
            flex: 1,
            child: Text('${collection['sort_order'] ?? 0}',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.onSurfaceVariant))),
        Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(isActive ? 'VISIBLE' : 'HIDDEN',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isActive
                          ? AppColors.completed
                          : AppColors.secondary)),
            )),
        Expanded(
            flex: 3,
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  color: AppColors.primary,
                  tooltip: 'Edit'),
              IconButton(
                  icon: Icon(
                      isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18),
                  onPressed: onToggleActive,
                  color: AppColors.tertiary,
                  tooltip: isActive ? 'Hide' : 'Show'),
              IconButton(
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  onPressed: onDelete,
                  color: AppColors.secondary,
                  tooltip: 'Delete'),
            ])),
      ]),
    );
  }
}

// ─── Collection Form Dialog ───────────────────────────────────────────────────
class _CollectionFormDialog extends StatefulWidget {
  final Map<String, dynamic>? collection;
  final VoidCallback onSaved;
  const _CollectionFormDialog({this.collection, required this.onSaved});

  @override
  State<_CollectionFormDialog> createState() => _CollectionFormDialogState();
}

class _CollectionFormDialogState extends State<_CollectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _orderCtrl;
  bool _isActive = true;
  bool _saving = false;

  // Image state — pending = picked but not yet uploaded
  String? _imageUrl;        // existing URL (from DB) or local blob preview
  List<int>? _pendingBytes; // raw bytes waiting to upload on save
  String? _pendingFileName;

  final _badgePresets = ['NEW', 'HOT', 'EID', 'SALE', 'LIMITED'];

  @override
  void initState() {
    super.initState();
    final c = widget.collection;
    _nameCtrl = TextEditingController(text: c?['name'] ?? '');
    _descCtrl = TextEditingController(text: c?['description'] ?? '');
    _slugCtrl = TextEditingController(text: c?['slug'] ?? '');
    _badgeCtrl = TextEditingController(text: c?['badge'] ?? '');
    _orderCtrl = TextEditingController(text: (c?['sort_order'] ?? 0).toString());
    _isActive = c?['is_active'] ?? true;
    _imageUrl = c?['image_url'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _slugCtrl.dispose();
    _badgeCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _autoSlug(String name) {
    if (widget.collection != null) return;
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    _slugCtrl.text = slug;
  }

  // Only picks the file and stores bytes locally — does NOT upload yet
  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;

    final file = input.files![0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = reader.result as List<int>;
    final previewUrl = html.Url.createObjectUrlFromBlob(file);

    setState(() {
      _pendingBytes = bytes;
      _pendingFileName = file.name;
      _imageUrl = previewUrl; // local blob for preview only
    });
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _pendingBytes = null;
      _pendingFileName = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Upload image now during save — token is guaranteed available here
      if (_pendingBytes != null && _pendingFileName != null) {
        final uploadedUrl = await apiService.uploadProductImage(
            _pendingBytes!, _pendingFileName!);
        _imageUrl = uploadedUrl;
        _pendingBytes = null;
        _pendingFileName = null;
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        'badge': _badgeCtrl.text.trim().isEmpty
            ? null
            : _badgeCtrl.text.trim().toUpperCase(),
        'sort_order': int.tryParse(_orderCtrl.text) ?? 0,
        'is_active': _isActive,
        'image_url': _imageUrl,
      };

      if (widget.collection != null) {
        await apiService.updateCollection(widget.collection!['id'], data);
      } else {
        await apiService.createCollection(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.collection != null;
    final hasPending = _pendingBytes != null;

    return Dialog(
      backgroundColor: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Collection' : 'New Collection',
                    style: GoogleFonts.newsreader(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurface)),
                const SizedBox(height: 6),
                Text(
                    'Collections group products by season or event in New Arrivals.',
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          onChanged: _autoSlug,
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: AppColors.onSurface),
                          decoration: const InputDecoration(
                              labelText: 'Collection Name *',
                              hintText: 'e.g. Summer 2026, Eid Special'),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: AppColors.onSurface),
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText:
                                  'Short description shown on collection card'),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _slugCtrl,
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: AppColors.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'URL Slug *',
                            hintText: 'e.g. summer-2026',
                            helperText:
                                'Auto-generated. Only letters, numbers, hyphens.',
                          ),
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Required';
                            if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                              return 'Only lowercase letters, numbers, hyphens';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Collection Image
                        Text('Collection Image',
                            style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLow,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: hasPending
                                        ? AppColors.tertiary
                                        : AppColors.outlineVariant),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _imageUrl != null && _imageUrl!.isNotEmpty
                                  ? Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(
                                              Icons.broken_image_outlined,
                                              color: AppColors.outline),
                                    )
                                  : const Icon(Icons.image_outlined,
                                      size: 32, color: AppColors.outline),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.upload_outlined,
                                      size: 16),
                                  label: const Text('CHOOSE IMAGE'),
                                  style: ElevatedButton.styleFrom(
                                      textStyle: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ),
                                if (hasPending) ...[
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.check_circle,
                                        size: 14, color: AppColors.completed),
                                    const SizedBox(width: 4),
                                    Text('Ready to upload',
                                        style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            color: AppColors.completed)),
                                  ]),
                                ],
                                if (_imageUrl != null && _imageUrl!.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.close, size: 14),
                                    label: const Text('REMOVE'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.secondary,
                                        textStyle: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                const SizedBox(height: 4),
                                Text('JPG, PNG recommended',
                                    style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _badgeCtrl,
                              style: GoogleFonts.manrope(
                                  fontSize: 14, color: AppColors.onSurface),
                              decoration: const InputDecoration(
                                  labelText: 'Badge Label (optional)',
                                  hintText: 'e.g. NEW, HOT, EID'),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: _badgePresets
                                  .map((b) => GestureDetector(
                                        onTap: () => setState(
                                            () => _badgeCtrl.text = b),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _badgeCtrl.text == b
                                                ? AppColors.primary
                                                : AppColors.surfaceLow,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: _badgeCtrl.text == b
                                                    ? AppColors.primary
                                                    : AppColors.outlineVariant),
                                          ),
                                          child: Text(b,
                                              style: GoogleFonts.manrope(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _badgeCtrl.text == b
                                                      ? Colors.white
                                                      : AppColors
                                                          .onSurfaceVariant)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _orderCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.manrope(
                              fontSize: 14, color: AppColors.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'Display Order',
                            helperText: 'Lower number = appears first',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          color: AppColors.surfaceLow,
                          child: Row(children: [
                            Switch(
                                value: _isActive,
                                onChanged: (v) =>
                                    setState(() => _isActive = v),
                                activeColor: AppColors.primary),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Visible in New Arrivals',
                                    style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface)),
                                Text(
                                    _isActive
                                        ? 'Customers can see this collection'
                                        : 'Hidden from customers',
                                    style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? 'SAVE CHANGES' : 'CREATE COLLECTION'),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}