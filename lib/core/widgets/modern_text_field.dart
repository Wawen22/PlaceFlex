import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors_2026.dart';
import '../theme/spacing_2026.dart';

/// Ultra-Modern TextField 2026 - Design System Premium
/// Features: Glassmorphism, Floating Label, Micro-interactions, Haptic Feedback
class ModernTextField extends StatefulWidget {
  const ModernTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.focusNode,
    this.useGlassmorphism = false,
    this.enableHaptics = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool useGlassmorphism;
  final bool enableHaptics;

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _focusController;
  late AnimationController _glowController;
  late AnimationController _shakeController;

  late Animation<double> _borderAnimation;
  late Animation<double> _labelAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;

  bool _isFocused = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    // Focus animations
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Shake animation for errors
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _borderAnimation = Tween<double>(begin: 1.5, end: 2.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutCubic),
    );

    _labelAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    widget.controller?.addListener(_handleTextChange);
    _hasContent = widget.controller?.text.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake animation on error
    if (widget.errorText != null && oldWidget.errorText == null) {
      _shakeController.forward(from: 0);
      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _focusController.forward();
        if (widget.enableHaptics) {
          HapticFeedback.selectionClick();
        }
      } else {
        _focusController.reverse();
      }
    });
  }

  void _handleTextChange() {
    final hasContent = widget.controller?.text.isNotEmpty ?? false;
    if (hasContent != _hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  Widget _buildGlowEffect(Color color, double opacity) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius2026.roundedXL,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(opacity * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    final accentColor = hasError
        ? AppColors2026.error
        : _isFocused
        ? AppColors2026.primary
        : AppColors2026.secondary;

    final borderColor = hasError
        ? AppColors2026.error
        : _isFocused
        ? AppColors2026.primary
        : isDark
        ? AppColors2026.borderDark.withOpacity(0.4)
        : AppColors2026.border.withOpacity(0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_focusController, _shakeController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  children: [
                    // Glow effect when focused
                    if (_isFocused && !hasError)
                      _buildGlowEffect(AppColors2026.primary, 0.15),

                    // Error glow
                    if (hasError) _buildGlowEffect(AppColors2026.error, 0.2),

                    // Main container
                    _buildMainContainer(
                      theme,
                      isDark,
                      hasError,
                      borderColor,
                      accentColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.errorText != null || widget.helperText != null)
          _buildHelperText(theme, isDark, hasError),
      ],
    );
  }

  Widget _buildMainContainer(
    ThemeData theme,
    bool isDark,
    bool hasError,
    Color borderColor,
    Color accentColor,
  ) {
    final fillColor = widget.useGlassmorphism
        ? (isDark
              ? AppColors2026.surfaceVariantDark.withOpacity(0.7)
              : AppColors2026.surfaceLight.withOpacity(0.7))
        : (isDark
              ? AppColors2026.surfaceVariantDark
              : AppColors2026.surfaceLight);

    final container = Container(
      decoration: BoxDecoration(
        gradient: _isFocused && !hasError
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [fillColor, fillColor.withOpacity(0.95)],
              )
            : null,
        color: _isFocused ? null : fillColor,
        borderRadius: AppRadius2026.roundedXL,
        border: Border.all(color: borderColor, width: _borderAnimation.value),
        boxShadow: [
          if (_isFocused && !hasError)
            BoxShadow(
              color: AppColors2026.primary.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          if (!_isFocused && !hasError)
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          if (hasError)
            BoxShadow(
              color: AppColors2026.error.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing2026.sm,
                right: AppSpacing2026.sm,
                top: AppSpacing2026.xs,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: hasError
                      ? AppColors2026.error
                      : _isFocused
                      ? accentColor
                      : isDark
                      ? AppColors2026.textOnDarkSecondary
                      : AppColors2026.textSecondary,
                  fontWeight: _isFocused ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: _isFocused ? 0.8 : 0.5,
                ),
                child: Transform.scale(
                  scale: _labelAnimation.value,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label!),
                      if (_isFocused && !hasError) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppColors2026.textOnDark
                  : AppColors2026.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors2026.textOnDarkSecondary.withOpacity(0.4)
                    : AppColors2026.textTertiary.withOpacity(0.6),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? accentColor
                            : isDark
                            ? AppColors2026.textOnDarkSecondary
                            : AppColors2026.textSecondary,
                        size: _isFocused ? 22 : 20,
                      ),
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      child: widget.suffixIcon,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon == null
                    ? AppSpacing2026.md
                    : AppSpacing2026.xs,
                vertical: AppSpacing2026.md,
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );

    // Wrap with glassmorphism if enabled
    if (widget.useGlassmorphism && _isFocused) {
      return ClipRRect(
        borderRadius: AppRadius2026.roundedXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: container,
        ),
      );
    }

    return container;
  }

  Widget _buildHelperText(ThemeData theme, bool isDark, bool hasError) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing2026.md,
        top: AppSpacing2026.xs,
        right: AppSpacing2026.md,
      ),
      child: Row(
        children: [
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors2026.error,
              ),
            ),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: theme.textTheme.bodySmall!.copyWith(
                color: hasError
                    ? AppColors2026.error
                    : isDark
                    ? AppColors2026.textOnDarkSecondary
                    : AppColors2026.textSecondary,
                fontWeight: hasError ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(
                widget.errorText ?? widget.helperText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
