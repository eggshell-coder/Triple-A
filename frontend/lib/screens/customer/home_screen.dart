// home_screen.dart — UPDATED AGAIN
// Layout:
// 1. Navbar at the very top
// 2. MEN'S / WOMEN'S showcase
// 3. Collections
// 4. Featured products
// 5. Footer with TRIPLE A + tagline + social/contact icons

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _collections = [];
  List<dynamic> _featuredProducts = [];
  bool _loadingCollections = true;
  bool _loadingProducts = true;

  int _carouselIndex = 0;
  Timer? _carouselTimer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchCollections();
    _fetchFeaturedProducts();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchCollections() async {
    try {
      final data = await apiService.getCollections();
      if (!mounted) return;

      setState(() {
        _collections = data;
        _loadingCollections = false;
      });

      if (data.length > 1) {
        _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          if (!mounted) return;
          final next = (_carouselIndex + 1) % _collections.length;
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCollections = false);
      }
    }
  }

  Future<void> _fetchFeaturedProducts() async {
    try {
      final data = await apiService.getFeaturedProducts();
      if (!mounted) return;

      setState(() {
        _featuredProducts = data;
        _loadingProducts = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProducts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: CustomScrollView(
        slivers: [
          // Navbar always on top
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            automaticallyImplyLeading: false,
            toolbarHeight: 60,
            flexibleSpace: const FlexibleSpaceBar(
              background: AppNavBar(),
            ),
          ),

          // MEN'S / WOMEN'S
          const SliverToBoxAdapter(
            child: _GenderBannerSection(),
          ),

          // COLLECTIONS
          SliverToBoxAdapter(
            child: _CollectionCarouselSection(
              collections: _collections,
              loading: _loadingCollections,
              pageController: _pageController,
              currentIndex: _carouselIndex,
              onPageChanged: (i) => setState(() => _carouselIndex = i),
            ),
          ),

          // FEATURED PRODUCTS
          SliverToBoxAdapter(
            child: _ProductShowcaseSection(
              products: _featuredProducts,
              loading: _loadingProducts,
            ),
          ),

          // FOOTER
          const SliverToBoxAdapter(
            child: _FooterSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

// ── Men / Women Banners ────────────────────────────────────────────────────
class _GenderBannerSection extends StatelessWidget {
  const _GenderBannerSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: _GenderBanner(
              label: "MEN'S",
              gender: 'men',
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GenderBanner(
              label: "WOMEN'S",
              gender: 'women',
              color: const Color(0xFF8B5A6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderBanner extends StatelessWidget {
  final String label;
  final String gender;
  final Color color;

  const _GenderBanner({
    required this.label,
    required this.gender,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/products?gender=$gender'),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Shop Now',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Collection Carousel ────────────────────────────────────────────────────
class _CollectionCarouselSection extends StatelessWidget {
  final List<dynamic> collections;
  final bool loading;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _CollectionCarouselSection({
    required this.collections,
    required this.loading,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'COLLECTIONS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (collections.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(child: Text('No collections yet.')),
            )
          else
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: collections.length,
                    itemBuilder: (_, i) =>
                        _CollectionSlide(collection: collections[i]),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        collections.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: currentIndex == i ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: currentIndex == i
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          final prev = (currentIndex - 1 + collections.length) %
                              collections.length;
                          pageController.animateToPage(
                            prev,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          final next =
                              (currentIndex + 1) % collections.length;
                          pageController.animateToPage(
                            next,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionSlide extends StatelessWidget {
  final dynamic collection;

  const _CollectionSlide({required this.collection});

  @override
  Widget build(BuildContext context) {
    final slug = collection['slug'] as String;
    final name = collection['name'] as String;
    final image = collection['image'] as String?;

    return GestureDetector(
      onTap: () => context.go('/collections/$slug'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF333333),
            image: image != null
                ? DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.35),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore →',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product Showcase ───────────────────────────────────────────────────────
class _ProductShowcaseSection extends StatelessWidget {
  final List<dynamic> products;
  final bool loading;

  const _ProductShowcaseSection({
    required this.products,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Text(
            'FEATURED',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        if (loading)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) => _HomeProductCard(product: products[i]),
          ),
        if (!loading && products.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: OutlinedButton(
                onPressed: () => context.go('/products'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  side: const BorderSide(
                    color: Color(0xFF1A1A1A),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  final dynamic product;

  const _HomeProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final id = product['id'];
    final name = product['name'] as String? ?? '';
    final price = product['price'];
    final image = product['image_url'] as String? ?? product['image'] as String?;

    return GestureDetector(
      onTap: () => context.go('/products/$id'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: image != null
                    ? Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFFE5E5E5),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳$price',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Text(
            'TRIPLE A',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Premium T-shirts crafted for the streets of Bangladesh.\nWear what defines you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _FooterSocialIcon(Icons.facebook),
              _FooterSocialIcon(Icons.camera_alt),
              _FooterSocialIcon(Icons.play_circle),
              _FooterSocialIcon(Icons.email_outlined),
              _FooterSocialIcon(Icons.phone_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterSocialIcon extends StatelessWidget {
  final IconData icon;

  const _FooterSocialIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}