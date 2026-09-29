import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/plan_time.dart';
import '../../../data/models/plan_model.dart';
import '../controllers/plans_controller.dart';

/// A watch plan: poster, when (+ countdown when [highlight]), who's coming,
/// Katılıyorum / Belki / Gelemem for invitees, and cancel for the creator.
/// Must be built inside an Obx (reads [PlansController.busy]).
class PlanCard extends StatelessWidget {
  const PlanCard({required this.plan, this.highlight = false, super.key});

  final PlanModel plan;

  /// "Sıradaki Plan": bigger poster, countdown, glow.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final plans = Get.find<PlansController>();
    final isCreator = plans.isCreator(plan);
    final busy = plans.busy.contains(plan.id);
    final going = plan.attendees.where((a) => a.response == PlanResponse.going);
    final maybe = plan.attendees.where((a) => a.response == PlanResponse.maybe);
    final pending = plan.attendees.where(
      (a) => a.response == PlanResponse.pending,
    );
    final notGoing = plan.attendees.where(
      (a) => a.response == PlanResponse.notGoing,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlight ? AppColors.primaryContainer : AppColors.outline,
        ),
        boxShadow: highlight
            ? [BoxShadow(color: AppColors.glowPrimary, blurRadius: 16)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () =>
                    Get.toNamed(AppRoutes.detail, arguments: plan.title),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: highlight ? 70 : 48,
                    height: highlight ? 105 : 72,
                    child: plan.title.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: plan.title.posterUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: AppColors.surfaceContainerLow),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: highlight ? 17 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        formatPlanTime(plan.scheduledAt),
                        plan.groupName ??
                            (plan.isSolo ? 'Tek başına' : 'Arkadaşlarla'),
                      ].join(' · '),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    if (highlight && !plan.hasStarted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '⏳ ${countdown(plan.scheduledAt)}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (!isCreator)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${plan.creatorDisplayName} planladı',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if ((plan.note ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '"${plan.note}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCreator && !plan.hasStarted)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
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
            ],
          ),
          if (!plan.isSolo) ...[
            const SizedBox(height: AppSpacing.sm),
            _people('✅', going),
            _people('🤔', maybe),
            _people('⏳', pending),
            _people('❌', notGoing),
          ],
          if (!isCreator && !plan.hasStarted) ...[
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
                      padding: const EdgeInsets.symmetric(horizontal: 2),
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
    );
  }

  Widget _people(String icon, Iterable<PlanAttendee> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$icon ${list.map((a) => a.displayName).join(', ')}',
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 11,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _responseButton(
    String label, {
    required bool selected,
    VoidCallback? onTap,
  }) => SizedBox(
    height: 32,
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
          '${plan.isSolo ? '.' : ' ve davetliler listesinden kalkacak.'}',
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

/// "Nasıldı?" — a started plan the user hasn't closed: İzledik ✓ (adds it to
/// the library) or İzlemedik.
class PlanOutcomeCard extends StatelessWidget {
  const PlanOutcomeCard({required this.plan, super.key});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final plans = Get.find<PlansController>();
    final busy = plans.busy.contains(plan.id);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 40,
              height: 60,
              child: plan.title.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: plan.title.posterUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.surfaceContainerLow),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The "Nasıldı?" section header already asks the question.
                Text(
                  plan.title.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd,
                ),
                Text(
                  formatPlanTime(plan.scheduledAt),
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => plans.setOutcome(plan, PlanOutcome.skipped),
            child: const Text('İzlemedik'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () => plans.setOutcome(plan, PlanOutcome.watched),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('İzledik ✓'),
          ),
        ],
      ),
    );
  }
}
