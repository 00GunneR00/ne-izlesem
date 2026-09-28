import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../data/models/enums.dart';
import '../../account/widgets/app_drawer.dart';
import '../../social/widgets/notification_bell.dart';
import '../controllers/swipe_controller.dart';
import '../widgets/swipe_card.dart';

class SwipeView extends GetView<SwipeController> {
  const SwipeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            GlassContainer(
              border: const Border(
                bottom: BorderSide(color: AppColors.outline),
              ),
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
                        'Ne İzlesem?',
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Obx(
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
                  final next = controller.queue.length > 1
                      ? controller.queue[1]
                      : null;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (next != null)
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _roundButton(
                              icon: Icons.close,
                              size: 64,
                              background: AppColors.surfaceContainer,
                              borderColor: AppColors.secondary,
                              iconColor: AppColors.secondary,
                              onTap: controller.pass,
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            _roundButton(
                              icon: Icons.bookmark_outline,
                              size: 48,
                              background: AppColors.surfaceContainer,
                              borderColor: AppColors.outline,
                              iconColor: AppColors.tertiary,
                              onTap: () {
                                controller.bookmark(top);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'İzleyeceğim listesine eklendi',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            _roundButton(
                              icon: Icons.check_circle,
                              size: 64,
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
    required double size,
    required Color background,
    required Color iconColor,
    Color? borderColor,
    bool glow = false,
    required VoidCallback onTap,
  }) => InkWell(
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
