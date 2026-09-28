import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/library_entry_model.dart';

/// Library grid card (poster, rating, name, year) with mark-watched /
/// remove actions. Used by the Kütüphanem page and Sosyal's Listem tab.
class LibraryPosterCard extends StatelessWidget {
  final LibraryEntryModel entry;
  final bool showMarkWatched;
  final VoidCallback onMarkWatched;
  final VoidCallback onRemove;

  const LibraryPosterCard({
    super.key,
    required this.entry,
    required this.showMarkWatched,
    required this.onMarkWatched,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry.title;
    final year = title.releaseDate != null && title.releaseDate!.length >= 4
        ? title.releaseDate!.substring(0, 4)
        : null;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.detail, arguments: title),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'title-${title.tmdbId}-${title.mediaType.name}',
                  child: title.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: title.posterUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.surfaceContainer),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xs,
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            title.voteAverage.toStringAsFixed(1),
                            style: AppTextStyles.labelSm,
                          ),
                        ],
                      ),
                      Text(
                        title.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd,
                      ),
                      if (year != null)
                        Text(
                          year,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (entry.progressLabel != null || entry.rating != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.primaryContainer),
                      ),
                      child: Text(
                        entry.status == LibraryStatus.watching &&
                                entry.progressLabel != null
                            ? entry.progressLabel!
                            : entry.rating != null
                            ? '★ ${entry.rating}'
                            : entry.progressLabel!,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    children: [
                      if (showMarkWatched)
                        _iconButton(Icons.check_circle_outline, onMarkWatched),
                      _iconButton(Icons.delete_outline, onRemove),
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

  Widget _iconButton(IconData icon, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    ),
  );
}
