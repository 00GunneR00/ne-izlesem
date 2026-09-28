import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/title_model.dart';
import '../../swipe/widgets/swipe_card.dart';
import '../controllers/group_swipe_controller.dart';

/// "Birlikte Seç" — members swipe the same deck; a title everyone swipes
/// right on becomes the group's match.
class GroupSwipeView extends StatelessWidget {
  const GroupSwipeView({required this.group, super.key});

  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      GroupSwipeController(
        group,
        onMatch: (title) =>
            Get.dialog(_MatchDialog(group: group, title: title)),
      ),
      tag: 'group-swipe-${group.id}',
    );
    return Scaffold(
      appBar: AppBar(title: Text('Birlikte Seç · ${group.name}')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'Herkes sağa kaydırdığında eşleşirsiniz. '
                'Grubun beğendikleri önce gelir.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Obx(
              () => ToggleButtons(
                isSelected: [
                  controller.mediaType.value == MediaType.movie,
                  controller.mediaType.value == MediaType.show,
                ],
                onPressed: (index) => controller.switchMediaType(
                  index == 0 ? MediaType.movie : MediaType.show,
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderColor: AppColors.outline,
                selectedBorderColor: AppColors.primaryContainer,
                fillColor: AppColors.primaryContainer,
                selectedColor: Colors.white,
                color: AppColors.secondary,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Film', style: AppTextStyles.labelSm),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Dizi', style: AppTextStyles.labelSm),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Obx(() {
                  if (controller.isLoading.value && controller.queue.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final top = controller.current;
                  if (top == null) {
                    return Center(
                      child: Text(
                        'Şu an gösterilecek içerik kalmadı.',
                        style: AppTextStyles.bodyMd,
                      ),
                    );
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (controller.queue.length > 1)
                        Positioned.fill(
                          top: 12,
                          bottom: 92,
                          child: Opacity(
                            opacity: 0.5,
                            child: Transform.scale(
                              scale: 0.95,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                  border: Border.all(color: AppColors.outline),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        bottom: 92,
                        child: Center(
                          child: SwipeCard(
                            key: ValueKey('${top.mediaType}-${top.tmdbId}'),
                            title: top,
                            genreName: controller.genreName,
                            likeLabel: 'İZLEYELİM',
                            onSwiped: (direction) =>
                                direction == SwipeDirection.like
                                ? controller.like()
                                : controller.pass(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Row(
                          children: [
                            _roundButton(
                              icon: Icons.close,
                              background: AppColors.surfaceContainer,
                              borderColor: AppColors.secondary,
                              iconColor: AppColors.secondary,
                              onTap: controller.pass,
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            _roundButton(
                              icon: Icons.favorite,
                              background: AppColors.primaryContainer,
                              iconColor: Colors.white,
                              glow: true,
                              onTap: controller.like,
                            ),
                          ],
                        ),
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

  Widget _roundButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    Color? borderColor,
    bool glow = false,
    required VoidCallback onTap,
  }) {
    const size = 64.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: AppColors.glowPrimary,
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}

class _MatchDialog extends StatelessWidget {
  const _MatchDialog({required this.group, required this.title});

  final GroupModel group;
  final TitleModel title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.primaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                'Eşleşme! 🎉',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (title.posterUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 140,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: CachedNetworkImage(
                      imageUrl: title.posterUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${group.name}" grubunda herkes bunu izlemek istiyor. '
              'Film gecesi belli oldu!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    child: const Text('Devam Et'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.detail, arguments: title);
                    },
                    child: const Text('Detaya Git'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
