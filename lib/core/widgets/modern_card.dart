import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/colors_2026.dart';
import '../theme/spacing_2026.dart';

/// Modern card con glassmorphism evoluto, gradient e varianti
class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.variant = ModernCardVariant.elevated,
    this.gradient,
    this.onTap,
    this.borderColor,
    this.blurIntensity = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final ModernCardVariant variant;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double blurIntensity;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppSpacing2026.allLG;
    final effectiveMargin = margin ?? EdgeInsets.zero;

    Widget content = Padding(padding: effectivePadding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: AppRadius2026.roundedXXL,
        child: content,
      );
    }

    return Container(
      margin: effectiveMargin,
      decoration: _getDecoration(context),
      child: ClipRRect(
        borderRadius: AppRadius2026.roundedXXL,
        child:
            variant == ModernCardVariant.glass ||
                variant == ModernCardVariant.glassColored
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurIntensity,
                  sigmaY: blurIntensity,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient ?? AppGradients2026.cardGlow,
                    border: Border.all(
                      color: borderColor ?? AppColors2026.glassBorder,
                    ),
                    borderRadius: AppRadius2026.roundedXXL,
                  ),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case ModernCardVariant.elevated:
        return BoxDecoration(
          color: isDark
              ? AppColors2026.surfaceDark
              : AppColors2026.surfaceLight,
          borderRadius: AppRadius2026.roundedXXL,
          boxShadow: AppElevation2026.level2,
        );

      case ModernCardVariant.outlined:
        return BoxDecoration(
          color: isDark
              ? AppColors2026.surfaceDark
              : AppColors2026.surfaceLight,
          borderRadius: AppRadius2026.roundedXXL,
          border: Border.all(
            color: borderColor ?? AppColors2026.border,
            width: 1.5,
          ),
        );

      case ModernCardVariant.filled:
        return BoxDecoration(
          color: isDark
              ? AppColors2026.surfaceVariantDark
              : AppColors2026.surfaceVariantLight,
          borderRadius: AppRadius2026.roundedXXL,
        );

      case ModernCardVariant.gradient:
        return BoxDecoration(
          gradient: gradient ?? AppGradients2026.buttonPrimary,
          borderRadius: AppRadius2026.roundedXXL,
          boxShadow: AppElevation2026.level3,
        );

      case ModernCardVariant.glass:
      case ModernCardVariant.glassColored:
        return BoxDecoration(borderRadius: AppRadius2026.roundedXXL);
    }
  }
}

enum ModernCardVariant {
  elevated,
  outlined,
  filled,
  gradient,
  glass,
  glassColored,
}
