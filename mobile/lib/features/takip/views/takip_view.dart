import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/library_entry_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/tracking_model.dart';
import '../../account/widgets/app_drawer.dart';
import '../../social/widgets/notification_bell.dart';
import '../controllers/takip_controller.dart';

const _months = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

/// "Bugün", "Dün", "3 gün önce", "2 gün sonra", or "12 Eki" further out.
String _relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(today).inDays;
  if (days == 0) return 'Bugün';
  if (days == -1) return 'Dün';
  if (days == 1) return 'Yarın';
  if (days < 0 && days >= -7) return '${-days} gün önce';
  if (days > 0 && days <= 7) return '$days gün sonra';
  return '${date.day} ${_months[date.month - 1]}';
}

/// The personal "what's on for me" board: shows in progress, new episodes,
/// watchlist titles not out yet, and group matches.
class TakipView extends GetView<TakipController> {
  const TakipView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.reload,
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = controller.tracking.value;
                  if (data == null) {
                    return _message(
                      controller.hasError.value
                          ? 'Takip bilgileri yüklenemedi. Aşağı çekip tekrar dene.'
                          : 'Yükleniyor...',
                    );
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Bottom padding clears the floating nav bar.
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.md,
                      0,
                      110,
                    ),
                    children: [
                      _section(
                        'İzlemeye Devam Et',
                        Icons.play_circle_outline,
                        data.continueWatching.isEmpty
                            ? _hint(
                                'Bir dizinin detayından "Dizi Takibi" ile '
                                'bölüm işaretlediğinde burada görünür.',
                              )
                            : _continueStrip(data.continueWatching),
                      ),
                      _section(
                        'Yeni Bölümler',
                        Icons.live_tv,
                        data.newEpisodes.isEmpty
                            ? _hint(
                                'Takip ettiğin dizilerde bu hafta çıkan ya da '
                                'önümüzdeki 30 günde çıkacak bölüm yok.',
                              )
                            : Column(
                                children: [
                                  for (final e in data.newEpisodes)
                                    _NewEpisodeTile(item: e),
                                ],
                              ),
                      ),
                      _section(
                        'Yakında Vizyonda',
                        Icons.event,
                        data.upcoming.isEmpty
                            ? _hint(
                                'İzleyeceğim listende henüz çıkmamış bir yapım yok.',
                              )
                            : Column(
                                children: [
                                  for (final u in data.upcoming)
                                    _UpcomingTile(item: u),
                                ],
                              ),
                      ),
                      _section(
                        'Grup Eşleşmeleri',
                        Icons.celebration_outlined,
                        data.groupMatches.isEmpty
                            ? _hint(
                                'Bir grupta "Birlikte Seç" ile kaydırın; '
                                'herkesin beğendiği yapımlar burada görünür.',
                              )
                            : _matchesStrip(data.groupMatches),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => GlassContainer(
    border: const Border(bottom: BorderSide(color: AppColors.outline)),
    child: SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.sm),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              'Takip',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineLgMobile.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    ),
  );

  Widget _message(String text) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );

  Widget _section(String title, IconData icon, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    ),
  );

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Text(
      text,
      style: AppTextStyles.bodyMd.copyWith(
        fontSize: 13,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _continueStrip(List<LibraryEntryModel> shows) => SizedBox(
    height: 196,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: shows.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final entry = shows[index];
        return Obx(
          () => _ContinueCard(
            entry: entry,
            busy: controller.advancing.contains(entry.id),
            onNext: () => controller.advanceEpisode(entry),
          ),
        );
      },
    ),
  );

  Widget _matchesStrip(List<GroupMatchNotification> matches) => SizedBox(
    height: 200,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final m = matches[index];
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.detail, arguments: m.title),
          child: SizedBox(
            width: 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Poster(title: m.title, width: 104, height: 150),
                const SizedBox(height: 4),
                Text(
                  m.title.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm,
                ),
                Text(
                  '🎉 ${m.groupName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.title,
    required this.width,
    required this.height,
  });

  final TitleModel title;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: SizedBox(
      width: width,
      height: height,
      child: title.posterUrl != null
          ? CachedNetworkImage(imageUrl: title.posterUrl!, fit: BoxFit.cover)
          : Container(color: AppColors.surfaceContainer),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.entry,
    required this.busy,
    required this.onNext,
  });

  final LibraryEntryModel entry;
  final bool busy;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final title = entry.title;
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.detail, arguments: title),
            child: Stack(
              children: [
                _Poster(title: title, width: 112, height: 132),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.md),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.background.withValues(alpha: 0.75),
                      child: Text(
                        entry.progressLabel ?? 'Başlamadın',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: FilledButton.icon(
              onPressed: busy ? null : onNext,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: AppTextStyles.labelSm.copyWith(fontSize: 12),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Sonraki'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewEpisodeTile extends StatelessWidget {
  const _NewEpisodeTile({required this.item});

  final NewEpisodeModel item;

  @override
  Widget build(BuildContext context) {
    final when = _relativeDay(item.airDate);
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.detail, arguments: item.title),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            _Poster(title: item.title, width: 44, height: 64),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd,
                  ),
                  Text(
                    [
                      'S${item.season} · B${item.episode}',
                      if ((item.episodeName ?? '').isNotEmpty)
                        item.episodeName!,
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.aired
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                item.aired ? 'Yeni · $when' : when,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 11,
                  color: item.aired ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item});

  final UpcomingReleaseModel item;

  @override
  Widget build(BuildContext context) {
    final date = item.releaseDate;
    final now = DateTime.now();
    final daysLeft = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.detail, arguments: item.title),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            _Poster(title: item.title, width: 44, height: 64),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd,
                  ),
                  Text(
                    '${date.day} ${_months[date.month - 1]} ${date.year}',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                daysLeft <= 1 ? 'Yarın' : '$daysLeft gün kaldı',
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
