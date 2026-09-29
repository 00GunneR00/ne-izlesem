import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../core/utils/plan_time.dart';
import '../../../data/models/library_entry_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/tracking_model.dart';
import '../../account/widgets/app_drawer.dart';
import '../../plans/controllers/plans_controller.dart';
import '../../plans/widgets/plan_card.dart';
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

/// One entry in the "Bu Hafta" calendar.
class _DayEvent {
  const _DayEvent(this.icon, this.text, this.title);
  final String icon;
  final String text;
  final TitleModel title;
}

/// Takip: "Nasıldı?" for started plans, the next plan, a 7-day calendar
/// (plans, new episodes, releases), other upcoming plans, and shows in
/// progress.
class TakipView extends GetView<TakipController> {
  const TakipView({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = Get.find<PlansController>();
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
                  if (controller.isLoading.value && plans.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = controller.tracking.value;
                  final outcome = plans.needsOutcome;
                  final next = plans.nextPlan;
                  final others = plans.upcoming.skip(1).toList();
                  // Read here so Obx tracks busy state used inside cards.
                  plans.busy.length;
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
                      if (outcome.isNotEmpty)
                        _section(
                          'Nasıldı?',
                          Icons.rate_review_outlined,
                          _padded(
                            Column(
                              children: [
                                for (final p in outcome) ...[
                                  PlanOutcomeCard(plan: p),
                                  const SizedBox(height: AppSpacing.xs),
                                ],
                              ],
                            ),
                          ),
                        ),
                      _section(
                        'Sıradaki Plan',
                        Icons.alarm,
                        next == null
                            ? _hint(
                                'Henüz bir planın yok. Bir film ya da dizinin '
                                'detayından "Planla"ya dokun; tek başına, grupla '
                                'ya da arkadaşlarınla.',
                              )
                            : _padded(PlanCard(plan: next, highlight: true)),
                      ),
                      _section(
                        'Bu Hafta',
                        Icons.calendar_month_outlined,
                        _weekCalendar(plans, data),
                      ),
                      if (others.isNotEmpty)
                        _section(
                          'Planlarım',
                          Icons.event_note_outlined,
                          _padded(
                            Column(
                              children: [
                                for (final p in others) ...[
                                  PlanCard(plan: p),
                                  const SizedBox(height: AppSpacing.xs),
                                ],
                              ],
                            ),
                          ),
                        ),
                      if (data != null && data.continueWatching.isNotEmpty)
                        _section(
                          'İzlemeye Devam Et',
                          Icons.play_circle_outline,
                          _continueStrip(data.continueWatching),
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

  /// Seven day chips (today + 6) with a dot where something's on, and the
  /// selected day's plans / new episodes / releases below. Releases further
  /// out get a one-line "Sonra" teaser.
  Widget _weekCalendar(PlansController plans, TrackingModel? data) {
    final today = DateTime.now();
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(today.year, today.month, today.day + i),
    ];

    List<_DayEvent> eventsOn(DateTime day) => [
      for (final p in plans.plans)
        if (isSameDay(p.scheduledAt, day) &&
            p.myResponse != PlanResponse.notGoing)
          _DayEvent(
            '📅',
            '${formatPlanTime(p.scheduledAt).split(' ').last} · ${p.title.name}'
                '${p.groupName != null ? ' (${p.groupName})' : ''}',
            p.title,
          ),
      if (data != null)
        for (final e in data.newEpisodes)
          if (isSameDay(e.airDate, day))
            _DayEvent(
              '📺',
              '${e.title.name} · S${e.season} B${e.episode}',
              e.title,
            ),
      if (data != null)
        for (final u in data.upcoming)
          if (isSameDay(u.releaseDate, day))
            _DayEvent('🎬', '${u.title.name} vizyonda', u.title),
    ];

    final selected = days[controller.selectedDay.value.clamp(0, 6)];
    final events = eventsOn(selected);
    final later = data == null
        ? <UpcomingReleaseModel>[]
        : data.upcoming
              .where(
                (u) => u.releaseDate.isAfter(
                  days.last.add(const Duration(days: 1)),
                ),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, i) {
              final day = days[i];
              final isSelected = i == controller.selectedDay.value;
              final hasEvents = eventsOn(day).isNotEmpty;
              return GestureDetector(
                onTap: () => controller.selectDay(i),
                child: Container(
                  width: 46,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.outline,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i == 0 ? 'Bugün' : shortWeekday(day),
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.onSurface,
                        ),
                      ),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEvents
                              ? (isSelected
                                    ? Colors.white
                                    : AppColors.primaryContainer)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (events.isEmpty)
          _hint('Bu gün için plan, yeni bölüm ya da vizyon yok.')
        else
          for (final e in events)
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.detail, arguments: e.title),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(e.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        e.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (later.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Text(
              'Sonra: ${later.take(3).map((u) => '${u.title.name} · ${u.releaseDate.day} ${_months[u.releaseDate.month - 1]}').join('  ·  ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
      ],
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

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: child,
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
