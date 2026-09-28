import 'dart:math';
import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/swipe_service.dart';
import '../../../data/services/titles_service.dart';
import '../../../data/services/user_service.dart';

class SwipeController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final SwipeService _swipeService = SwipeService();
  final UserService _userService = UserService();
  final LibraryService _libraryService = LibraryService();
  final SessionService _session = Get.find();
  final Random _random = Random();

  final Rx<MediaType> mediaType = MediaType.movie.obs;
  final RxList<TitleModel> queue = <TitleModel>[].obs;
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxBool isLoading = true.obs;

  static const _maxStartPage = 20;
  int _page = 1;
  int? _preferredGenreId;
  int _loadToken = 0;
  bool _isFetchingMore = false;
  final Set<String> _seenKeys = {};

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = _session.userId.value;
    if (userId != null) {
      final user = await _userService.getById(userId);
      if (user.preferredGenreIds.isNotEmpty) {
        _preferredGenreId = user.preferredGenreIds.first;
      }
    }
    // Start from a random page each time so the queue isn't identical
    // (same order, same titles) on every app open.
    _page = 1 + _random.nextInt(_maxStartPage);
    await Future.wait([_loadGenres(), _loadMore()]);
  }

  Future<void> _loadGenres() async {
    genres.value = await _titlesService.getGenres(mediaType.value);
  }

  String? genreName(int id) {
    for (final g in genres) {
      if (g.id == id) return g.name;
    }
    return null;
  }

  Future<void> bookmark(TitleModel title) async {
    final userId = _session.userId.value;
    if (userId == null) return;
    await _libraryService.add(
      userId: userId,
      tmdbId: title.tmdbId,
      mediaType: title.mediaType,
      status: LibraryStatus.toWatch,
    );
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore) {
      // A fetch is already in flight. Swiping fast fires this repeatedly
      // (each swipe re-checks queue.length < 3) before the first request
      // lands — without this guard each re-request fetches the *same* page
      // (since _page only advances once the await completes), so the same
      // handful of titles would get appended into the queue repeatedly,
      // which is what eventually surfaced as "the same movies again".
      return;
    }
    final token = _loadToken;
    _isFetchingMore = true;
    isLoading.value = true;
    try {
      // Preferred genre ids come from onboarding, which only offers movie
      // genres — TMDB uses a different id space for TV genres, so the filter
      // only makes sense while browsing movies.
      final genreId = mediaType.value == MediaType.movie
          ? _preferredGenreId
          : null;
      // A single page can come back with nothing new (every title already
      // seen) or fail outright — neither means we're actually out of
      // content, so keep trying subsequent pages within this same call
      // instead of leaving the queue stuck with nothing left to swipe.
      for (var attempt = 0; attempt < 6; attempt++) {
        if (token != _loadToken) return; // superseded by a reset meanwhile
        try {
          final results = await _titlesService.discover(
            mediaType.value,
            genreId: genreId,
            page: _page,
          );
          _page++;
          if (token != _loadToken) return;

          final fresh = [
            for (final title in results)
              if (_seenKeys.add('${title.mediaType.name}-${title.tmdbId}'))
                title,
          ];
          if (fresh.isEmpty) continue;
          queue.addAll(fresh..shuffle(_random));
          return;
        } catch (_) {
          _page++; // skip whatever page just failed and try the next one
        }
      }
    } finally {
      _isFetchingMore = false;
      isLoading.value = false;
    }
  }

  void switchMediaType(MediaType type) {
    if (mediaType.value == type) return;
    mediaType.value = type;
    _page = 1 + _random.nextInt(_maxStartPage);
    queue.clear();
    _seenKeys.clear();
    _loadToken++;
    _loadGenres();
    _loadMore();
  }

  TitleModel? get current => queue.isEmpty ? null : queue.first;

  Future<void> _consumeTop(SwipeDirection direction) async {
    final top = current;
    if (top == null) return;
    queue.removeAt(0);
    final userId = _session.userId.value;
    if (userId != null) {
      _swipeService.record(
        userId: userId,
        tmdbId: top.tmdbId,
        mediaType: top.mediaType,
        direction: direction,
      );
      // Right swipe (like) = already watched. Left swipe (pass) = not
      // interested — just consumes the card, no library entry.
      if (direction == SwipeDirection.like) {
        _libraryService.add(
          userId: userId,
          tmdbId: top.tmdbId,
          mediaType: top.mediaType,
          status: LibraryStatus.watched,
        );
      }
    }
    if (queue.length < 3) {
      _loadMore();
    }
  }

  void like() => _consumeTop(SwipeDirection.like);
  void pass() => _consumeTop(SwipeDirection.pass);
}
