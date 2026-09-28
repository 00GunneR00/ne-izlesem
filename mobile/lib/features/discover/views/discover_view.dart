import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../data/models/enums.dart';
import '../../account/widgets/app_drawer.dart';
import '../../social/widgets/notification_bell.dart';
import '../controllers/discover_controller.dart';
import '../widgets/trailer_feed_item.dart';

class DiscoverView extends GetView<DiscoverController> {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value && controller.feed.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.feed.isEmpty) {
              return Center(
                child: Text(
                  'Bu filtrede içerik bulunamadı.',
                  style: AppTextStyles.bodyMd,
                ),
              );
            }
            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: controller.feed.length,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) => TrailerFeedItem(
                title: controller.feed[index],
                genreName: controller.genreName,
              ),
            );
          }),
          SafeArea(
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
                            icon: const Icon(
                              Icons.menu,
                              color: AppColors.primary,
                            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: SizedBox(
                    height: 36,
                    child: Obx(
                      () => ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _genreChip(
                            'Tümü',
                            controller.selectedGenreId.value == null,
                            () => controller.selectGenre(null),
                          ),
                          ...controller.genres.map(
                            (g) => _genreChip(
                              g.name,
                              controller.selectedGenreId.value == g.id,
                              () => controller.selectGenre(g.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Obx(
                    () => ToggleButtons(
                      isSelected: [
                        controller.mediaType.value == MediaType.movie,
                        controller.mediaType.value == MediaType.show,
                      ],
                      onPressed: (i) => controller.switchMediaType(
                        i == 0 ? MediaType.movie : MediaType.show,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      borderColor: AppColors.outline,
                      selectedBorderColor: AppColors.primaryContainer,
                      fillColor: AppColors.primaryContainer,
                      selectedColor: Colors.white,
                      color: AppColors.secondary,
                      constraints: const BoxConstraints(minHeight: 32),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Film', style: AppTextStyles.labelSm),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Dizi', style: AppTextStyles.labelSm),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genreChip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.xs),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.2)
              : AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer.withValues(alpha: 0.5)
                : AppColors.outline,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: selected ? AppColors.primary : AppColors.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}
