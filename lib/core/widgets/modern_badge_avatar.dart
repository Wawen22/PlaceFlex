import 'package:flutter/material.dart';
import '../theme/colors_2026.dart';
import '../theme/spacing_2026.dart';

/// Modern badge per notifiche, stati e labels
class ModernBadge extends StatelessWidget {
  const ModernBadge({
    super.key,
    required this.label,
    this.variant = ModernBadgeVariant.primary,
    this.size = ModernBadgeSize.medium,
    this.icon,
  });

  final String label;
  final ModernBadgeVariant variant;
  final ModernBadgeSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = _getColors(isDark);
    final padding = size == ModernBadgeSize.small
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing2026.xxs,
            vertical: AppSpacing2026.xxxs,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing2026.xs,
            vertical: AppSpacing2026.xxs,
          );

    final textStyle = size == ModernBadgeSize.small
        ? theme.textTheme.labelSmall
        : theme.textTheme.labelMedium;

    final iconSize = size == ModernBadgeSize.small
        ? AppIconSize2026.xs
        : AppIconSize2026.sm;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: AppRadius2026.roundedFull,
        border: Border.all(color: colors.$2, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: colors.$3),
            const SizedBox(width: AppSpacing2026.xxxs),
          ],
          Text(
            label,
            style: textStyle?.copyWith(
              color: colors.$3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _getColors(bool isDark) {
    switch (variant) {
      case ModernBadgeVariant.primary:
        return (
          AppColors2026.primaryContainer,
          AppColors2026.primary.withOpacity(0.3),
          AppColors2026.primary,
        );
      case ModernBadgeVariant.secondary:
        return (
          AppColors2026.secondaryContainer,
          AppColors2026.secondary.withOpacity(0.3),
          AppColors2026.secondary,
        );
      case ModernBadgeVariant.accent:
        return (
          AppColors2026.accentContainer,
          AppColors2026.accent.withOpacity(0.3),
          AppColors2026.accent,
        );
      case ModernBadgeVariant.success:
        return (
          AppColors2026.successContainer,
          AppColors2026.success.withOpacity(0.3),
          AppColors2026.success,
        );
      case ModernBadgeVariant.warning:
        return (
          AppColors2026.warningContainer,
          AppColors2026.warning.withOpacity(0.3),
          AppColors2026.warning,
        );
      case ModernBadgeVariant.error:
        return (
          AppColors2026.errorContainer,
          AppColors2026.error.withOpacity(0.3),
          AppColors2026.error,
        );
      case ModernBadgeVariant.neutral:
        return isDark
            ? (
                AppColors2026.surfaceVariantDark,
                AppColors2026.borderDark,
                AppColors2026.textOnDark,
              )
            : (
                AppColors2026.surfaceVariantLight,
                AppColors2026.border,
                AppColors2026.textPrimary,
              );
    }
  }
}

enum ModernBadgeVariant {
  primary,
  secondary,
  accent,
  success,
  warning,
  error,
  neutral,
}

enum ModernBadgeSize { small, medium }

/// Modern avatar con initials, immagini e placeholder
class ModernAvatar extends StatelessWidget {
  const ModernAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = ModernAvatarSize.medium,
    this.color,
    this.onTap,
    this.hasBorder = false,
  });

  final String? imageUrl;
  final String? initials;
  final ModernAvatarSize size;
  final Color? color;
  final VoidCallback? onTap;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final radius = switch (size) {
      ModernAvatarSize.small => 16.0,
      ModernAvatarSize.medium => 24.0,
      ModernAvatarSize.large => 32.0,
      ModernAvatarSize.xlarge => 48.0,
    };

    final fontSize = switch (size) {
      ModernAvatarSize.small => 12.0,
      ModernAvatarSize.medium => 16.0,
      ModernAvatarSize.large => 20.0,
      ModernAvatarSize.xlarge => 28.0,
    };

    final backgroundColor = color ?? AppColors2026.primary;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor.withOpacity(0.15),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              initials ?? '?',
              style: TextStyle(
                color: backgroundColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );

    if (hasBorder) {
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: backgroundColor, width: 2),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

enum ModernAvatarSize { small, medium, large, xlarge }
