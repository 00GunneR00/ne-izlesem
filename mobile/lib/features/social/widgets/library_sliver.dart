import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/library_poster_card.dart';

/// Sosyal's "Listem" tab: the user's library (İzlediklerim / İzleyeceklerim
/// / İzliyorum + Film/Dizi filter) as a single sliver, so it scrolls inside
/// the Sosyal page like the feed does. Call from inside an Obx — it reads
/// the controller's observables.
Widget librarySliver(ProfileController controller) {
  final tab = controller.mainTab.value;
  final entries = controller.entriesFor(tab);
  final counts = [
    controller.watchedCount,
    controller.toWatchCount,
    controller.watchingCount,
  ];
  const labels = ['İzlediklerim', 'İzleyeceklerim', 'İzliyorum'];

  return SliverMainAxisGroup(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      _chip(
                        '${labels[i]} · ${counts[i]}',
                        selected: tab == i,
                        onTap: () => controller.changeMainTab(i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (label, filter) in const [
                      ('Tümü', ProfileMediaFilter.all),
                      ('Filmler', ProfileMediaFilter.movie),
                      ('Diziler', ProfileMediaFilter.show),
                    ])
                      _chip(
                        label,
                        selected: controller.selectedFilter.value == filter,
                        small: true,
                        onTap: () => controller.changeFilter(filter),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
      if (controller.isLoading.value && entries.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      else if (entries.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Burada henüz bir şey yok.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => LibraryPosterCard(
                entry: entries[index],
                showMarkWatched: tab != 0,
                onMarkWatched: () => controller.markWatched(entries[index]),
                onRemove: () => controller.remove(entries[index]),
              ),
              childCount: entries.length,
            ),
          ),
        ),
      if (controller.isLoadingMore(tab))
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ],
  );
}

Widget _chip(
  String label, {
  required bool selected,
  required VoidCallback onTap,
  bool small = false,
}) => Padding(
  padding: const EdgeInsets.only(right: AppSpacing.xs),
  child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: selected
            ? (small ? AppColors.surfaceVariant : AppColors.primaryContainer)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: selected && !small
              ? AppColors.primaryContainer
              : AppColors.outline,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            fontSize: small ? 11 : 12,
            color: selected
                ? (small ? AppColors.onSurface : Colors.white)
                : AppColors.secondary,
          ),
        ),
      ),
    ),
  ),
);
