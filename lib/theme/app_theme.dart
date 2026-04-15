import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors — mirrors the React Tailwind palette
  static const Color primary = Color(0xFF6366F1); // indigo-500
  static const Color primaryLight = Color(0xFFEEF2FF); // indigo-50
  static const Color primaryShadow = Color(0xFFA5B4FC); // indigo-300

  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;

  static const Color overdueRed = Color(0xFFEF4444); // red-500
  static const Color overdueRedBg = Color(0xFFFEF2F2); // red-50
  static const Color overdueRedBorder = Color(0xFFFEE2E2); // red-100
  static const Color overdueRedBadge = Color(0xFFFECACA); // red-200

  static const Color dueTodayOrange = Color(0xFFF97316); // orange-500
  static const Color dueTodayOrangeBg = Color(0xFFFFF7ED); // orange-50
  static const Color dueTodayOrangeBorder = Color(0xFFFFEDD5); // orange-100
  static const Color dueTodayOrangeBadge = Color(0xFFFED7AA); // orange-200

  static const Color upcomingBlue = Color(0xFF60A5FA); // blue-400
  static const Color upcomingBlueBg = Color(0xFFEFF6FF); // blue-50

  static const Color emeraldSuccess = Color(0xFF10B981); // emerald-500
  static const Color emeraldSuccessBg = Color(0xFFECFDF5); // emerald-50

  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textTertiary = Color(0xFF9CA3AF); // gray-400
  static const Color borderLight = Color(0xFFF3F4F6); // gray-100
  static const Color borderMedium = Color(0xFFE5E7EB); // gray-200

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        background: background,
        surface: surface,
        primary: primary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
          elevation: 4,
          shadowColor: primaryShadow,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: textTertiary,
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.8,
          color: textSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111827),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1F2937)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
