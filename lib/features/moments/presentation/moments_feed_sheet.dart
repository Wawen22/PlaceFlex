import 'package:flutter/material.dart';
import '../../../core/theme/colors_2026.dart';
import '../../../core/theme/spacing_2026.dart';
import '../../../core/widgets/modern_card.dart';
import '../models/moment.dart';

class MomentsFeedSheet extends StatelessWidget {
  const MomentsFeedSheet({
    super.key,
    required this.moments,
    required this.onMomentTap,
    this.isLoading = false,
  });

  final List<Moment> moments;
  final ValueChanged<Moment> onMomentTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors2026.surfaceVariantDark
                : AppColors2026.surfaceVariantLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Momenti vicini',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: moments.isEmpty && !isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.explore_off_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun momento qui vicino',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: moments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final moment = moments[index];
                          return _MomentListItem(
                            moment: moment,
                            onTap: () => onMomentTap(moment),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MomentListItem extends StatelessWidget {
  const _MomentListItem({
    required this.moment,
    required this.onTap,
  });

  final Moment moment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // Thumbnail / Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              image: moment.thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(moment.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: moment.thumbnailUrl == null
                ? Icon(
                    _getIconForType(moment.mediaType),
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (moment.description != null)
                    Text(
                      moment.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 12,
                        color: AppColors2026.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${moment.radiusMeters}m', // Idealmente calcolare distanza reale
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors2026.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(MomentMediaType type) {
    return switch (type) {
      MomentMediaType.photo => Icons.photo_camera_rounded,
      MomentMediaType.video => Icons.videocam_rounded,
      MomentMediaType.audio => Icons.mic_rounded,
      MomentMediaType.text => Icons.text_fields_rounded,
    };
  }
}
