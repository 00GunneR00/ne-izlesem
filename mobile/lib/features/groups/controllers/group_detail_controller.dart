import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/suggestion_model.dart';
import '../../../data/services/groups_service.dart';

class GroupDetailController extends GetxController {
  GroupDetailController(this.groupId, {int initialTab = 0})
    : selectedTab = initialTab.obs;

  final int groupId;
  final GroupsService _groupsService = GroupsService();
  final SessionService _session = Get.find();

  final RxList<GroupSuggestion> suggestions = <GroupSuggestion>[].obs;
  final RxList<GroupMatch> matches = <GroupMatch>[].obs;
  final RxBool isLoading = true.obs;

  /// 0 = Eşleşmeler, 1 = Grubun Önerileri (same segmented style as Sosyal).
  final RxInt selectedTab;

  void selectTab(int index) => selectedTab.value = index;

  /// Eşleşmeler filter: null = Tümü, else only films / only shows. Ranking
  /// (#1, #2…) is within the filtered list.
  final Rxn<MediaType> matchFilter = Rxn<MediaType>();

  void setMatchFilter(MediaType? type) => matchFilter.value = type;

  List<GroupMatch> get visibleMatches {
    final filter = matchFilter.value;
    return filter == null
        ? matches
        : matches.where((m) => m.title.mediaType == filter).toList();
  }

  /// Match ids with a vote request in flight.
  final RxSet<int> voting = <int>{}.obs;

  /// İzleyelim / Kararsız / İzlemeyelim (same choice again clears it), then
  /// re-rank the way the backend does — score, then İzleyelim count, then
  /// newer match — so the list reorders at once.
  Future<void> vote(GroupMatch match, MatchVote choice) async {
    final userId = _session.userId.value;
    if (userId == null || !voting.add(match.id)) return;
    try {
      final updated = await _groupsService.voteOnMatch(
        groupId,
        match.id,
        userId,
        choice,
      );
      final list = [for (final m in matches) m.id == updated.id ? updated : m]
        ..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          if (byScore != 0) return byScore;
          final byYes = b.yes.length.compareTo(a.yes.length);
          return byYes != 0 ? byYes : b.matchedAt.compareTo(a.matchedAt);
        });
      matches.value = list;
    } catch (_) {
      Get.snackbar('Olmadı', 'Oyun kaydedilemedi, tekrar dene.');
    } finally {
      voting.remove(match.id);
    }
  }

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final userId = _session.userId.value;
    if (userId == null) return;
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _groupsService.getSuggestions(groupId, userId),
        _groupsService.getMatches(groupId, userId),
      ]);
      suggestions.value = results[0] as List<GroupSuggestion>;
      matches.value = results[1] as List<GroupMatch>;
    } finally {
      isLoading.value = false;
    }
  }
}
