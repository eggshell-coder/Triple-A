// lib/config/responsive.dart
// Centralised responsive rules so every screen sizes images the same way.
//
// Why this exists: product images were using a single hard-coded
// aspect ratio (0.8 / 0.72) on every screen size. On phones that made
// cards very tall — the image ate most of the tile and the product
// name got squeezed out. These helpers give us one standard look.

import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  // ── Breakpoints ────────────────────────────────────────────────────────────
  // Phone  : 0   – 599
  // Tablet : 600 – 1023
  // Desktop: 1024 +
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static bool isPhone(BuildContext c) => width(c) < tabletBreakpoint;
  static bool isTablet(BuildContext c) =>
      width(c) >= tabletBreakpoint && width(c) < desktopBreakpoint;
  static bool isDesktop(BuildContext c) => width(c) >= desktopBreakpoint;

  static double width(BuildContext c) => MediaQuery.of(c).size.width;

  // ── Standard product image ratio ──────────────────────────────────────────
  // 3:4 portrait is the fashion-retail standard (0.75). Every grid and
  // detail page uses this so tiles line up in a clean row.
  static const double productImageRatio = 0.75;

  // Detail page can be a touch taller — it's the hero image.
  static const double productDetailRatio = 0.82;

  // ── Grid columns ──────────────────────────────────────────────────────────
  static int productColumns(BuildContext c) {
    if (isDesktop(c)) return 5;
    if (isTablet(c)) return 4;
    return 2;
  }

  // Layout documentation kept next to the values so the two stay in sync:
  //   Phone  (< 600) → 2 columns
  //   Tablet (600–1023) → 4 columns
  //   Desktop (≥ 1024) → 5 columns

  // ── Page padding ──────────────────────────────────────────────────────────
  static EdgeInsets pagePadding(BuildContext c) {
    if (isPhone(c)) return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    if (isTablet(c)) return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 48);
  }

  // ── Detail page hero image height ─────────────────────────────────────────
  /// Caps the hero image so it never takes more than the viewport height.
  static double detailImageHeight(BuildContext c) {
    final screen = MediaQuery.of(c).size.height;
    if (isPhone(c)) {
      // On phones: at most ~45% of the screen, so the name / price /
      // Add to Cart button stay visible without scrolling past a huge photo.
      return (screen * 0.35).clamp(200.0, 340.0); 
    }
    return (screen * 0.72).clamp(420.0, 820.0);
  }

  /// Scales headline text down on small screens.
  static double detailTitleSize(BuildContext c) {
    if (isPhone(c)) return 24;
    if (isTablet(c)) return 30;
    return 36;
  }

  static double detailPriceSize(BuildContext c) {
    if (isPhone(c)) return 20;
    return 24;
  }

  // ── Grid delegate ──────────────────────────────────────────────────────────
  /// Standard product grid used across home / products / new arrivals /
  /// collection / wishlist so all grids look identical.
  static SliverGridDelegateWithFixedCrossAxisCount productGrid(BuildContext c) {
    final phone = isPhone(c);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: productColumns(c),
      // Card = image (3:4) + name/price block, hence a portrait-ish tile.
      childAspectRatio: phone ? 0.58 : 0.62,
      crossAxisSpacing: phone ? 10 : 16,
      mainAxisSpacing: phone ? 10 : 16,
    );
  }
}