import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/suggestion_model.dart';
import '../controllers/group_detail_controller.dart';
import 'group_swipe_view.dart';

/// Shown when a group is tapped from "Gruplarım": the "Birlikte Seç" entry
/// point, the group's matches (titles every member swiped right on), and the
/// titles accepted from suggestions ("Bunu izleyelim mi?").
class GroupDetailView extends StatelessWidget {
  const GroupDetailView({required this.group, super.key});

  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      GroupDetailController(group.id),
      tag: 'group-${group.id}',
    );
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value &&
              controller.watchlist.isEmpty &&
              controller.matches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.reload,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _swipeTogetherCard(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Eşleşmeler',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.matches.isEmpty)
                  _emptyText(
                    'Henüz eşleşme yok. Birlikte seçmeye başlayın; herkesin '
                    'sağa kaydırdığı ilk film burada görünecek.',
                  )
                else
                  _matchesStrip(controller.matches),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Onaylanan Öneriler',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.watchlist.isEmpty)
                  _emptyText(
                    'Bu grupta henüz onaylanmış bir izleme önerisi yok.',
                  )
                else
                  for (final item in controller.watchlist) ...[
                    _watchlistCard(item),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _swipeTogetherCard() => InkWell(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    onTap: () => Get.to(() => GroupSwipeView(group: group)),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryContainer),
        boxShadow: [BoxShadow(color: AppColors.glowPrimary, blurRadius: 16)],
      ),
      child: Row(
        children: [
          const Icon(Icons.style, color: AppColors.primary, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Birlikte Seç',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ne izlesek? Herkes kaydırsın, ortak beğeniniz eşleşsin.',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
    ),
  );

  Widget _emptyText(String text) => Text(
    text,
    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
  );

  Widget _matchesStrip(List<GroupMatch> matches) => SizedBox(
    height: 190,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final match = matches[index];
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Get.toNamed(AppRoutes.detail, arguments: match.title),
          child: SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: match.title.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: match.title.posterUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: AppColors.surfaceContainerLow),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  match.title.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _watchlistCard(GroupWatchlistItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.detail, arguments: item.title),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 70,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: item.title.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.title.posterUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: AppColors.surfaceContainerLow),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.name,
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.acceptedByDisplayName} onayladı · ${_formatDate(item.acceptedAt)}',
                            style: AppTextStyles.labelSm.copyWith(
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
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }
}
