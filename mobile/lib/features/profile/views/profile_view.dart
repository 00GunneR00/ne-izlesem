import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/profile_controller.dart';
import '../widgets/library_poster_card.dart';
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
                    children: [_grid(0), _grid(1), _grid(2)],
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
      final isLoadingMore = controller.isLoadingMore(tab);
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
                    child: LibraryPosterCard(
                      entry: entries[index],
                      showMarkWatched: tab != 0,
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
                      const SizedBox(width: AppSpacing.lg),
                      _stat(controller.watchingCount, 'İzliyor'),
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
                Expanded(child: _mainTabButton('İzliyorum', 2)),
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

