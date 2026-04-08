import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette (Dark Mode)
  static const Color primary = Color(0xFF00D05A); // Original Neon Green
  static const Color accent = Color(0xFF00B34D);
  static const Color highlight = Color(0xFF00D05A);
  static const Color success = Color(0xFF00D05A);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF4D4D);

  // Dark Surface Colors
  static const Color background = Color(0xFF0E1111);
  static const Color surface = Color(0xFF1A1D1E);
  static const Color cardBg = Color(0xFF1A1D1E);

  // Gradient Colors
  static const List<Color> primaryGradient = [Color(0xFF00D05A), Color(0xFF00B34D)];
  static const List<Color> accentGradient = [Color(0xFF1A1D1E), Color(0xFF0E1111)];
  static const List<Color> successGradient = [Color(0xFF00D05A), Color(0xFF00B34D)];

  // Dark Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF666666);
}

/// Light-mode color tokens matching the "Monifi" UI in the user image
class LightColors {
  static const Color primary = Color(0xFF3861FB);          // Vibrant Monifi Blue
  static const Color background = Color(0xFFF8F9FB);       // Clean Light Background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D1E);      // Deep Charcoal
  static const Color textSecondary = Color(0xFF6C727A);    // Modern Gray
  static const Color textHint = Color(0xFF9EA4AC);
  static const Color divider = Color(0xFFEDF0F3);
}

class AppTheme {
  // ─── Dark Theme ───────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          bodyLarge: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary),
          bodyMedium: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  // ─── Light Theme ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const textPrimary = LightColors.textPrimary;
    const textSecondary = LightColors.textSecondary;
    const lPrimary = LightColors.primary;

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lPrimary,
      scaffoldBackgroundColor: LightColors.background,
      colorScheme: const ColorScheme.light(
        primary: lPrimary,
        secondary: lPrimary,
        surface: LightColors.surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.background,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
          bodyLarge: GoogleFonts.outfit(fontSize: 16, color: textSecondary),
          bodyMedium: GoogleFonts.outfit(fontSize: 14, color: textSecondary),
          titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
          titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        ),
      ),
      cardTheme: CardThemeData(
        color: LightColors.cardBg,
        elevation: 4,                        // Soft Shadow as seen in Monifi
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: LightColors.divider, width: 1),
        ),
      ),
      dividerColor: LightColors.divider,
      iconTheme: const IconThemeData(color: textSecondary),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? lPrimary : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? lPrimary.withOpacity(0.35) : Colors.grey.shade300,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LightColors.surface,
        indicatorColor: lPrimary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? lPrimary : textSecondary,
          ),
        ),
      ),
    );
  }
}
