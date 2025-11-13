import 'package:flutter/material.dart';

/// PlaceFlex 2026 - Modern Color System
/// Ispirato da design trends 2026: vibrant, high contrast, accessible
class AppColors2026 {
  // ============= PRIMARY PALETTE =============
  /// Electric Purple - Main brand color
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9F7AEA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryContainer = Color(0xFFEDE9FE);

  /// Cyan Accent - Energy and discovery
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color secondaryContainer = Color(0xFFCFFAFE);

  /// Coral Accent - Actions and highlights
  static const Color accent = Color(0xFFFF5A7C);
  static const Color accentLight = Color(0xFFFF7A96);
  static const Color accentDark = Color(0xFFE63956);
  static const Color accentContainer = Color(0xFFFFE4E9);

  // ============= NEUTRAL PALETTE =============
  /// Light Theme Backgrounds
  static const Color backgroundLight = Color(0xFFFAFAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF3F4F6);

  /// Dark Theme Backgrounds
  static const Color backgroundDark = Color(0xFF0F0F1E);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceVariantDark = Color(0xFF24243E);

  /// Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color textOnDarkSecondary = Color(0xFFCBD5E1);

  // ============= SEMANTIC COLORS =============
  /// Success
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFD1FAE5);

  /// Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFFFEF3C7);

  /// Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);

  /// Info
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ============= OVERLAY & BORDERS =============
  static const Color overlay = Color(0x1A000000);
  static const Color overlayLight = Color(0x0D000000);
  static const Color overlayStrong = Color(0x4D000000);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF334155);

  // ============= SPECIAL EFFECTS =============
  /// Glass morphism
  static const Color glass = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Shadows
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowStrong = Color(0x29000000);
}

/// Gradient presets for modern UI
class AppGradients2026 {
  /// Hero Background - Purple to Dark Blue
  static const LinearGradient heroPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4C1D95)],
  );

  /// Hero Alt - Cyan to Purple
  static const LinearGradient heroSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E7490), Color(0xFF7C3AED), Color(0xFF9333EA)],
  );

  /// Card Glow - Subtle overlay
  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
  );

  /// Button Primary
  static LinearGradient buttonPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors2026.primary, AppColors2026.primaryDark],
  );

  /// Button Secondary
  static LinearGradient buttonSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors2026.secondary, AppColors2026.secondaryDark],
  );

  /// Background Light
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAFAFC), Color(0xFFF5F3FF), Color(0xFFECFDFF)],
  );

  /// Background Dark
  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF16132E)],
  );

  /// Shimmer effect
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
  );

  /// Success Glow
  static LinearGradient successGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors2026.success, AppColors2026.successLight],
  );

  /// Warning Glow
  static LinearGradient warningGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors2026.warning, AppColors2026.warningLight],
  );

  /// Accent Glow
  static LinearGradient accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors2026.accent, AppColors2026.accentLight],
  );
}
