// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

// ─── App Nav Bar ──────────────────────────────────────────────────────────────
class AppNavBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final bool showBack;
  const AppNavBar({super.key, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  ConsumerState<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends ConsumerState<AppNavBar> {
  List<dynamic> _categories = [];
  bool _categoriesLoaded = false;
  final LayerLink _shopLayerLink = LayerLink();
  OverlayEntry? _shopOverlay;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _removeShopOverlay();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await apiService.getCategories();
      if (mounted) setState(() { _categories = data; _categoriesLoaded = true; });
    } catch (_) {}
  }

  void _showShopDropdown(BuildContext context) {
    _removeShopOverlay();
    final overlay = Overlay.of(context);

    _shopOverlay = OverlayEntry(
      builder: (_) => _ShopMegaMenu(
        layerLink: _shopLayerLink,
        onClose: _removeShopOverlay,
        onNavigate: (path) {
          _removeShopOverlay();
          context.go(path);
        },
      ),
    );
    overlay.insert(_shopOverlay!);
  }

  void _removeShopOverlay() {
    _shopOverlay?.remove();
    _shopOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartProvider).fold<int>(0, (s, i) => s + i.quantity);
    final user = ref.watch(userProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    return AppBar(
      backgroundColor: AppColors.surface.withOpacity(0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (widget.showBack) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => context.pop(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
            ],

            // Logo
            GestureDetector(
              onTap: () { _removeShopOverlay(); context.go('/'); },
              child: Text('TRIPLE A',
                  style: GoogleFonts.newsreader(
                      fontSize: 24, fontWeight: FontWeight.w700,
                      color: AppColors.primary, letterSpacing: 2)),
            ),

            if (isWide) ...[
              const SizedBox(width: 48),

              // ── SHOP with mega-dropdown (now shows T-shirt types) ──
              CompositedTransformTarget(
                link: _shopLayerLink,
                child: _ShopNavButton(
                  onTap: () => _showShopDropdown(context),
                  onClose: _removeShopOverlay,
                ),
              ),

              const SizedBox(width: 32),

              // ── OUR STORY (replaces NEW ARRIVALS) ──
              _NavLink(
                label: 'OUR STORY',
                onTap: () { _removeShopOverlay(); context.go('/about'); },
              ),
              // REMOVED: _NavLink(label: 'NEW ARRIVALS', ...)
            ],

            const Spacer(),

            // Search
            IconButton(
              icon: const Icon(Icons.search_outlined, size: 22),
              onPressed: () { _removeShopOverlay(); context.go('/products'); },
              color: AppColors.primary,
              tooltip: 'Search',
            ),

            // ── Wishlist icon (logged-in users only) ──────────────────
            if (user.isLoggedIn)
              IconButton(
                icon: const Icon(Icons.favorite_border, size: 22),
                onPressed: () { _removeShopOverlay(); context.go('/wishlist'); },
                color: AppColors.primary,
                tooltip: 'Wishlist',
              ),

            // User menu
            if (user.isLoggedIn)
              _UserMenu(user: user, ref: ref, onTap: _removeShopOverlay)
            else
              TextButton(
                onPressed: () { _removeShopOverlay(); context.go('/login'); },
                child: Text('LOGIN',
                    style: GoogleFonts.manrope(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, color: AppColors.primary)),
              ),

            // Cart
            badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text(cartCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
              badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.secondary, padding: EdgeInsets.all(5)),
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                onPressed: () { _removeShopOverlay(); context.go('/cart'); },
                color: AppColors.primary,
                tooltip: 'Cart',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SHOP nav button ──────────────────────────────────────────────────────────
class _ShopNavButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onClose;
  const _ShopNavButton({required this.onTap, required this.onClose});

  @override
  State<_ShopNavButton> createState() => _ShopNavButtonState();
}

class _ShopNavButtonState extends State<_ShopNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { setState(() => _hovered = true); widget.onTap(); },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SHOP',
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: _hovered
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.7))),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down,
                size: 16,
                color: _hovered
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ─── SHOP Mega-Menu Overlay (updated: shows T-shirt types, not categories) ────
class _ShopMegaMenu extends StatefulWidget {
  final LayerLink layerLink;
  final VoidCallback onClose;
  final Function(String) onNavigate;

