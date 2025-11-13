import 'package:flutter/material.dart';
import '../theme/colors_2026.dart';
import '../theme/spacing_2026.dart';
import '../theme/typography_2026.dart';

/// Modern button component con gradient, effetti e varianti
class ModernButton extends StatefulWidget {
  const ModernButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ModernButtonVariant.primary,
    this.size = ModernButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.gradient,
    this.elevation = 0,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ModernButtonVariant variant;
  final ModernButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final Gradient? gradient;
  final double elevation;

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final buttonPadding = switch (widget.size) {
      ModernButtonSize.small => const EdgeInsets.symmetric(
        horizontal: AppSpacing2026.sm,
        vertical: AppSpacing2026.xs,
      ),
      ModernButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: AppSpacing2026.lg,
        vertical: AppSpacing2026.sm,
      ),
      ModernButtonSize.large => const EdgeInsets.symmetric(
        horizontal: AppSpacing2026.xl,
        vertical: AppSpacing2026.md,
      ),
    };

    final textStyle = switch (widget.size) {
      ModernButtonSize.small => AppTypography2026.button(large: false),
      ModernButtonSize.medium => AppTypography2026.button(large: false),
      ModernButtonSize.large => AppTypography2026.button(large: true),
    };

    final iconSize = switch (widget.size) {
      ModernButtonSize.small => AppIconSize2026.sm,
      ModernButtonSize.medium => AppIconSize2026.md,
      ModernButtonSize.large => AppIconSize2026.lg,
    };

    Widget content = widget.isLoading
        ? SizedBox(
            height: iconSize,
            width: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
            ),
          )
        : Row(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: iconSize),
                const SizedBox(width: AppSpacing2026.xxs),
              ],
              DefaultTextStyle(
                style: textStyle.copyWith(color: _getTextColor()),
                child: widget.child,
              ),
            ],
          );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.isExpanded ? double.infinity : null,
            decoration: _getDecoration(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                borderRadius: AppRadius2026.roundedXL,
                child: Padding(padding: buttonPadding, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration() {
    if (widget.gradient != null) {
      return BoxDecoration(
        gradient: widget.gradient,
        borderRadius: AppRadius2026.roundedXL,
        boxShadow: widget.elevation > 0 ? AppElevation2026.level3 : null,
      );
    }

    switch (widget.variant) {
      case ModernButtonVariant.primary:
        return BoxDecoration(
          gradient: AppGradients2026.buttonPrimary,
          borderRadius: AppRadius2026.roundedXL,
          boxShadow: widget.elevation > 0
              ? AppElevation2026.colored(AppColors2026.primary)
              : null,
        );

      case ModernButtonVariant.secondary:
        return BoxDecoration(
          gradient: AppGradients2026.buttonSecondary,
          borderRadius: AppRadius2026.roundedXL,
          boxShadow: widget.elevation > 0
              ? AppElevation2026.colored(AppColors2026.secondary)
              : null,
        );

      case ModernButtonVariant.accent:
        return BoxDecoration(
          gradient: AppGradients2026.accentGlow,
          borderRadius: AppRadius2026.roundedXL,
          boxShadow: widget.elevation > 0
              ? AppElevation2026.colored(AppColors2026.accent)
              : null,
        );

      case ModernButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius2026.roundedXL,
          border: Border.all(color: AppColors2026.primary, width: 2),
        );

      case ModernButtonVariant.ghost:
        return BoxDecoration(
          color: AppColors2026.primary.withOpacity(0.1),
          borderRadius: AppRadius2026.roundedXL,
        );

      case ModernButtonVariant.text:
        return const BoxDecoration();
    }
  }

  Color _getTextColor() {
    switch (widget.variant) {
      case ModernButtonVariant.primary:
      case ModernButtonVariant.secondary:
      case ModernButtonVariant.accent:
        return Colors.white;
      case ModernButtonVariant.outlined:
      case ModernButtonVariant.ghost:
      case ModernButtonVariant.text:
        return AppColors2026.primary;
    }
  }
}

enum ModernButtonVariant { primary, secondary, accent, outlined, ghost, text }

enum ModernButtonSize { small, medium, large }
