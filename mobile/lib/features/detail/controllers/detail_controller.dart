import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/cast_member_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/models/library_entry_model.dart';
import '../../../data/models/season_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/trailer_model.dart';
import '../../../data/services/comments_service.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/titles_service.dart';

class DetailController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final LibraryService _libraryService = LibraryService();
  final CommentsService _commentsService = CommentsService();
  final SessionService _session = Get.find();

  late final TitleModel title;
  final RxList<TrailerModel> trailers = <TrailerModel>[].obs;
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxList<CastMemberModel> cast = <CastMemberModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isPostingComment = false.obs;
  final Rxn<LibraryStatus> savedStatus = Rxn<LibraryStatus>();
  final Rxn<int> rating = Rxn<int>();
  final RxBool isRating = false.obs;

  // Shows only: seasons + "nerede kaldın" (last watched episode).
  final RxList<SeasonModel> seasons = <SeasonModel>[].obs;
  final Rxn<int> progressSeason = Rxn<int>();
  final Rxn<int> progressEpisode = Rxn<int>();
  final RxBool isSavingProgress = false.obs;
  int? _entryId;

  /// Status before the last change on this screen, so undoing "İzledim" on
  /// something that was in "İzleyeceğim" puts it back there instead of
  /// dropping it from the library.
  LibraryStatus? _previousStatus;

  @override
  void onInit() {
    super.onInit();
    title = Get.arguments as TitleModel;
    _loadLibraryEntry();
    _loadTrailers();
    _loadGenres();
    _loadComments();
    _loadCast();
    if (title.mediaType == MediaType.show) _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    try {
      seasons.value = await _titlesService.getSeasons(title.tmdbId);
    } catch (_) {
      // No tracking card without season data; the rest of the page is fine.
    }
  }

  Future<void> _loadCast() async {
    cast.value = await _titlesService.getCast(title.mediaType, title.tmdbId);
  }

  Future<void> _loadComments() async {
    comments.value = await _commentsService.getForTitle(
      title.tmdbId,
      title.mediaType,
    );
  }

  int? get currentUserId => _session.userId.value;

  /// Returns true once saved, so the input is only cleared on success.
  Future<bool> postComment(String text, {bool isSpoiler = false}) async {
    final userId = _session.userId.value;
    final trimmed = text.trim();
    if (userId == null || trimmed.isEmpty || isPostingComment.value) {
      return false;
    }
    isPostingComment.value = true;
    try {
      final comment = await _commentsService.add(
        userId: userId,
        tmdbId: title.tmdbId,
        mediaType: title.mediaType,
        text: trimmed,
        isSpoiler: isSpoiler,
      );
      comments.insert(0, comment);
      return true;
    } catch (_) {
      Get.snackbar('Olmadı', 'Yorumun gönderilemedi, tekrar dene.');
      return false;
    } finally {
      isPostingComment.value = false;
    }
  }

  Future<bool> editComment(
    CommentModel comment,
    String text, {
    required bool isSpoiler,
  }) async {
    final userId = _session.userId.value;
    final trimmed = text.trim();
    if (userId == null || trimmed.isEmpty) return false;
    try {
      final updated = await _commentsService.update(
        comment.id,
        userId: userId,
        text: trimmed,
        isSpoiler: isSpoiler,
      );
      final index = comments.indexWhere((c) => c.id == comment.id);
      if (index >= 0) comments[index] = updated;
      return true;
    } catch (_) {
      Get.snackbar('Olmadı', 'Yorum güncellenemedi, tekrar dene.');
      return false;
    }
  }

  Future<void> deleteComment(CommentModel comment) async {
    final userId = _session.userId.value;
    if (userId == null) return;
    try {
      await _commentsService.delete(comment.id, userId);
      comments.removeWhere((c) => c.id == comment.id);
    } catch (_) {
      Get.snackbar('Olmadı', 'Yorum silinemedi, tekrar dene.');
    }
  }

  Future<void> _loadTrailers() async {
    isLoading.value = true;
    try {
      trailers.value = await _titlesService.getTrailers(
        title.mediaType,
        title.tmdbId,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadGenres() async {
    genres.value = await _titlesService.getGenres(title.mediaType);
  }

  String? genreName(int id) {
    for (final g in genres) {
      if (g.id == id) return g.name;
    }
    return null;
  }

  Future<void> _loadLibraryEntry() async {
    final userId = _session.userId.value;
    if (userId == null) return;
    try {
      final entry = await _libraryService.getEntry(
        userId: userId,
        tmdbId: title.tmdbId,
        mediaType: title.mediaType,
      );
      // Don't clobber a tap that landed before the lookup finished.
      if (isSaving.value) return;
      _entryId = entry?.id;
      savedStatus.value = entry?.status;
      rating.value = entry?.rating;
      _applyProgress(entry);
    } catch (_) {
      // Buttons just start unselected; saving still works.
    }
  }

  /// Tapping a status sets it; tapping the already-active one undoes it.
  Future<void> saveToLibrary(LibraryStatus status) async {
    final userId = _session.userId.value;
    if (userId == null || isSaving.value) return;
    isSaving.value = true;
    try {
      if (savedStatus.value == status && _entryId != null) {
        final restore = _previousStatus;
        if (restore != null && restore != status) {
          final entry = await _libraryService.updateStatus(_entryId!, restore);
          savedStatus.value = restore;
          rating.value = entry.rating;
          _applyProgress(entry);
        } else {
          await _libraryService.remove(_entryId!);
          _entryId = null;
          savedStatus.value = null;
          rating.value = null;
          _applyProgress(null);
        }
        _previousStatus = null;
        return;
      }

      final entry = await _libraryService.add(
        userId: userId,
        tmdbId: title.tmdbId,
        mediaType: title.mediaType,
        status: status,
      );
      _previousStatus = savedStatus.value;
      _entryId = entry.id;
      savedStatus.value = status;
      // The backend drops the rating when an entry leaves "İzledim".
      rating.value = entry.rating;
      _applyProgress(entry);
    } catch (_) {
      Get.snackbar('Olmadı', 'Kütüphane güncellenemedi, tekrar dene.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Stars only show once watched; tapping the current value clears it.
  Future<void> setRating(int? value) async {
    final userId = _session.userId.value;
    final entryId = _entryId;
    if (userId == null || entryId == null || isRating.value) return;
    final before = rating.value;
    rating.value = value; // optimistic — stars respond instantly
    isRating.value = true;
    try {
      await _libraryService.setRating(entryId, userId, value);
    } catch (_) {
      rating.value = before;
      Get.snackbar('Olmadı', 'Puanın kaydedilemedi, tekrar dene.');
    } finally {
      isRating.value = false;
    }
  }

  void _applyProgress(LibraryEntryModel? entry) {
    progressSeason.value = entry?.currentSeason;
    progressEpisode.value = entry?.currentEpisode;
  }

  int _episodeCount(int season) {
    for (final s in seasons) {
      if (s.seasonNumber == season) return s.episodeCount;
    }
    return 0;
  }

  /// The episode "Sonraki bölümü izledim" would log, or null when the last
  /// aired episode is already logged.
  ({int season, int episode})? get nextEpisode {
    if (seasons.isEmpty) return null;
    final season = progressSeason.value;
    final episode = progressEpisode.value ?? 0;
    if (season == null) {
      return (season: seasons.first.seasonNumber, episode: 1);
    }
    if (episode < _episodeCount(season)) {
      return (season: season, episode: episode + 1);
    }
    for (final s in seasons) {
      if (s.seasonNumber > season) return (season: s.seasonNumber, episode: 1);
    }
    return null;
  }

  /// Share of aired episodes watched so far, for the progress bar.
  double get overallProgress {
    final season = progressSeason.value;
    if (season == null || seasons.isEmpty) return 0;
    var total = 0;
    var done = 0;
    for (final s in seasons) {
      total += s.episodeCount;
      if (s.seasonNumber < season) done += s.episodeCount;
      if (s.seasonNumber == season) done += progressEpisode.value ?? 0;
    }
    return total == 0 ? 0 : (done / total).clamp(0, 1);
  }

  Future<void> watchNextEpisode() async {
    final next = nextEpisode;
    if (next != null) await setProgress(next.season, next.episode);
  }

  /// Steps back one episode (to the previous season's last one at E0).
  Future<void> undoEpisode() async {
    final season = progressSeason.value;
    final episode = progressEpisode.value ?? 0;
    if (season == null) return;
    if (episode > 0) return setProgress(season, episode - 1);
    SeasonModel? previous;
    for (final s in seasons) {
      if (s.seasonNumber < season) previous = s;
    }
    if (previous != null) {
      await setProgress(previous.seasonNumber, previous.episodeCount);
    }
  }

  /// Jump to the start of a season (nothing of it watched yet).
  Future<void> selectSeason(int season) => setProgress(season, 0);

  Future<void> setProgress(int season, int episode) async {
    final userId = _session.userId.value;
    if (userId == null || isSavingProgress.value) return;
    isSavingProgress.value = true;
    try {
      var entryId = _entryId;
      if (entryId == null) {
        final entry = await _libraryService.add(
          userId: userId,
          tmdbId: title.tmdbId,
          mediaType: title.mediaType,
          status: LibraryStatus.watching,
        );
        entryId = entry.id;
        _entryId = entryId;
        _previousStatus = null;
      }
      final entry = await _libraryService.setProgress(
        entryId,
        userId,
        season: season,
        episode: episode,
      );
      if (savedStatus.value != entry.status) _previousStatus = savedStatus.value;
      savedStatus.value = entry.status;
      _applyProgress(entry);
    } catch (_) {
      Get.snackbar('Olmadı', 'İlerlemen kaydedilemedi, tekrar dene.');
      return;
    } finally {
      isSavingProgress.value = false;
    }

    // Logged the very last aired episode — offer to call it watched.
    if (nextEpisode == null && savedStatus.value != LibraryStatus.watched) {
      Get.snackbar(
        'Diziyi bitirdin! 🎉',
        'İzledim olarak işaretlemek ister misin?',
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            saveToLibrary(LibraryStatus.watched);
          },
          child: const Text('İşaretle'),
        ),
      );
    }
  }
}
