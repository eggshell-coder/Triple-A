// lib/config/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens matching the Editorial Heritage system from Stitch design
class AppColors {
  static const primary = Color(0xFF112619);
  static const primaryContainer = Color(0xFF273C2D);
  static const secondary = Color(0xFFAF2B3E);
  static const tertiary = Color(0xFF735C00);
  static const surface = Color(0xFFFAF9F5);
  static const surfaceLow = Color(0xFFF4F4F0);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFE9E8E4);
  static const surfaceHighest = Color(0xFFE3E2DF);
  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF444842);
  static const outline = Color(0xFF747872);
  static const outlineVariant = Color(0xFFC4C8C0);
  static const onPrimary = Color(0xFFFFFFFF);
  static const error = Color(0xFFBA1A1A);

  // Status colors
  static const pending = Color(0xFF735C00);
  static const processing = Color(0xFF1565C0);
  static const completed = Color(0xFF2E7D32);
  static const cancelled = Color(0xFFAF2B3E);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withOpacity(0.85),
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.newsreader(
          color: AppColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.newsreader(
          fontSize: 56, fontWeight: FontWeight.w300,
          color: AppColors.onSurface, letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.newsreader(
          fontSize: 45, fontWeight: FontWeight.w300,
          color: AppColors.onSurface, letterSpacing: -1.5,
        ),
        headlineLarge: GoogleFonts.newsreader(
          fontSize: 32, fontWeight: FontWeight.w400,
          color: AppColors.onSurface, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.newsreader(
          fontSize: 28, fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        titleLarge: GoogleFonts.newsreader(
          fontSize: 22, fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppColors.onSurface, letterSpacing: 1.5,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant, letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.manrope(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.manrope(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant),
        hintStyle: GoogleFonts.manrope(fontSize: 14, color: AppColors.outline),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
       cardTheme: CardThemeData(
        color: AppColors.surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        shadowColor: AppColors.onSurface.withOpacity(0.06),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withOpacity(0.3),
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.manrope(fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