  const _ShopMegaMenu({
    required this.layerLink,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  State<_ShopMegaMenu> createState() => _ShopMegaMenuState();
}

class _ShopMegaMenuState extends State<_ShopMegaMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  // T-shirt types for dropdown
  static const List<(String, String?)> _types = [
    ('All',          null),
    ('Oversized',    'oversized'),
    ('Polo',         'polo'),
    ('Full Sleeve',  'full-sleeve'),
    ('Half Sleeve',  'half-sleeve'),
    ('Drop Shoulder','drop-shoulder'),
    ('Basic',        'basic'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss tap area
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // The dropdown panel
        CompositedTransformFollower(
          link: widget.layerLink,
          offset: const Offset(-16, 60),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: MouseRegion(
                  onExit: (_) => widget.onClose(),
                  child: Container(
                    width: 520,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.outlineVariant.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withOpacity(0.2)),
                            ),
                          ),
                          child: Row(children: [
                            Text('SHOP BY TYPE',
                                style: GoogleFonts.manrope(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    letterSpacing: 2.5,
                                    color: AppColors.tertiary)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => widget.onNavigate('/products'),
                              child: Text('View All →',
                                  style: GoogleFonts.manrope(
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            ),
                          ]),
                        ),

                        // Two columns: Men's | Women's — each listing types
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Men's column
                              Expanded(
                                child: _TypeColumn(
                                  gender: 'men',
                                  label: "MEN'S",
                                  icon: '👔',
                                  types: _types,
                                  onNavigate: widget.onNavigate,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 220,
                                color: AppColors.outlineVariant.withOpacity(0.3),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              // Women's column
                              Expanded(
                                child: _TypeColumn(
                                  gender: 'women',
                                  label: "WOMEN'S",
                                  icon: '👗',
                                  types: _types,
                                  onNavigate: widget.onNavigate,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Footer
                        GestureDetector(
                          onTap: () => widget.onNavigate('/products'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              border: Border(
                                top: BorderSide(
                                    color: AppColors.outlineVariant
                                        .withOpacity(0.2)),
                              ),
                            ),
                            child: Row(children: [
                              const Text('🛍️',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Text('Browse All T-Shirts',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                              const Spacer(),
                              const Icon(Icons.arrow_forward,
                                  size: 14, color: AppColors.outline),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Type Column inside mega-menu (replaces _GenderColumn) ───────────────────
class _TypeColumn extends StatelessWidget {
  final String gender;
  final String label;
  final String icon;
  final List<(String, String?)> types;
  final Function(String) onNavigate;

  const _TypeColumn({
    required this.gender,
    required this.label,
    required this.icon,
    required this.types,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender header
        GestureDetector(
          onTap: () => onNavigate('/products?gender=$gender'),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.newsreader(
                    fontSize: 18, fontWeight: FontWeight.w500,
                    color: AppColors.onSurface)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 13, color: AppColors.outline),
          ]),
        ),
        const SizedBox(height: 4),
        Container(
            height: 1.5,
            width: 40,
            color: AppColors.primary.withOpacity(0.3)),
        const SizedBox(height: 12),

        // Type list
        ...types.map((t) {
          final typeName  = t.$1;
          final typeValue = t.$2;
          final path = typeValue != null
              ? '/products?gender=$gender&type=$typeValue'
              : '/products?gender=$gender';
          return _TypeMenuItem(
            name: typeName,
            isHeader: typeValue == null,
            onTap: () => onNavigate(path),
          );
        }),
      ],
    );
  }
}

// ─── Single type item in mega-menu ───────────────────────────────────────────
class _TypeMenuItem extends StatefulWidget {
  final String name;
  final bool isHeader;
  final VoidCallback onTap;
  const _TypeMenuItem(
      {required this.name, required this.isHeader, required this.onTap});

  @override
  State<_TypeMenuItem> createState() => _TypeMenuItemState();
}

class _TypeMenuItemState extends State<_TypeMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _hovered ? 8 : 4,
              height: 1.5,
              color: AppColors.primary,
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              widget.name,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: widget.isHeader
                      ? FontWeight.w700
                      : (_hovered ? FontWeight.w600 : FontWeight.w400),
                  color: widget.isHeader
                      ? AppColors.primary
                      : (_hovered
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── User Menu ────────────────────────────────────────────────────────────────
class _UserMenu extends StatelessWidget {
  final UserState user;
  final WidgetRef ref;
  final VoidCallback onTap;
  const _UserMenu({required this.user, required this.ref, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        onTap();
        if (val == 'orders') context.go('/my-orders');
        if (val == 'wishlist') context.go('/wishlist');
        if (val == 'track') context.go('/track-order');
        if (val == 'logout') {
          await ref.read(userProvider.notifier).logout();
          ref.read(cartProvider.notifier).clear();
          if (context.mounted) context.go('/');
        }
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user.name,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'orders',
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('My Orders', style: GoogleFonts.manrope(fontSize: 13)),
          ]),
        ),
        // ── Wishlist added to user menu ──
        PopupMenuItem(
          value: 'wishlist',
          child: Row(children: [
            const Icon(Icons.favorite_border,
                size: 16, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text('My Wishlist', style: GoogleFonts.manrope(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'track',
          child: Row(children: [
            const Icon(Icons.local_shipping_outlined,
                size: 16, color: AppColors.tertiary),
            const SizedBox(width: 10),
            Text('Track Order', style: GoogleFonts.manrope(fontSize: 13)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            const Icon(Icons.logout, size: 16, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text('Sign Out',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.secondary)),
          ]),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          Text(user.name.split(' ').first,
              style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const Icon(Icons.arrow_drop_down,
              size: 18, color: AppColors.primary),
        ]),
      ),
    );
  }
}

// ─── Plain nav link ───────────────────────────────────────────────────────────
class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.primary.withOpacity(0.7))),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class ProductCard extends StatefulWidget {
  final dynamic product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = p['image_url'];
    final inStock = (p['stock'] ?? 0) > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(fit: StackFit.expand, children: [
                AnimatedScale(
                  scale: _hovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                if (!inStock)
                  Container(
                    color: Colors.black.withOpacity(0.4),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: Colors.white.withOpacity(0.9),
                      child: Text('SOLD OUT',
                          style: GoogleFonts.manrope(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: AppColors.onSurface)),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(p['categories']?['name'] ?? '',
              style: GoogleFonts.manrope(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: AppColors.tertiary)),
          const SizedBox(height: 4),
          Text(p['name'] ?? '',
              style: GoogleFonts.newsreader(
                  fontSize: 16, fontWeight: FontWeight.w500,
                  color: AppColors.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('৳ ${(p['price'] ?? 0).toStringAsFixed(0)}',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: AppColors.surfaceLow,
      child: const Icon(Icons.image_outlined,
          color: AppColors.outline, size: 40));
}

// ─── Status Chip ──────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending':    (AppColors.pending,    const Color(0xFFFFF8E1)),
      'processing': (AppColors.processing, const Color(0xFFE3F2FD)),
      'completed':  (AppColors.completed,  const Color(0xFFE8F5E9)),
      'cancelled':  (AppColors.cancelled,  const Color(0xFFFFEBEE)),
    };
    final (fg, bg) =
        colors[status] ?? (AppColors.outline, AppColors.surfaceLow);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.manrope(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: fg)),
    );
  }
}

// ─── Shimmer Box ──────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox(
      {super.key,
      required this.width,
      required this.height,
      this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}