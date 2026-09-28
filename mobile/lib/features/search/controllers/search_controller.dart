import 'dart:math';
import 'package:get/get.dart';
import '../../../core/constants/watch_providers.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/person_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/people_service.dart';
import '../../../data/services/titles_service.dart';

enum SearchMode { title, person, platform }

class AppSearchController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final PeopleService _peopleService = PeopleService();
  final Random _random = Random();

  final Rx<SearchMode> mode = SearchMode.title.obs;
  final Rx<MediaType> mediaType = MediaType.movie.obs;

  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  // False while showing random suggestions (empty query); true once the
  // user has actually typed something and these are real search results.
  final RxBool isSearchActive = false.obs;

  final RxList<TitleModel> titleResults = <TitleModel>[].obs;
  final RxList<PersonModel> personResults = <PersonModel>[].obs;
  final RxList<TitleModel> platformResults = <TitleModel>[].obs;
  final Rxn<WatchProvider> selectedProvider = Rxn<WatchProvider>();

  /// Seed titles behind the "Senin İçin" list; empty when it's genre-based.
  final RxList<String> recommendedBecause = <String>[].obs;
  final SessionService _session = Get.find();

  @override
  void onInit() {
    super.onInit();
    _loadTitleSuggestions();
    _loadPersonSuggestions();
  }

  void switchMode(SearchMode next) {
    if (mode.value == next) return;
    mode.value = next;
  }

  void switchMediaType(MediaType type) {
    if (mediaType.value == type) return;
    mediaType.value = type;
    if (mode.value == SearchMode.title) {
      query.value.trim().isEmpty
          ? _loadTitleSuggestions()
          : searchTitles(query.value);
    } else if (mode.value == SearchMode.platform &&
        selectedProvider.value != null) {
      browseProvider(selectedProvider.value!);
    }
  }

  Future<void> _loadTitleSuggestions() async {
    isSearchActive.value = false;
    isLoading.value = true;
    recommendedBecause.clear();
    try {
      final userId = _session.userId.value;
      if (userId != null) {
        try {
          final recs = await _titlesService.getRecommendations(
            userId,
            mediaType.value,
          );
          if (recs.items.isNotEmpty) {
            titleResults.value = recs.items;
            recommendedBecause.value = recs.basedOn;
            return;
          }
        } catch (_) {
          // Fall through to plain popular titles.
        }
      }
      final results = await _titlesService.discover(
        mediaType.value,
        page: 1 + _random.nextInt(15),
      );
      titleResults.value = results..shuffle(_random);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPersonSuggestions() async {
    isLoading.value = true;
    try {
      final results = await _peopleService.getPopular(
        page: 1 + _random.nextInt(5),
      );
      personResults.value = results..shuffle(_random);
    } finally {
      isLoading.value = false;
    }
  }

  /// Called both on submit and, debounced, on every keystroke — an empty
  /// query falls back to random suggestions instead of an empty list.
  Future<void> searchTitles(String text) async {
    query.value = text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await _loadTitleSuggestions();
      return;
    }
    isSearchActive.value = true;
    isLoading.value = true;
    try {
      titleResults.value = await _titlesService.search(
        mediaType.value,
        trimmed,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchPeople(String text) async {
    query.value = text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await _loadPersonSuggestions();
      return;
    }
    isSearchActive.value = true;
    isLoading.value = true;
    try {
      personResults.value = await _peopleService.search(trimmed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> browseProvider(WatchProvider provider) async {
    selectedProvider.value = provider;
    isLoading.value = true;
    try {
      platformResults.value = await _titlesService.discover(
        mediaType.value,
        providerId: provider.id,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
