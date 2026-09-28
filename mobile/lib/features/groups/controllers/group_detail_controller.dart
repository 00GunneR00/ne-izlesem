import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/suggestion_model.dart';
import '../../../data/services/groups_service.dart';

class GroupDetailController extends GetxController {
  GroupDetailController(this.groupId);

  final int groupId;
  final GroupsService _groupsService = GroupsService();
  final SessionService _session = Get.find();

  final RxList<GroupWatchlistItem> watchlist = <GroupWatchlistItem>[].obs;
  final RxBool isLoading = true.obs;

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
      watchlist.value = await _groupsService.getWatchlist(groupId, userId);
    } finally {
      isLoading.value = false;
    }
  }
}
