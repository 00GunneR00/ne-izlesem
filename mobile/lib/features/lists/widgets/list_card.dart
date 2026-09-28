import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_list_model.dart';

/// A collection card: 2×2 poster collage, name, count and privacy.
/// [showOwner] adds the owner's name (friends' lists).
class ListCard extends StatelessWidget {
  const ListCard({
    required this.list,
    required this.onTap,
    this.showOwner = false,
    super.key,
  });

  final UserListSummary list;
  final VoidCallback onTap;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1, child: _collage()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        list.isShared
                            ? Icons.people_outline
                            : Icons.lock_outline,
                        size: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          showOwner
                              ? '${list.ownerDisplayName} · ${list.itemCount} yapım'
                              : '${list.itemCount} yapım',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collage() {
    final posters = list.previewPosters;
    if (posters.isEmpty) {
      return Container(
        color: AppColors.surfaceContainerHigh,
        child: const Center(
          child: Icon(
            Icons.playlist_add,
            size: 36,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    if (posters.length < 4) {
      return CachedNetworkImage(imageUrl: posters.first, fit: BoxFit.cover);
    }
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      childAspectRatio: 1,
      children: [
        for (final url in posters.take(4))
          CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
      ],
    );
  }
}
