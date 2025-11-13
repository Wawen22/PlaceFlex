import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/colors_2026.dart';
import '../core/theme/spacing_2026.dart';
import '../core/theme/typography_2026.dart';

/// PlaceFlex 2026 - Modern App Theme
class AppTheme {
  /// Light theme configuration
  static ThemeData get light {
    final textTheme = AppTypography2026.createTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ============= COLOR SCHEME =============
      colorScheme: ColorScheme.light(
        primary: AppColors2026.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors2026.primaryContainer,
        onPrimaryContainer: AppColors2026.primaryDark,
        secondary: AppColors2026.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors2026.secondaryContainer,
        onSecondaryContainer: AppColors2026.secondaryDark,
        tertiary: AppColors2026.accent,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors2026.accentContainer,
        onTertiaryContainer: AppColors2026.accentDark,
        error: AppColors2026.error,
        onError: Colors.white,
        errorContainer: AppColors2026.errorContainer,
        onErrorContainer: AppColors2026.error,
        surface: AppColors2026.surfaceLight,
        onSurface: AppColors2026.textPrimary,
        surfaceContainerHighest: AppColors2026.surfaceVariantLight,
        onSurfaceVariant: AppColors2026.textSecondary,
        outline: AppColors2026.border,
        shadow: AppColors2026.shadowMedium,
      ),

      scaffoldBackgroundColor: AppColors2026.backgroundLight,
      textTheme: textTheme,

      // ============= APP BAR =============
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors2026.textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors2026.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ============= INPUT DECORATION =============
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors2026.surfaceLight,
        contentPadding: AppSpacing2026.allSM,
        border: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.error, width: 2),
        ),
      ),

      // ============= BUTTONS =============
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors2026.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing2026.sm,
            horizontal: AppSpacing2026.lg,
          ),
          textStyle: AppTypography2026.button(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors2026.primary,
          side: BorderSide(color: AppColors2026.primary, width: 2),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing2026.sm,
            horizontal: AppSpacing2026.lg,
          ),
          textStyle: AppTypography2026.button(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors2026.primary,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing2026.sm,
            horizontal: AppSpacing2026.md,
          ),
          textStyle: AppTypography2026.button(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedMD),
        ),
      ),

      // ============= FLOATING ACTION BUTTON =============
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors2026.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
      ),

      // ============= CARD =============
      cardTheme: CardThemeData(
        color: AppColors2026.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXXL),
      ),

      // ============= BOTTOM NAV =============
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors2026.surfaceLight,
        selectedItemColor: AppColors2026.primary,
        unselectedItemColor: AppColors2026.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors2026.surfaceLight,
        elevation: 4,
        indicatorColor: AppColors2026.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors2026.primary,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: AppColors2026.textSecondary,
          );
        }),
      ),

      // ============= CHIP =============
      chipTheme: ChipThemeData(
        backgroundColor: AppColors2026.surfaceVariantLight,
        selectedColor: AppColors2026.primaryContainer,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedFull),
      ),

      // ============= DIVIDER =============
      dividerTheme: DividerThemeData(
        color: AppColors2026.border,
        thickness: 1,
        space: AppSpacing2026.md,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get dark {
    final textTheme = AppTypography2026.createTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ============= COLOR SCHEME =============
      colorScheme: ColorScheme.dark(
        primary: AppColors2026.primaryLight,
        onPrimary: AppColors2026.backgroundDark,
        primaryContainer: AppColors2026.primaryDark,
        onPrimaryContainer: AppColors2026.primaryLight,
        secondary: AppColors2026.secondaryLight,
        onSecondary: AppColors2026.backgroundDark,
        secondaryContainer: AppColors2026.secondaryDark,
        onSecondaryContainer: AppColors2026.secondaryLight,
        tertiary: AppColors2026.accentLight,
        onTertiary: AppColors2026.backgroundDark,
        tertiaryContainer: AppColors2026.accentDark,
        onTertiaryContainer: AppColors2026.accentLight,
        error: AppColors2026.errorLight,
        onError: AppColors2026.backgroundDark,
        errorContainer: AppColors2026.error,
        onErrorContainer: AppColors2026.errorLight,
        surface: AppColors2026.surfaceDark,
        onSurface: AppColors2026.textOnDark,
        surfaceContainerHighest: AppColors2026.surfaceVariantDark,
        onSurfaceVariant: AppColors2026.textOnDarkSecondary,
        outline: AppColors2026.borderDark,
        shadow: AppColors2026.shadowStrong,
      ),

      scaffoldBackgroundColor: AppColors2026.backgroundDark,
      textTheme: textTheme,

      // ============= APP BAR =============
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors2026.textOnDark,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors2026.textOnDark,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ============= INPUT DECORATION =============
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors2026.surfaceVariantDark,
        contentPadding: AppSpacing2026.allSM,
        border: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.borderDark, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.borderDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.errorLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius2026.roundedXL,
          borderSide: BorderSide(color: AppColors2026.errorLight, width: 2),
        ),
      ),

      // ============= BUTTONS =============
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors2026.primaryLight,
          foregroundColor: AppColors2026.backgroundDark,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing2026.sm,
            horizontal: AppSpacing2026.lg,
          ),
          textStyle: AppTypography2026.button(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors2026.primaryLight,
          side: BorderSide(color: AppColors2026.primaryLight, width: 2),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing2026.sm,
            horizontal: AppSpacing2026.lg,
          ),
          textStyle: AppTypography2026.button(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors2026.primaryLight,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing2026.sm,
            horizontal: AppSpacing2026.md,
          ),
          textStyle: AppTypography2026.button(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedMD),
        ),
      ),

      // ============= FLOATING ACTION BUTTON =============
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors2026.primaryLight,
        foregroundColor: AppColors2026.backgroundDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXL),
      ),

      // ============= CARD =============
      cardTheme: CardThemeData(
        color: AppColors2026.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedXXL),
      ),

      // ============= BOTTOM NAV =============
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors2026.surfaceDark,
        selectedItemColor: AppColors2026.primaryLight,
        unselectedItemColor: AppColors2026.textOnDarkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors2026.surfaceDark,
        elevation: 4,
        indicatorColor: AppColors2026.primaryDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors2026.primaryLight,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: AppColors2026.textOnDarkSecondary,
          );
        }),
      ),

      // ============= CHIP =============
      chipTheme: ChipThemeData(
        backgroundColor: AppColors2026.surfaceVariantDark,
        selectedColor: AppColors2026.primaryDark,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius2026.roundedFull),
      ),

      // ============= DIVIDER =============
      dividerTheme: DividerThemeData(
        color: AppColors2026.borderDark,
        thickness: 1,
        space: AppSpacing2026.md,
      ),
    );
  }
}
