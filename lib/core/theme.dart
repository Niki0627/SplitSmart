// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors - High Contrast B&W Minimal
  static const primary = Color(0xFF000000); // Black for primary actions
  static const primaryDark = Color(0xFF1A1A1A);
  static const primaryLight = Color(0xFF333333);
  
  static const cyan = Color(0xFF666666); // Re-mapped to gray
  static const cyanDark = Color(0xFF333333);
  static const cyanLight = Color(0xFF999999);

  static const accent = Color(0xFF666666); // Re-mapped to gray
  static const accentDark = Color(0xFF333333);
  static const accentLight = Color(0xFF999999);

  // Light Mode Colors
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF3F4F6);
  static const cardLight = Color(0xFFF9FAFB);
  static const borderLight = Color(0xFFE5E7EB);

  // Dark Mode Colors (Clean Dark Aesthetic)
  static const backgroundDark = Color(0xFF111111); // Deep almost black
  static const surfaceDark = Color(0xFF1E1E1E);
  static const cardDark = Color(0xFF262626); // Dark gray cards
  static const borderDark = Color(0xFF3F3F3F); // Subtle borders

  // Typography Colors
  static const slate900 = Color(0xFF000000); // Pure black
  static const slate800 = Color(0xFF1F2937);
  static const slate700 = Color(0xFF374151);
  static const slate600 = Color(0xFF4B5563);
  static const slate500 = Color(0xFF9CA3AF);
  static const slate400 = Color(0xFFD1D5DB);
  static const slate300 = Color(0xFFE5E7EB);
  static const slate100 = Color(0xFFFFFFFF); // Pure white

  // Semantic Status Colors (Mapped to grays/blacks/whites for B&W theme)
  static const emerald = Color(0xFF1A1A1A); 
  static const rose = Color(0xFF333333); 
  static const amber = Color(0xFF4D4D4D);
  static const blue = Color(0xFF666666);
  static const purple = Color(0xFF808080);
  static const violet = Color(0xFF999999);
}

class AppTheme {
  static ThemeData get dark {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: Colors.white,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.grey,
        surface: AppColors.surfaceDark,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: Colors.white),
        displayMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: Colors.white),
        displaySmall: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white),
        headlineSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.dmSans(color: AppColors.slate300),
        bodyMedium: GoogleFonts.dmSans(color: AppColors.slate400),
        labelLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.slate500),
        labelStyle: GoogleFonts.dmSans(color: AppColors.slate400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.slate500,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.borderDark, thickness: 1),
      useMaterial3: true,
    );
  }

  static ThemeData get light {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: Colors.black,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.grey,
        surface: AppColors.surfaceLight,
        onPrimary: Colors.white,
        onSurface: AppColors.slate900,
      ),
      textTheme:
          GoogleFonts.dmSansTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800, color: AppColors.slate900),
        displayMedium: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800, color: AppColors.slate900),
        displaySmall: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, color: AppColors.slate900),
        headlineMedium: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, color: AppColors.slate900),
        headlineSmall: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, color: AppColors.slate900),
        titleLarge: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, color: AppColors.slate900),
        titleMedium: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600, color: AppColors.slate900),
        bodyLarge: GoogleFonts.dmSans(color: AppColors.slate800),
        bodyMedium: GoogleFonts.dmSans(color: AppColors.slate600),
        labelLarge: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700, color: AppColors.slate900),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.slate500),
        labelStyle: GoogleFonts.dmSans(color: AppColors.slate600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle:
              GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.slate900),
        iconTheme: const IconThemeData(color: AppColors.slate900),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.black,
        unselectedItemColor: AppColors.slate500,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.borderLight, thickness: 1),
      useMaterial3: true,
    );
  }
}
