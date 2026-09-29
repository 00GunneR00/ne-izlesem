import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
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
