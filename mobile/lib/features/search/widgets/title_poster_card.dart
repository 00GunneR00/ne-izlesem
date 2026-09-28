import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/title_model.dart';

/// Poster grid cell for a search/filmography result — tap goes straight to
/// the shared DetailView. Same visual language as the library grid's poster
/// card, minus the watched/remove actions (not relevant outside the library).
class TitlePosterCard extends StatelessWidget {
  const TitlePosterCard({required this.title, super.key});

  final TitleModel title;

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
