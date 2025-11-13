import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PlaceFlex 2026 - Modern Typography System
/// Basato su scale fluide e type hierarchy chiara
class AppTypography2026 {
  /// Base font family - Inter per UI, Space Grotesk per headlines
  static TextTheme createTextTheme(Brightness brightness) {
    // Headlines con Space Grotesk (moderno, geometrico)
    final headlineFont = GoogleFonts.spaceGrotesk();

    // Body text con Inter (leggibile, neutro)
    final bodyFont = GoogleFonts.inter();

    return TextTheme(
      // ============= DISPLAY =============
      displayLarge: headlineFont.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: headlineFont.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: headlineFont.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
      ),

      // ============= HEADLINE =============
      headlineLarge: headlineFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: headlineFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: headlineFont.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      ),

      // ============= TITLE =============
      titleLarge: bodyFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // ============= BODY =============
      bodyLarge: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // ============= LABEL =============
      labelLarge: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: bodyFont.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: bodyFont.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  /// Typography tokens per casi d'uso specifici
  static TextStyle button({bool large = false}) {
    return GoogleFonts.inter(
      fontSize: large ? 16 : 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.0,
    );
  }

  static TextStyle caption() {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    );
  }

  static TextStyle overline() {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      height: 1.6,
    ).copyWith(textBaseline: TextBaseline.alphabetic);
  }

  static TextStyle code() {
    return GoogleFonts.jetBrainsMono(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
    );
  }

  /// Numerical display (stats, metrics)
  static TextStyle numeric({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
      height: 1.0,
      fontFeatures: [const FontFeature.tabularFigures()],
    );
  }
}
