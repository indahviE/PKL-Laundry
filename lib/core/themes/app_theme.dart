 import 'package:flutter/material.dart';

/// App Theme Configuration
class AppTheme {
  // ============================================
  // COLORS
  // ============================================

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF00D4FF);
  static const Color accentColor = Color(0xFFFF6B6B);
  
  static const Color successColor = Color(0xFF51CF66);
  static const Color warningColor = Color(0xFFFFA500);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color infoColor = Color(0xFF6C63FF);

  // Neutral Colors
  static const Color darkColor = Color(0xFF2D3436);
  static const Color lightColor = Color(0xFFFAFAFA);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // Gray Shades
  static const Color gray900 = Color(0xFF111827);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray50 = Color(0xFFFAFAFA);

  // ============================================
  // SPACING
  // ============================================

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // ============================================
  // BORDER RADIUS
  // ============================================

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;

  // ============================================
  // LIGHT THEME
  // ============================================

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: Colors.white,
        brightness: Brightness.light,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconThemeData: IconThemeData(color: darkColor),
        titleTextStyle: TextStyle(
          color: darkColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkColor,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkColor,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkColor,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: gray700,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: gray600,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkColor,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: lg,
          vertical: md,
        ),
        filled: true,
        fillColor: gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(
            color: errorColor,
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: gray500,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: gray700,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: errorColor,
          fontSize: 12,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: xl,
            vertical: md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: xl,
            vertical: md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          side: const BorderSide(color: primaryColor),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: md,
            vertical: sm,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusXl),
            topRight: Radius.circular(radiusXl),
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: gray100,
        labelStyle: const TextStyle(
          color: darkColor,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: sm,
          vertical: xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      // Divider Color
      dividerColor: borderColor,

      // Icon Theme
      iconTheme: const IconThemeData(color: darkColor),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: gray900,
      cardColor: gray800,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: gray800,
        brightness: Brightness.dark,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: gray800,
        elevation: 0,
        centerTitle: false,
        iconThemeData: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: gray300,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: gray400,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),

      // Input Decoration Theme (Dark)
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: lg,
          vertical: md,
        ),
        filled: true,
        fillColor: gray800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: gray700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: gray700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: gray500,
          fontSize: 14,
        ),
      ),

      // Card Theme (Dark)
      cardTheme: CardTheme(
        color: gray800,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: gray700),
        ),
      ),

      // Divider Color
      dividerColor: gray700,

      // Icon Theme
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}