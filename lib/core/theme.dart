import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF00D05A); // Neon Green
  static const Color accent = Color(0xFF00B34D); // Slightly darker green
  static const Color highlight = Color(0xFF00D05A);
  static const Color success = Color(0xFF00D05A);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF4D4D);

  // Surface Colors
  static const Color background = Color(0xFF0E1111); // Deep Charcoal
  static const Color surface = Color(0xFF1A1D1E);    // Dark Grey Surface
  static const Color cardBg = Color(0xFF1A1D1E);

  // Gradient Colors
  static const List<Color> primaryGradient = [Color(0xFF00D05A), Color(0xFF00B34D)];
  static const List<Color> accentGradient = [Color(0xFF1A1D1E), Color(0xFF0E1111)];
  static const List<Color> successGradient = [Color(0xFF00D05A), Color(0xFF00B34D)];

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF666666);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: Colors.black, // Neon green looks better with black text
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          bodyLarge: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // High radius as per image
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}
