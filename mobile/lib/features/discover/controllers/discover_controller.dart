import 'dart:math';
import 'package:get/get.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/titles_service.dart';

class DiscoverController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final Random _random = Random();

  final Rx<MediaType> mediaType = MediaType.movie.obs;
  final Rxn<int> selectedGenreId = Rxn<int>();
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxList<TitleModel> feed = <TitleModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;

  static const _maxStartPage = 20;
  // Movies with no trailer are kept only this fraction of the time; shows
  // with no trailer are never kept (backend discover results for TV lean
  // more heavily on obscure/low-quality entries, so trailer presence is a
  // stronger relevance signal there than for movies).
  static const _movieNoTrailerKeepRate = 1 / 6;

  double _noTrailerKeepRateFor(MediaType type) =>
      type == MediaType.show ? 0 : _movieNoTrailerKeepRate;

  int _page = 1;
  int _loadToken = 0;
  bool _isFetchingMore = false;
  final Set<String> _seenKeys = {};

  @override
  void onInit() {
    super.onInit();
    _loadGenres();
    _loadFeed(reset: true);
  }

  Future<void> _loadGenres() async {
    genres.value = await _titlesService.getGenres(mediaType.value);
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (reset) {
      // Start from a random page each time so the feed isn't identical
      // (same order, same titles) on every app open.
      _page = _pickStartPage(mediaType.value);
      feed.clear();
      _seenKeys.clear();
      currentIndex.value = 0;
      _loadToken++;
    } else if (_isFetchingMore) {
      // A fetch is already in flight. Fast scrolling fires onPageChanged
      // for several consecutive indices before the first request lands —
      // without this guard each of those re-requests the *same* page
      // (since _page only advances once the await completes), so the same
      // handful of titles would get appended into the feed repeatedly.
      return;
    }
    final token = _loadToken;
    _isFetchingMore = true;
    isLoading.value = true;
    try {
      final type = mediaType.value;
      // A single page can come back with nothing new to show (every title
      // already seen, or all filtered out as trailer-less) or the request
      // can fail outright — neither means the feed is actually exhausted
      // (TMDB has thousands of titles), so keep trying subsequent pages
      // within this same call instead of just stopping. Without this, the
      // feed could silently stop growing while the user still had nowhere
      // left to swipe to.
      for (var attempt = 0; attempt < 6; attempt++) {
        if (token != _loadToken) return; // superseded by a reset meanwhile
        try {
          final results = await _titlesService.discover(
            type,
            genreId: selectedGenreId.value,
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

          final trailerStatus = await _titlesService.getTrailerStatus(
            type,
            fresh.map((t) => t.tmdbId).toList(),
          );
          if (token != _loadToken) return;

          final withTrailer = <TitleModel>[];
          final withoutTrailer = <TitleModel>[];
          for (final title in fresh) {
            (trailerStatus[title.tmdbId] ?? false
                    ? withTrailer
                    : withoutTrailer)
                .add(title);
          }
          withoutTrailer.shuffle(_random);
          final keptWithoutTrailer = withoutTrailer.take(
            (withoutTrailer.length * _noTrailerKeepRateFor(type)).ceil(),
          );

          final batch = [...withTrailer, ...keptWithoutTrailer]
            ..shuffle(_random);
          if (batch.isEmpty) continue;
          feed.addAll(batch);
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

  /// Results come back popularity-sorted, so a low page number means more
  /// popular titles. Movies pick a start page uniformly. Shows skew the pick
  /// toward low pages — very popular shows should surface more often — while
  /// still occasionally reaching deep into the range for real discovery, and
  /// still random enough that two opens don't land on the same page.
  int _pickStartPage(MediaType type) {
    if (type != MediaType.show) {
      return 1 + _random.nextInt(_maxStartPage);
    }
    final skewedToward0 = pow(_random.nextDouble(), 2.2).toDouble();
    return 1 + (skewedToward0 * (_maxStartPage - 1)).floor();
  }

  void switchMediaType(MediaType type) {
    if (mediaType.value == type) return;
    mediaType.value = type;
    selectedGenreId.value = null;
    _loadGenres();
    _loadFeed(reset: true);
  }

  void selectGenre(int? genreId) {
    selectedGenreId.value = genreId;
    _loadFeed(reset: true);
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    if (index >= feed.length - 3) {
      _loadFeed();
    }
  }

  String? genreName(int id) {
    for (final g in genres) {
      if (g.id == id) return g.name;
    }
    return null;
  }
}
