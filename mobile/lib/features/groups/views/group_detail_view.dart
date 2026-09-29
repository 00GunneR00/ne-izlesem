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
/// point, the group's matches (everyone swiped right on, or everyone backed a
/// suggestion), and "Grubun Önerileri" — one card per suggested title.
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
              controller.suggestions.isEmpty &&
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
                  'Grubun Önerileri',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.suggestions.isEmpty)
                  _emptyText(
                    'Henüz öneri yok. Bir filmin detayından "Bunu izleyelim '
                    'mi?" ile gruba öner; herkes onaylarsa eşleşme olur.',
                  )
                else
                  for (final item in controller.suggestions) ...[
                    _suggestionCard(item),
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

  /// One card per suggested title: who suggested it, who's in, who passed,
  /// and "2/3 onay" progress. Everyone in → "🎉 Eşleşme".
  Widget _suggestionCard(GroupSuggestion item) {
    final progress = item.memberCount == 0
        ? 0.0
        : item.supportCount / item.memberCount;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: item.isMatch ? AppColors.primaryContainer : AppColors.outline,
        ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.name,
                            style: AppTextStyles.headlineMd.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (item.isMatch)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              '🎉 Eşleşme',
                              style: AppTextStyles.labelSm.copyWith(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.suggestedBy.join(', ')} önerdi · '
                      '${_formatDate(item.lastActivityAt)}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if ((item.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${item.note}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${item.supportCount}/${item.memberCount} onay',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (item.acceptedBy.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _peopleLine(
                        Icons.check_circle,
                        AppColors.primaryContainer,
                        '${item.acceptedBy.join(', ')} onayladı',
                      ),
                    ],
                    if (item.passedBy.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _peopleLine(
                        Icons.close,
                        AppColors.onSurfaceVariant,
                        '${item.passedBy.join(', ')} geçti',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _peopleLine(IconData icon, Color color, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: 13, color: color),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: AppTextStyles.labelSm.copyWith(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }
}
