import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../data/models/library_entry_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/tracking_model.dart';
import '../../account/widgets/app_drawer.dart';
import '../../plans/controllers/plans_controller.dart';
import '../../plans/widgets/plan_card.dart';
import '../../social/widgets/notification_bell.dart';
import '../controllers/takip_controller.dart';

const _days = [
  'PAZARTESİ',
  'SALI',
  'ÇARŞAMBA',
  'PERŞEMBE',
  'CUMA',
  'CUMARTESİ',
  'PAZAR',
];
const _months = [
  'OCA',
  'ŞUB',
  'MAR',
  'NİS',
  'MAY',
  'HAZ',
  'TEM',
  'AĞU',
  'EYL',
  'EKİ',
  'KAS',
  'ARA',
];

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// "BUGÜN", "YARIN", "CUMA · 2 EKİ".
String _dayHeader(DateTime day) {
  final diff = day.difference(_dayOf(DateTime.now())).inDays;
  if (diff == 0) return 'BUGÜN';
  if (diff == 1) return 'YARIN';
  return '${_days[day.weekday - 1]} · ${day.day} ${_months[day.month - 1]}';
}

/// A non-plan agenda line under a day: new episode or release.
class _Extra {
  const _Extra(this.icon, this.text, this.title);
  final IconData icon;
  final String text;
  final TitleModel title;
}

/// Takip as one agenda: an optional thin "… nasıldı?" strip on top, then
/// one section per day (BUGÜN, YARIN, CUMA · 2 EKİ…) holding that day's
/// plans and — below them — new episodes and releases; "İzlemeye devam et"
/// at the bottom. Everything appears exactly once.
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
                  plans.busy.length; // tracked for the cards' busy state
                  final kind = controller.selectedKind.value;
                  bool ofKind(PlanModel p) => p.kind == kind;
                  // New episodes, releases and "devam et" are personal, so
                  // they live under Tek Başına.
                  final personal = kind == PlanKind.solo;
                  final data = controller.tracking.value;
                  final outcome = plans.needsOutcome.where(ofKind).toList();
                  final upcoming = plans.upcoming.where(ofKind).toList();
                  final nextId = upcoming.isEmpty ? null : upcoming.first.id;
                  // Declined plans stay listed (dimmed) so you can change your mind.
                  final days = _agenda(
                    plans.notStarted.where(ofKind).toList(),
                    personal ? data : null,
                  );

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Bottom padding clears the floating nav bar.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      110,
                    ),
                    children: [
                      _kindTabs(plans),
                      const SizedBox(height: AppSpacing.lg),
                      for (final p in outcome) ...[
                        PlanOutcomeCard(plan: p),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      if (outcome.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),
                      if (days.isEmpty)
                        _emptyAgenda(kind)
                      else
                        for (final day in days.entries) ...[
                          _header(_dayHeader(day.key)),
                          for (final p in day.value.plans) ...[
                            PlanCard(
                              plan: p,
                              isNext: p.id == nextId,
                              dimmed: p.myResponse == PlanResponse.notGoing,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          for (final e in day.value.extras) _extraRow(e),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      if (personal &&
                          data != null &&
                          data.continueWatching.isNotEmpty) ...[
                        _header('İZLEMEYE DEVAM ET'),
                        _continueStrip(data.continueWatching),
                      ],
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

  /// Days (sorted) → that day's plans and new-episode / release lines.
  Map<DateTime, ({List<PlanModel> plans, List<_Extra> extras})> _agenda(
    List<PlanModel> upcoming,
    TrackingModel? data,
  ) {
    final today = _dayOf(DateTime.now());
    final byDay = <DateTime, ({List<PlanModel> plans, List<_Extra> extras})>{};
    ({List<PlanModel> plans, List<_Extra> extras}) slot(DateTime d) =>
        byDay.putIfAbsent(
          _dayOf(d),
          () => (plans: <PlanModel>[], extras: <_Extra>[]),
        );

    for (final p in upcoming) {
      slot(p.scheduledAt).plans.add(p);
    }
    if (data != null) {
      for (final e in data.newEpisodes) {
        // Just-aired ones show under today; upcoming under their day.
        final day = e.airDate.isBefore(today) ? today : e.airDate;
        slot(day).extras.add(
          _Extra(
            Icons.live_tv,
            '${e.title.name} · S${e.season} B${e.episode}${e.aired ? ' · yeni' : ''}',
            e.title,
          ),
        );
      }
      for (final u in data.upcoming) {
        slot(u.releaseDate).extras.add(
          _Extra(
            Icons.local_movies_outlined,
            '${u.title.name} vizyonda',
            u.title,
          ),
        );
      }
    }
    final sorted = byDay.keys.toList()..sort();
    return {for (final d in sorted) d: byDay[d]!};
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

  /// Small, quiet day / section label.
  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text,
      style: AppTextStyles.labelSm.copyWith(
        fontSize: 12,
        letterSpacing: 1.2,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _extraRow(_Extra e) => InkWell(
    onTap: () => Get.toNamed(AppRoutes.detail, arguments: e.title),
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(e.icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              e.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );

  /// Tek Başına | Grupla | Arkadaşlarla — same look as Sosyal's switch.
  /// Counts are that kind's upcoming plans; a dot marks unanswered invites.
  Widget _kindTabs(PlansController plans) {
    Widget tab(PlanKind kind, String label) {
      final selected = controller.selectedKind.value == kind;
      final count = plans.notStarted.where((p) => p.kind == kind).length;
      final hasInvite = plans.pendingInvites.any((p) => p.kind == kind);
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.selectKind(kind),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.surfaceContainerHigh
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    count > 0 ? '$label · $count' : label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (hasInvite) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          tab(PlanKind.solo, 'Tek Başına'),
          tab(PlanKind.group, 'Grupla'),
          tab(PlanKind.friends, 'Arkadaşlarla'),
        ],
      ),
    );
  }

  Widget _emptyAgenda(PlanKind kind) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      children: [
        const Icon(
          Icons.event_available,
          size: 40,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(switch (kind) {
          PlanKind.solo => 'Kendine bir plan yap',
          PlanKind.group => 'Grup planın yok',
          PlanKind.friends => 'Arkadaşlarla planın yok',
        }, style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          switch (kind) {
            PlanKind.solo =>
              'Bir film ya da dizinin detayından "Planla" → Tek başıma. '
                  'Takip ettiğin dizilerin yeni bölümleri ve listendeki vizyon '
                  'tarihleri de burada görünür.',
            PlanKind.group =>
              'Grup sayfasında en çok oy alan eşleşme için "film gecesi '
                  'planla"ya dokun ya da detaydan "Planla" → Grup.',
            PlanKind.friends =>
              'Bir film ya da dizinin detayından "Planla" → Arkadaş ile '
                  'arkadaşlarını davet et.',
          },
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _continueStrip(List<LibraryEntryModel> shows) => SizedBox(
    height: 196,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
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
