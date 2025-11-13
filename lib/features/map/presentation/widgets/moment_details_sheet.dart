import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/colors_2026.dart';
import '../../../../core/theme/spacing_2026.dart';
import '../../../moments/models/moment.dart';

/// Bottom sheet ultra-moderno per dettagli momento
/// Design 2026: Glassmorphism, animazioni, icone dinamiche
class MomentDetailsSheet extends StatelessWidget {
  const MomentDetailsSheet({required this.moment, super.key});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing2026.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors2026.surfaceDark.withOpacity(0.85),
                      AppColors2026.surfaceVariantDark.withOpacity(0.85),
                    ]
                  : [
                      Colors.white.withOpacity(0.85),
                      AppColors2026.surfaceVariantLight.withOpacity(0.85),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing2026.xl),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle indicator con gradiente
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing2026.md),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getGradientForType(moment.mediaType),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing2026.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con icona dinamica
                      Row(
                        children: [
                          Hero(
                            tag: 'moment-${moment.id}',
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _getGradientForType(moment.mediaType),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getGradientForType(
                                      moment.mediaType,
                                    ).first.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIconForType(moment.mediaType),
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing2026.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  moment.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _getGradientForType(
                                            moment.mediaType,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getTypeLabel(moment.mediaType),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(moment.createdAt),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors2026
                                                      .textOnDarkSecondary
                                                : AppColors2026.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (moment.description != null &&
                          moment.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing2026.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing2026.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            moment.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing2026.md),

                      // Info chips con glassmorphism
                      Wrap(
                        spacing: AppSpacing2026.sm,
                        runSpacing: AppSpacing2026.sm,
                        children: [
                          _GlassInfoChip(
                            icon: Icons.visibility_rounded,
                            label:
                                moment.visibility.name[0].toUpperCase() +
                                moment.visibility.name.substring(1),
                            isDark: isDark,
                          ),
                          _GlassInfoChip(
                            icon: Icons.radar_rounded,
                            label: '${moment.radiusMeters}m raggio',
                            isDark: isDark,
                          ),
                          if (moment.tags.isNotEmpty)
                            ...moment.tags.map(
                              (tag) => _GlassInfoChip(
                                icon: Icons.tag_rounded,
                                label: tag,
                                isDark: isDark,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing2026.xl),

                      // Action button con gradiente
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getGradientForType(moment.mediaType),
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _getGradientForType(
                                  moment.mediaType,
                                ).first.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing2026.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Chiudi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientForType(MomentMediaType type) {
    switch (type) {
      case MomentMediaType.photo:
        return [const Color(0xFF00FFA3), const Color(0xFF0094FF)];
      case MomentMediaType.video:
        return [const Color(0xFFFF0080), const Color(0xFFFF8C00)];
      case MomentMediaType.audio:
        return [const Color(0xFF9D00FF), const Color(0xFFFF00F5)];
      case MomentMediaType.text:
        return [const Color(0xFFFFD700), const Color(0xFFFF6B00)];
    }
  }

  IconData _getIconForType(MomentMediaType type) {
    switch (type) {
      case MomentMediaType.photo:
        return Icons.photo_camera_rounded;
      case MomentMediaType.video:
        return Icons.play_circle_rounded;
      case MomentMediaType.audio:
        return Icons.mic_rounded;
      case MomentMediaType.text:
        return Icons.text_fields_rounded;
    }
  }

  String _getTypeLabel(MomentMediaType type) {
    switch (type) {
      case MomentMediaType.photo:
        return 'FOTO';
      case MomentMediaType.video:
        return 'VIDEO';
      case MomentMediaType.audio:
        return 'AUDIO';
      case MomentMediaType.text:
        return 'TESTO';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Adesso';
        return '${diff.inMinutes}m fa';
      }
      return '${diff.inHours}h fa';
    } else if (diff.inDays == 1) {
      return 'Ieri';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}g fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _GlassInfoChip extends StatelessWidget {
  const _GlassInfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors2026.textOnDark
                    : AppColors2026.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors2026.textOnDark
                      : AppColors2026.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
