import 'package:flutter/material.dart';
import '../theme/colors_2026.dart';
import '../theme/spacing_2026.dart';

/// Loading states premium con shimmer e skeletons
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  final Widget child;
  final bool isLoading;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loader per liste e cards
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors2026.surfaceVariantDark
              : AppColors2026.surfaceVariantLight,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius2026.sm),
        ),
      ),
    );
  }
}

/// Empty state illustrato
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing2026.allXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                padding: AppSpacing2026.allXL,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors2026.primary.withOpacity(0.1),
                ),
                child: Icon(
                  icon,
                  size: AppIconSize2026.huge,
                  color: AppColors2026.primary,
                ),
              ),
            const SizedBox(height: AppSpacing2026.lg),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors2026.textOnDark
                    : AppColors2026.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing2026.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors2026.textOnDarkSecondary
                    : AppColors2026.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing2026.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success/Error feedback visuale
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.message,
    this.type = FeedbackType.success,
    this.onDismiss,
  });

  final String message;
  final FeedbackType type;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getColors();

    return Container(
      margin: AppSpacing2026.allSM,
      padding: AppSpacing2026.allSM,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: AppRadius2026.roundedXL,
        border: Border.all(color: colors.$2, width: 1.5),
        boxShadow: AppElevation2026.level2,
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: colors.$2, size: AppIconSize2026.md),
          const SizedBox(width: AppSpacing2026.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.$3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, color: colors.$2),
              iconSize: AppIconSize2026.sm,
            ),
        ],
      ),
    );
  }

  (Color, Color, Color) _getColors() {
    switch (type) {
      case FeedbackType.success:
        return (
          AppColors2026.successContainer,
          AppColors2026.success,
          AppColors2026.success,
        );
      case FeedbackType.error:
        return (
          AppColors2026.errorContainer,
          AppColors2026.error,
          AppColors2026.error,
        );
      case FeedbackType.warning:
        return (
          AppColors2026.warningContainer,
          AppColors2026.warning,
          AppColors2026.warning,
        );
      case FeedbackType.info:
        return (
          AppColors2026.infoContainer,
          AppColors2026.info,
          AppColors2026.info,
        );
    }
  }

  IconData _getIcon() {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle_outline_rounded;
      case FeedbackType.error:
        return Icons.error_outline_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }
}

enum FeedbackType { success, error, warning, info }
