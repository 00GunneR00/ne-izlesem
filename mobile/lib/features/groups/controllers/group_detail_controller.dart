import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/suggestion_model.dart';
import '../../../data/services/groups_service.dart';

class GroupDetailController extends GetxController {
  GroupDetailController(this.groupId);

  final int groupId;
  final GroupsService _groupsService = GroupsService();
  final SessionService _session = Get.find();

  final RxList<GroupSuggestion> suggestions = <GroupSuggestion>[].obs;
  final RxList<GroupMatch> matches = <GroupMatch>[].obs;
  final RxBool isLoading = true.obs;

  /// 0 = Eşleşmeler, 1 = Grubun Önerileri (same segmented style as Sosyal).
  final RxInt selectedTab = 0.obs;

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

  /// Vote / un-vote a match, then re-rank the same way the backend does
  /// (most votes first, ties → newer match) so the grid reorders at once.
  Future<void> toggleVote(GroupMatch match) async {
    final userId = _session.userId.value;
    if (userId == null || !voting.add(match.id)) return;
    try {
      final updated = await _groupsService.toggleMatchVote(
        groupId,
        match.id,
        userId,
      );
      final list = [
        for (final m in matches) m.id == updated.id ? updated : m,
      ]..sort((a, b) {
          final byVotes = b.voteCount.compareTo(a.voteCount);
          return byVotes != 0 ? byVotes : b.matchedAt.compareTo(a.matchedAt);
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
