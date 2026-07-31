import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glassmorphic_theme_extension.dart';

/// Centralized M3 Design System theme configuration for ResuMatch AI.
class AppTheme {
  // Brand Color Tokens
  static const Color darkBackground = Color(0xFF090D16); // Deep Space Dark
  static const Color darkMidnightBg = Color(0xBF121826); // Glassmorphic Midnight (0.75 opacity)
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightMidnightBg = Color(0xCCFFFFFF); // Glassmorphic Light (0.80 opacity)

  static const Color primaryViolet = Color(0xFF6366F1); // Electric Violet
  static const Color secondaryTeal = Color(0xFF14B8A6); // Cyber Teal
  static const Color errorCrimson = Color(0xFFEF4444); // Crimson Red
  static const Color warningGold = Color(0xFFF59E0B); // Amber Gold

  static const Color textLightPrimary = Color(0xFFF8FAFC); // Off-white
  static const Color textLightMuted = Color(0xFF94A3B8); // Cool grey
  static const Color textDarkPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textDarkMuted = Color(0xFF64748B); // Slate grey

  /// Glassmorphic borders
  static final Border darkSubtleBorder = Border.all(
    color: const Color(0x14FFFFFF), // White with 8% alpha
    width: 1.0,
  );

  static final Border lightSubtleBorder = Border.all(
    color: const Color(0x14000000), // Black with 8% alpha
    width: 1.0,
  );

  /// Standard dark M3 Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryViolet,
        secondary: secondaryTeal,
        error: errorCrimson,
        surface: darkMidnightBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02,
          color: textLightPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: textLightPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textLightPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: textLightPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textLightMuted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textLightMuted,
        ),
      ),
      extensions: [
        GlassmorphicThemeExtension(
          midnightBg: darkMidnightBg,
          blurRadius: 12.0,
          borderSubtle: darkSubtleBorder,
        ),
      ],
    );
  }

  /// Standard light M3 Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryViolet,
        secondary: secondaryTeal,
        error: errorCrimson,
        surface: lightMidnightBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02,
          color: textDarkPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: textDarkPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDarkPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: textDarkPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textDarkMuted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textDarkMuted,
        ),
      ),
      extensions: [
        GlassmorphicThemeExtension(
          midnightBg: lightMidnightBg,
          blurRadius: 12.0,
          borderSubtle: lightSubtleBorder,
        ),
      ],
    );
  }
}
