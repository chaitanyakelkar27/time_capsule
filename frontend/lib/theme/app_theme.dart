import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme for TimeCapsule.
/// Inspired by Linear.app / Vercel dashboard.
class AppTheme {
  AppTheme._();

  // ── Color Palette ──────────────────────────────────────
  static const Color scaffold = Color(0xFF0D0F14);
  static const Color cardBg = Color(0xFF161B25);
  static const Color primary = Color(0xFF4F6EF7);
  static const Color success = Color(0xFF2DD4BF);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color divider = Color(0xFF1E2535);
  static const Color inputFill = Color(0xFF1E2535);
  static const Color inputBorder = Color(0xFF2A3347);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textBody = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF475569);

  // ── Status Colors ──────────────────────────────────────
  static const Color statusLocked = Color(0xFFFBBF24);
  static const Color statusUnlocked = Color(0xFF2DD4BF);
  static const Color statusScheduled = Color(0xFF4F6EF7);

  // ── Border Radii ───────────────────────────────────────
  static const double radiusCard = 12.0;
  static const double radiusInput = 8.0;
  static const double radiusPill = 99.0;

  // ── Typography Helpers ─────────────────────────────────
  static TextStyle display = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle heading = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle subheading = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textBody,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.8,
  );

  // ── ThemeData ──────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffold,
      cardColor: cardBg,
      dividerColor: divider,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: success,
        error: error,
        surface: cardBg,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: display,
        headlineMedium: heading,
        titleMedium: subheading,
        bodyMedium: body,
        labelSmall: label,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,

      // ── AppBar ────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textSecondary, size: 20),
      ),

      // ── Card ──────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),

      // ── Input ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Filled Button ─────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusInput),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textBody,
          side: const BorderSide(color: inputBorder),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusInput),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Divider ───────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),

      // ── SnackBar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: GoogleFonts.inter(color: textBody, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusInput),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textBody,
        ),
      ),
    );
  }
}
