import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/watch_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/person_model.dart';
import '../../../data/models/title_model.dart';
import '../../account/widgets/app_drawer.dart';
import '../../social/widgets/notification_bell.dart';
import '../controllers/search_controller.dart';
import '../widgets/title_poster_card.dart';
import 'person_filmography_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final AppSearchController controller = Get.find<AppSearchController>();
  final _searchTextController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchTextController.dispose();
    super.dispose();
  }

  void _onModeChanged(SearchMode mode) {
    _debounce?.cancel();
    _searchTextController.clear();
    controller.switchMode(mode);
  }

  /// Fires [search] as the user types, after a short pause — searching on
  /// every single keystroke would fire far more requests than needed.
  void _debouncedSearch(String text, ValueChanged<String> search) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => search(text));
  }

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: _modeSegments(),
            ),
            Expanded(
              child: Obx(() {
                switch (controller.mode.value) {
                  case SearchMode.title:
                    return _titleSearch();
                  case SearchMode.person:
                    return _personSearch();
                  case SearchMode.platform:
                    return _platformSearch();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSegments() => Obx(
    () => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(child: _modeButton('Film/Dizi Adı', SearchMode.title)),
          Expanded(child: _modeButton('Oyuncu', SearchMode.person)),
          Expanded(child: _modeButton('Platform', SearchMode.platform)),
        ],
      ),
    ),
  );

  Widget _modeButton(String label, SearchMode mode) {
    final selected = controller.mode.value == mode;
    return GestureDetector(
      onTap: () => _onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _searchBar({
    required String hint,
    required ValueChanged<String> onSubmitted,
    ValueChanged<String>? onChanged,
  }) => Container(
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      0,
    ),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _searchTextController,
            style: AppTextStyles.bodyMd,
            onSubmitted: (text) {
              _debounce?.cancel();
              onSubmitted(text);
            },
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.arrow_forward,
            color: AppColors.primary,
            size: 18,
          ),
          onPressed: () {
            _debounce?.cancel();
            onSubmitted(_searchTextController.text);
          },
        ),
      ],
    ),
  );

  Widget _mediaTypeToggle() => Padding(
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
  );

  Widget _resultsGrid(List<TitleModel> titles) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.xl,
    ),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.62,
    ),
    itemCount: titles.length,
    itemBuilder: (context, index) => TitlePosterCard(title: titles[index]),
  );

  Widget _emptyHint(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
    ),
  );

  Widget _titleSearch() {
    return Column(
      children: [
        Center(child: _mediaTypeToggle()),
        _searchBar(
          hint: 'Film ya da dizi adı ara...',
          onSubmitted: controller.searchTitles,
          onChanged: (text) => _debouncedSearch(text, controller.searchTitles),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (controller.titleResults.isEmpty) {
              return _emptyHint('Sonuç bulunamadı.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!controller.isSearchActive.value) _suggestionsLabel(),
                Expanded(child: _resultsGrid(controller.titleResults)),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _suggestionsLabel() {
    final because = controller.recommendedBecause;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Senin İçin Öneriler',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (because.isNotEmpty)
            Text(
              _becauseText(because),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 11,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  String _becauseText(List<String> names) {
    final shown = names.take(2).join(', ');
    final rest = names.length - 2;
    return 'Beğendiğin yapımlara göre: $shown${rest > 0 ? ' +$rest' : ''}';
  }

  Widget _personSearch() {
    return Column(
      children: [
        _searchBar(
          hint: 'Oyuncu adı ara...',
          onSubmitted: controller.searchPeople,
          onChanged: (text) => _debouncedSearch(text, controller.searchPeople),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (controller.personResults.isEmpty) {
              return _emptyHint('Sonuç bulunamadı.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!controller.isSearchActive.value) _suggestionsLabel(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    itemCount: controller.personResults.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) =>
                        _personTile(controller.personResults[index]),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _personTile(PersonModel person) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.outline),
    ),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => Get.to(() => PersonFilmographyView(person: person)),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceVariant,
        backgroundImage: person.profileUrl != null
            ? CachedNetworkImageProvider(person.profileUrl!)
            : null,
        child: person.profileUrl == null
            ? Text(
                person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(person.name, style: AppTextStyles.bodyMd),
      subtitle: person.knownForDepartment != null
          ? Text(
              person.knownForDepartment!,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _platformSearch() {
    return Column(
      children: [
        Center(child: _mediaTypeToggle()),
        SizedBox(
          height: 88,
          // kWatchProviders is a constant list, so nothing here needs the
          // whole ListView rebuilt reactively — only each circle's border
          // (which provider is selected) needs its own small Obx. Wrapping
          // the outer ListView in Obx instead reads no observable directly
          // (the only Rx access is deferred into itemBuilder), which GetX
          // flags as "improper use of GetX".
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: kWatchProviders.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final provider = kWatchProviders[index];
              return GestureDetector(
                onTap: () => controller.browseProvider(provider),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Obx(() {
                        final selected =
                            controller.selectedProvider.value?.id ==
                            provider.id;
                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryContainer
                                  : AppColors.outline,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: provider.logoUrl,
                            fit: BoxFit.cover,
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        provider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (controller.selectedProvider.value == null) {
              return _emptyHint('Üyeliğin olan bir platformu seç.');
            }
            if (controller.platformResults.isEmpty) {
              return _emptyHint('Bu platformda içerik bulunamadı.');
            }
            return _resultsGrid(controller.platformResults);
          }),
        ),
      ],
    );
  }
}
