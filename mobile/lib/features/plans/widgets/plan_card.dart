import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/plan_time.dart';
import '../../../data/models/plan_model.dart';
import '../controllers/plans_controller.dart';

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// A watch plan in the agenda style shared by Takip and the notifications
/// page: time column · poster · title / who / attendees, and
/// Katılıyorum · Belki · Gelemem for invitees. Must be built inside an Obx
/// (reads [PlansController.busy]).
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    this.isNext = false,
    this.showDate = false,
    this.dimmed = false,
    super.key,
  });

  final PlanModel plan;

  /// The soonest plan: accent bar on the left and a countdown.
  final bool isNext;

  /// Show the day under the time (when not listed under a day header).
  final bool showDate;

  /// The user said Gelemem: shown faded, still answerable.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final plans = Get.find<PlansController>();
    final isCreator = plans.isCreator(plan);
    final busy = plans.busy.contains(plan.id);
    final canRespond = !isCreator && !plan.hasStarted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent bar marks the next plan.
            Container(
              width: 4,
              color: isNext ? AppColors.primaryContainer : Colors.transparent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Declined: content fades, the answer buttons stay bright.
                    Opacity(
                      opacity: dimmed ? 0.45 : 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 48,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hhmm(plan.scheduledAt),
                                  style: AppTextStyles.headlineMd.copyWith(
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (showDate)
                                  Text(
                                    formatPlanTime(
                                      plan.scheduledAt,
                                    ).split(' ').first,
                                    style: AppTextStyles.labelSm.copyWith(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.toNamed(
                              AppRoutes.detail,
                              arguments: plan.title,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: SizedBox(
                                width: 40,
                                height: 60,
                                child: plan.title.posterUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: plan.title.posterUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.surfaceContainerLow,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _details(isCreator)),
                          if (isCreator && !plan.hasStarted)
                            SizedBox(
                              width: 28,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.onSurfaceVariant,
                                  size: 18,
                                ),
                                color: AppColors.surfaceContainerHigh,
                                onSelected: (_) => _confirmCancel(plans),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'cancel',
                                    child: Text('Planı iptal et'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (dimmed)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Gelemem dedin · fikrin değişirse aşağıdan seç',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (canRespond) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (final (response, label) in const [
                            (PlanResponse.going, 'Katılıyorum'),
                            (PlanResponse.maybe, 'Belki'),
                            (PlanResponse.notGoing, 'Gelemem'),
                          ])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: _responseButton(
                                  label,
                                  selected: plan.myResponse == response,
                                  onTap: busy
                                      ? null
                                      : () => plans.respond(plan, response),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(bool isCreator) {
    final who = plan.groupName ?? (plan.isSolo ? 'Tek başına' : 'Arkadaşlarla');
    final meta = [
      who,
      if (!isCreator) '${plan.creatorDisplayName} planladı',
      if (isNext && !plan.hasStarted) countdown(plan.scheduledAt),
    ].join(' · ');

    int count(PlanResponse r) =>
        plan.attendees.where((a) => a.response == r).length;
    final summary = [
      if (count(PlanResponse.going) > 0) '✅ ${count(PlanResponse.going)}',
      if (count(PlanResponse.maybe) > 0) '🤔 ${count(PlanResponse.maybe)}',
      if (count(PlanResponse.pending) > 0) '⏳ ${count(PlanResponse.pending)}',
      if (count(PlanResponse.notGoing) > 0) '✕ ${count(PlanResponse.notGoing)}',
    ].join('   ');
    final names = plan.attendees
        .map((a) => '${a.displayName} ${_icon(a.response)}')
        .join(', ');

    final muted = AppTextStyles.labelSm.copyWith(
      fontSize: 11,
      color: AppColors.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plan.title.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMd.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
        if (!plan.isSolo) ...[
          const SizedBox(height: 2),
          Tooltip(
            message: names,
            triggerMode: TooltipTriggerMode.tap,
            child: Text(
              summary,
              style: muted.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
        if ((plan.note ?? '').isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '"${plan.note}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  static String _icon(PlanResponse r) => switch (r) {
    PlanResponse.going => '✅',
    PlanResponse.maybe => '🤔',
    PlanResponse.pending => '⏳',
    PlanResponse.notGoing => '✕',
  };

  Widget _responseButton(
    String label, {
    required bool selected,
    VoidCallback? onTap,
  }) => SizedBox(
    height: 30,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: selected
            ? AppColors.primaryContainer
            : Colors.transparent,
        side: BorderSide(
          color: selected ? AppColors.primaryContainer : AppColors.outline,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 12,
          color: selected ? Colors.white : AppColors.primary,
        ),
      ),
    ),
  );

  Future<void> _confirmCancel(PlansController plans) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Planı iptal et', style: AppTextStyles.headlineMd),
        content: Text(
          '${plan.title.name} · ${formatPlanTime(plan.scheduledAt)} planı iptal edilecek'
          '${plan.isSolo ? '.' : ' ve davetlilerin listesinden kalkacak.'}',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('İptal et'),
          ),
        ],
      ),
    );
    if (ok == true) await plans.cancel(plan);
  }
}

/// Thin "<title> nasıldı?" strip for a started plan: İzledik ✓ (adds it to
/// the library) or İzlemedik.
class PlanOutcomeCard extends StatelessWidget {
  const PlanOutcomeCard({required this.plan, super.key});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final plans = Get.find<PlansController>();
    final busy = plans.busy.contains(plan.id);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 28,
              height: 42,
              child: plan.title.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: plan.title.posterUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.surfaceContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: plan.title.name,
                style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                children: [
                  TextSpan(
                    text: ' nasıldı?',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => plans.setOutcome(plan, PlanOutcome.skipped),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('İzlemedik'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () => plans.setOutcome(plan, PlanOutcome.watched),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('İzledik ✓'),
          ),
        ],
      ),
    );
  }
}
