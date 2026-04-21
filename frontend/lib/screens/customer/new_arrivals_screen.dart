// lib/screens/customer/new_arrivals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class NewArrivalsScreen extends ConsumerStatefulWidget {
  const NewArrivalsScreen({super.key});
  @override
  ConsumerState<NewArrivalsScreen> createState() => _NewArrivalsScreenState();
}

class _NewArrivalsScreenState extends ConsumerState<NewArrivalsScreen> {
  List<Map<String, dynamic>> _collections = [];
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
      final data = await apiService.getCollections();
      if (mounted) setState(() { _collections = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _bgColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('summer')) return const Color(0xFFFFF8E1);
    if (n.contains('winter')) return const Color(0xFFE3F2FD);
    if (n.contains('spring')) return const Color(0xFFF1F8E9);
    if (n.contains('eid') || n.contains('special')) return const Color(0xFFFCE4EC);
    if (n.contains('street') || n.contains('casual')) return const Color(0xFFF3E5F5);
    return const Color(0xFFF3F0E8);
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
                      Text('Failed to load collections',
                          style: GoogleFonts.manrope(
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                )
              : _collections.isEmpty
                  ? Center(
                      child: Text('No collections available yet',
                          style: GoogleFonts.newsreader(
                              fontSize: 18, color: AppColors.outline)))
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(40, 48, 40, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SEASONAL & EVENT COLLECTIONS',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                    color: AppColors.tertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'New Arrivals',
                                  style: GoogleFonts.newsreader(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 4 : 2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final col = _collections[i];
                                return _CollectionCard(
                                  collection: col,
                                  bgColor: _bgColor(col['name'] ?? ''),
                                  onTap: () => context
                                      .go('/collections/${col['slug']}'),
                                );
                              },
                              childCount: _collections.length,
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final Color bgColor;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = collection['badge'] as String?;
    final imageUrl = (collection['image_url'] ?? '').toString();
    final name = (collection['name'] ?? '').toString();
    final description = (collection['description'] ?? '').toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            SizedBox(
              height: 190,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: bgColor,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined,
                            size: 34, color: Color(0xFF112619)),
                      ),
                    )
                  : Container(
                      color: bgColor,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined,
                          size: 34, color: Color(0xFF112619)),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null && badge.trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF112619),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    Text(
                      name,
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF112619),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description.isEmpty
                          ? 'Explore this seasonal collection'
                          : description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.55),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'VIEW COLLECTION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.black.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 12,
                            color: Colors.black.withOpacity(0.65)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}