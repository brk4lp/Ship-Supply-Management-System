import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

/// "The Linear Aesthetic" - Clean SaaS Design System
/// Minimalist, slate-colored, professional, data-dense but readable
class AppTheme {
  // Brand Colors (Slate/Zinc Palette)
  static const Color background = Color(0xFFF8F9FA);      // Off-White
  static const Color surface = Color(0xFFFFFFFF);          // Pure White
  static const Color border = Color(0xFFE2E8F0);           // Thin subtle grey
  static const Color primaryText = Color(0xFF1E293B);      // Slate 800
  static const Color secondaryText = Color(0xFF64748B);    // Slate 500
  static const Color brandColor = Color(0xFF0F172A);       // Deep Navy
  static const Color accent = Color(0xFF6366F1);           // Muted Indigo

  // Status Colors (Muted/Pastel tones)
  static const Color success = Color(0xFF10B981);          // Emerald 500
  static const Color error = Color(0xFFDC2626);            // Red 600
  static const Color warning = Color(0xFFF59E0B);          // Amber 500
  static const Color info = Color(0xFF3B82F6);             // Blue 500

  // Border Radius
  static const double radiusSmall = 8.0;   // Inputs, buttons
  static const double radiusMedium = 12.0; // Cards, containers

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: brandColor,
        primaryContainer: Color(0xFF1E293B),
        secondary: accent,
        secondaryContainer: Color(0xFFE0E7FF),
        tertiary: Color(0xFF0EA5E9),
        tertiaryContainer: Color(0xFFE0F2FE),
        error: Color(0xFFDC2626),
        errorContainer: Color(0xFFFEE2E2),
      ),
      surfaceMode: FlexSurfaceMode.level,
      blendLevel: 7,
      scaffoldBackground: background,
      surface: surface,
      appBarStyle: FlexAppBarStyle.surface,
      appBarElevation: 0,
      bottomAppBarElevation: 0,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      visualDensity: VisualDensity.compact, // Dense for desktop
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      // Custom component themes
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: border, width: 1),
        ),
        color: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          minimumSize: const Size(88, 40),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowHeight: 44,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        horizontalMargin: 16,
        columnSpacing: 24,
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondaryText,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: primaryText,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: accent,
        primaryContainer: Color(0xFF312E81),
        secondary: Color(0xFF818CF8),
        secondaryContainer: Color(0xFF3730A3),
        tertiary: Color(0xFF38BDF8),
        tertiaryContainer: Color(0xFF0C4A6E),
        error: Color(0xFFF87171),
        errorContainer: Color(0xFF7F1D1D),
      ),
      surfaceMode: FlexSurfaceMode.level,
      blendLevel: 13,
      visualDensity: VisualDensity.compact,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }

  /// Standard "Linear" container decoration
  static BoxDecoration linearContainer({Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(color: border, width: 1),
    );
  }

  /// Text Styles using Inter font
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryText,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryText,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: primaryText,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryText,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryText,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryText,
        letterSpacing: 0.5,
      );
}
