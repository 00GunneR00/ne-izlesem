import 'package:get/get.dart';
import '../../data/models/enums.dart';
import '../../data/models/title_model.dart';
import '../../data/services/likes_service.dart';
import '../session/session_service.dart';

/// App-wide persisted "like" state, shared by Discover, Detail and Social
/// screens so a heart tapped in one place shows filled everywhere else too.
class LikesController extends GetxController {
  final LikesService _likesService = LikesService();
  final SessionService _session = Get.find();

  final RxSet<String> _likedKeys = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
    // Session id becomes available after registration completes (app boots
    // before that), so reload whenever it changes.
    ever(_session.userId, (_) => _load());
  }

  String _key(int tmdbId, MediaType mediaType) => '$tmdbId-${mediaType.name}';

  Future<void> _load() async {
    final userId = _session.userId.value;
    if (userId == null) return;
    final likes = await _likesService.getForUser(userId);
    _likedKeys.assignAll(likes.map((l) => _key(l.tmdbId, l.mediaType)));
  }

  bool isLiked(int tmdbId, MediaType mediaType) => _likedKeys.contains(_key(tmdbId, mediaType));

  Future<void> toggle(TitleModel title) async {
    final userId = _session.userId.value;
    if (userId == null) return;
    final key = _key(title.tmdbId, title.mediaType);
    // Optimistic update.
    final wasLiked = _likedKeys.contains(key);
    if (wasLiked) {
      _likedKeys.remove(key);
    } else {
      _likedKeys.add(key);
    }
    final liked = await _likesService.toggle(userId: userId, tmdbId: title.tmdbId, mediaType: title.mediaType);
    if (liked) {
      _likedKeys.add(key);
    } else {
      _likedKeys.remove(key);
    }
  }
}
