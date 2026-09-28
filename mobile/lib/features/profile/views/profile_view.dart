import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/library_entry_model.dart';
import '../controllers/profile_controller.dart';
import '../widgets/staggered_fade_in.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileController controller = Get.find<ProfileController>();
  late final PageController _pageController = PageController(
    initialPage: controller.mainTab.value,
  );

  @override
  void initState() {
    super.initState();
    // Not a bottom-nav tab anymore (opened from the hamburger drawer), so
    // there's no IndexedStack keeping it alive — refresh explicitly on
    // every open instead of relying on onInit having run once.
    controller.refreshAll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kütüphanem')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Column(
            children: [
              _header(),
              _tabsAndFilters(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PageView(
                    controller: _pageController,
                    onPageChanged: controller.changeMainTab,
                    children: [_grid(0), _grid(1)],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(int tab) {
    return Obx(() {
      final entries = controller.entriesFor(tab);
      final isLoadingMore = tab == 0
          ? controller.isLoadingMoreWatched.value
          : controller.isLoadingMoreToWatch.value;
      if (entries.isEmpty) {
        return isLoadingMore
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Text(
                  'Burada henüz bir şey yok.',
                  style: AppTextStyles.bodyMd,
                ),
              );
      }
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Fetch the next page a bit before the user actually hits the
          // bottom, so the grid doesn't stall while it loads.
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 400) {
            controller.loadMore(tab);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StaggeredFadeIn(
                    index: index,
                    child: _PosterCard(
                      entry: entries[index],
                      showMarkWatched: tab == 1,
                      onMarkWatched: () =>
                          controller.markWatched(entries[index]),
                      onRemove: () => controller.remove(entries[index]),
                    ),
                  ),
                  childCount: entries.length,
                ),
              ),
            ),
            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      );
    });
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.outline),
              ),
            ),
            child: Obx(() {
              final name = controller.displayName.value;
              final initial = (name != null && name.isNotEmpty)
                  ? name[0].toUpperCase()
                  : '?';
              return Center(
                child: Text(initial, style: AppTextStyles.headlineLg),
              );
            }),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    controller.displayName.value ?? 'Kullanıcı',
                    style: AppTextStyles.headlineLgMobile,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Obx(
                  () => Row(
                    children: [
                      _stat(controller.watchedCount, 'İzlenen'),
                      const SizedBox(width: AppSpacing.lg),
                      _stat(controller.toWatchCount, 'Listede'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(int value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$value',
        style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
      ),
      Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary),
      ),
    ],
  );

  Widget _tabsAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                Expanded(child: _mainTabButton('İzlediklerim', 0)),
                Expanded(child: _mainTabButton('İzleyeceklerim', 1)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 32,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('Tümü', ProfileMediaFilter.all),
                  _filterChip('Filmler', ProfileMediaFilter.movie),
                  _filterChip('Diziler', ProfileMediaFilter.show),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _mainTabButton(String label, int index) {
    final selected = controller.mainTab.value == index;
    return InkWell(
      onTap: () => _selectTab(index),
      child: Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primaryContainer : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: selected ? AppColors.primary : AppColors.secondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, ProfileMediaFilter filter) {
    final selected = controller.selectedFilter.value == filter;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: GestureDetector(
        onTap: () => controller.changeFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.outline),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? AppColors.onSurface : AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final LibraryEntryModel entry;
  final bool showMarkWatched;
  final VoidCallback onMarkWatched;
  final VoidCallback onRemove;

  const _PosterCard({
    required this.entry,
    required this.showMarkWatched,
    required this.onMarkWatched,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry.title;
    final year = title.releaseDate != null && title.releaseDate!.length >= 4
        ? title.releaseDate!.substring(0, 4)
        : null;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.detail, arguments: title),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'title-${title.tmdbId}-${title.mediaType.name}',
                  child: title.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: title.posterUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.surfaceContainer),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xs,
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            title.voteAverage.toStringAsFixed(1),
                            style: AppTextStyles.labelSm,
                          ),
                        ],
                      ),
                      Text(
                        title.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd,
                      ),
                      if (year != null)
                        Text(
                          year,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    children: [
                      if (showMarkWatched)
                        _iconButton(Icons.check_circle_outline, onMarkWatched),
                      _iconButton(Icons.delete_outline, onRemove),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    ),
  );
}
