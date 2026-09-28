import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/cast_member_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
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

  Future<void> postComment(String text) async {
    final userId = _session.userId.value;
    final trimmed = text.trim();
    if (userId == null || trimmed.isEmpty || isPostingComment.value) return;
    isPostingComment.value = true;
    try {
      final comment = await _commentsService.add(
        userId: userId,
        tmdbId: title.tmdbId,
        mediaType: title.mediaType,
        text: trimmed,
      );
      comments.insert(0, comment);
    } finally {
      isPostingComment.value = false;
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
        } else {
          await _libraryService.remove(_entryId!);
          _entryId = null;
          savedStatus.value = null;
          rating.value = null;
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
}
