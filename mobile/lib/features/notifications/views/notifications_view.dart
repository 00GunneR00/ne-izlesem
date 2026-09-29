import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/suggestion_model.dart';
import '../../plans/controllers/plans_controller.dart';
import '../../plans/widgets/plan_card.dart';
import '../../social/controllers/social_controller.dart';
import '../../social/widgets/dismissible_action.dart';
import '../../social/widgets/suggestion_card.dart';

Color _avatarColor(String seed) {
  const palette = [
    Color(0xFFE07A5F),
    Color(0xFF3D5A80),
    Color(0xFF81B29A),
    Color(0xFFF2CC8F),
    Color(0xFFB56576),
  ];
  return palette[seed.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
}

/// Friend requests, "Bunu izleyelim mi?" suggestions, and suggestion-response
/// notifications — all reached via the bell icon on the main tabs. Reuses
/// SocialController (already alive via RootBinding).
class NotificationsView extends GetView<SocialController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          Obx(
            () => controller.unseenNotificationCount > 0
                ? IconButton(
                    tooltip: 'Tümünü okundu işaretle',
                    icon: const Icon(Icons.done_all, color: AppColors.primary),
                    onPressed: controller.markAllNotificationsSeen,
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => controller.clearableNotificationCount > 0
                ? IconButton(
                    tooltip: 'Okunanları temizle',
                    icon: const Icon(
                      Icons.cleaning_services_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: controller.clearReadNotifications,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Obx(() {
              final plans = Get.find<PlansController>();
              final invites = plans.pendingInvites;
              plans.busy.length; // tracked for the RSVP buttons' busy state
              final hasAnything =
                  invites.isNotEmpty ||
                  controller.groupMatchNotifications.isNotEmpty ||
                  controller.incomingRequests.isNotEmpty ||
                  controller.suggestionInbox.isNotEmpty ||
                  controller.suggestionNotifications.isNotEmpty;
              if (!hasAnything) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'Henüz bildirimin yok.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waiting for Katılıyorum / Belki / Gelemem — answering
                  // moves them to Takip's plans.
                  if (invites.isNotEmpty) ...[
                    Text(
                      'Plan Davetleri',
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final p in invites) ...[
                      PlanCard(plan: p),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (controller.groupMatchNotifications.isNotEmpty) ...[
                    _groupMatchesSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (controller.incomingRequests.isNotEmpty) ...[
                    _requestsSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (controller.suggestionInbox.isNotEmpty) ...[
                    _suggestionInboxSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (controller.suggestionNotifications.isNotEmpty)
                    _notificationsSection(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Unread items get a primary-tinted border so they stand out until the
  /// user taps "Tümünü okundu işaretle".
  BoxDecoration _itemDecoration({required bool unread}) => BoxDecoration(
    color: AppColors.surfaceContainerLow,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: unread
          ? AppColors.primary.withValues(alpha: 0.6)
          : AppColors.outline,
    ),
  );

  Widget _groupMatchesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Grup Eşleşmeleri',
        style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final n in controller.groupMatchNotifications)
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Get.toNamed(AppRoutes.detail, arguments: n.title),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: _itemDecoration(unread: !n.seen),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 36,
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: n.title.posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: n.title.posterUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppColors.surfaceContainer),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Eşleşme! 🎉 "${n.groupName}" grubunda herkes '
                    '"${n.title.name}" izlemek istiyor.',
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _requestsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Arkadaşlık İstekleri',
        style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final request in controller.incomingRequests)
        DismissibleAction(
          key: ValueKey(request.friendshipId),
          builder: (context, dismiss) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: _itemDecoration(unread: !request.seen),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _avatarColor(request.requesterUsername),
                  child: Text(
                    request.requesterDisplayName.isNotEmpty
                        ? request.requesterDisplayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${request.requesterDisplayName} (@${request.requesterUsername})',
                    style: AppTextStyles.bodyMd,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      dismiss(() => controller.acceptRequest(request)),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      dismiss(() => controller.declineRequest(request)),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _suggestionInboxSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bunu İzleyelim mi?',
        style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final item in controller.suggestionInbox) SuggestionCard(item: item),
    ],
  );

  Widget _notificationsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Bildirimler',
        style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final n in controller.suggestionNotifications)
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: _itemDecoration(unread: !n.seen),
          child: Row(
            children: [
              Icon(
                n.status == SuggestionStatus.accepted
                    ? Icons.check_circle
                    : Icons.close,
                color: n.status == SuggestionStatus.accepted
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  n.status == SuggestionStatus.accepted
                      ? '${n.recipientDisplayName}, "${n.title.name}" filmini izleyecekler listesine ekledi.'
                      : '${n.recipientDisplayName}, "${n.title.name}" önerini geçti.',
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
