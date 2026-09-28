import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/groups_service.dart';
import '../../../data/services/titles_service.dart';
import 'group_detail_controller.dart';

/// "Birlikte Seç" — the group's shared swipe deck. Right swipe means "let's
/// watch this together"; when it's the last missing like, the backend
/// reports a match and [onMatch] fires.
class GroupSwipeController extends GetxController {
  GroupSwipeController(this.group, {required this.onMatch});

  final GroupModel group;
  final void Function(TitleModel title) onMatch;

  final GroupsService _groupsService = GroupsService();
  final TitlesService _titlesService = TitlesService();
  final SessionService _session = Get.find();

  final Rx<MediaType> mediaType = MediaType.movie.obs;
  final RxList<TitleModel> queue = <TitleModel>[].obs;
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxBool isLoading = true.obs;

  // Deliberately starts at page 1 (unlike the solo deck's random page):
  // every member walks the same list, which is what makes likes overlap.
  int _page = 1;
  int _loadToken = 0;
  bool _isFetchingMore = false;
  final Set<String> _seenKeys = {};

  @override
  void onInit() {
    super.onInit();
    _loadGenres();
    _loadMore();
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

  TitleModel? get current => queue.isEmpty ? null : queue.first;

  Future<void> _loadMore() async {
    final userId = _session.userId.value;
    if (_isFetchingMore || userId == null) return;
    final token = _loadToken;
    _isFetchingMore = true;
    isLoading.value = true;
    try {
      for (var attempt = 0; attempt < 6; attempt++) {
        if (token != _loadToken) return;
        try {
          final deck = await _groupsService.getDeck(
            groupId: group.id,
            userId: userId,
            mediaType: mediaType.value,
            page: _page,
          );
          _page = deck.nextPage;
          if (token != _loadToken) return;
          final fresh = [
            for (final title in deck.items)
              if (_seenKeys.add('${title.mediaType.name}-${title.tmdbId}'))
                title,
          ];
          if (fresh.isEmpty) continue;
          queue.addAll(fresh);
          return;
        } catch (_) {
          _page++;
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
    _page = 1;
    queue.clear();
    _seenKeys.clear();
    _loadToken++;
    _loadGenres();
    _loadMore();
  }

  Future<void> _consumeTop(SwipeDirection direction) async {
    final top = current;
    final userId = _session.userId.value;
    if (top == null || userId == null) return;
    queue.removeAt(0);
    if (queue.length < 3) _loadMore();

    try {
      final result = await _groupsService.swipe(
        groupId: group.id,
        userId: userId,
        title: top,
        direction: direction,
      );
      if (result.matched) {
        onMatch(result.title ?? top);
        final tag = 'group-${group.id}';
        if (Get.isRegistered<GroupDetailController>(tag: tag)) {
          Get.find<GroupDetailController>(tag: tag).reload();
        }
      }
    } catch (_) {
      Get.snackbar('Olmadı', 'Seçimin kaydedilemedi, tekrar dene.');
    }
  }

  void like() => _consumeTop(SwipeDirection.like);
  void pass() => _consumeTop(SwipeDirection.pass);
}
