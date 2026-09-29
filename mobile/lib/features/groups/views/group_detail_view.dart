import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
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
                _segmentedTabs(controller),
                const SizedBox(height: AppSpacing.lg),
                if (controller.selectedTab.value == 0) ...[
                  if (controller.matches.isEmpty)
                    _emptyText(
                      'Henüz eşleşme yok. "Birlikte Seç"te herkesin sağa '
                      'kaydırdığı ya da herkesin onayladığı öneriler burada '
                      'görünür.',
                    )
                  else
                    _matchesList(controller),
                ] else ...[
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

  /// Eşleşmeler | Grubun Önerileri — same look as Sosyal's
  /// Arkadaş Akışı | Genel Trend switch, with counts.
  Widget _segmentedTabs(GroupDetailController controller) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      children: [
        Expanded(
          child: _tabButton(
            controller,
            'Eşleşmeler · ${controller.matches.length}',
            0,
          ),
        ),
        Expanded(
          child: _tabButton(
            controller,
            'Grubun Önerileri · ${controller.suggestions.length}',
            1,
          ),
        ),
      ],
    ),
  );

  Widget _tabButton(GroupDetailController controller, String label, int index) {
    final selected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.selectTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Matches as a ranked list: each row has İzleyelim / Kararsız /
  /// İzlemeyelim on the right. Score = İzleyelim − İzlemeyelim; the top one
  /// gets 🏆 once its score is positive.
  Widget _matchesList(GroupDetailController controller) {
    final matches = controller.visibleMatches;
    final filter = controller.matchFilter.value;
    final busyIds = controller.voting.toSet();
    final movieCount = controller.matches
        .where((m) => m.title.mediaType == MediaType.movie)
        .length;
    final showCount = controller.matches.length - movieCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(
                controller,
                'Tümü · ${controller.matches.length}',
                null,
              ),
              _filterChip(controller, 'Filmler · $movieCount', MediaType.movie),
              _filterChip(controller, 'Diziler · $showCount', MediaType.show),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '👍 İzleyelim +1 · 🤔 Kararsız 0 · 👎 İzlemeyelim −1 — en yüksek '
          'puanlı en üstte.',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (matches.isEmpty)
          _emptyText(
            filter == MediaType.show
                ? 'Henüz dizi eşleşmesi yok. "Birlikte Seç"te Dizi\'ye geçip '
                      'kaydırın.'
                : 'Henüz film eşleşmesi yok.',
          )
        else
          for (var i = 0; i < matches.length; i++) ...[
            _matchRow(
              controller,
              matches[i],
              rank: i + 1,
              busy: busyIds.contains(matches[i].id),
              // In "Tümü", mark shows so they stand out from films.
              showTypeBadge: filter == null,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }

  Widget _filterChip(
    GroupDetailController controller,
    String label,
    MediaType? type,
  ) {
    final selected = controller.matchFilter.value == type;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: GestureDetector(
        onTap: () => controller.setMatchFilter(type),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.outline),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? AppColors.onSurface : AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchRow(
    GroupDetailController controller,
    GroupMatch match, {
    required int rank,
    required bool busy,
    required bool showTypeBadge,
  }) {
    final isTop = rank == 1 && match.score > 0;
    final year =
        match.title.releaseDate != null && match.title.releaseDate!.length >= 4
        ? match.title.releaseDate!.substring(0, 4)
        : null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isTop ? AppColors.primaryContainer : AppColors.outline,
        ),
        boxShadow: isTop
            ? [BoxShadow(color: AppColors.glowPrimary, blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              isTop ? '🏆' : '#$rank',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: isTop ? 18 : 12,
                color: AppColors.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.detail, arguments: match.title),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 44,
                height: 66,
                child: match.title.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: match.title.posterUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.surfaceContainerLow),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  Get.toNamed(AppRoutes.detail, arguments: match.title),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.title.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      ?year,
                      if (showTypeBadge &&
                          match.title.mediaType == MediaType.show)
                        'Dizi',
                      'Puan ${match.score > 0 ? '+' : ''}${match.score}',
                    ].join(' · '),
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '👍 ${match.yes.length}  🤔 ${match.maybe.length}  '
                    '👎 ${match.no.length}',
                    style: AppTextStyles.labelSm.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final (vote, emoji, label) in const [
            (MatchVote.yes, '👍', 'İzleyelim'),
            (MatchVote.maybe, '🤔', 'Kararsız'),
            (MatchVote.no, '👎', 'İzlemeyelim'),
          ])
            _voteButton(
              emoji: emoji,
              tooltip: _voteTooltip(label, match, vote),
              selected: match.myVote == vote,
              onTap: busy ? null : () => controller.vote(match, vote),
            ),
        ],
      ),
    );
  }

  String _voteTooltip(String label, GroupMatch match, MatchVote vote) {
    final names = switch (vote) {
      MatchVote.yes => match.yes,
      MatchVote.maybe => match.maybe,
      MatchVote.no => match.no,
    };
    return names.isEmpty ? label : '$label: ${names.join(', ')}';
  }

  Widget _voteButton({
    required String emoji,
    required String tooltip,
    required bool selected,
    required VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerHigh,
            border: Border.all(
              color: selected ? AppColors.primaryContainer : AppColors.outline,
            ),
          ),
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
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
