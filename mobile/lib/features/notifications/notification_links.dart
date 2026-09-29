import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/title_model.dart';
import '../friends/views/friends_view.dart';
import '../groups/views/group_detail_view.dart';
import '../root/controllers/root_controller.dart';
import '../social/controllers/social_controller.dart';
import '../takip/controllers/takip_controller.dart';

// Where tapping a notification takes you.

/// A group's page on a given tab (0 = Eşleşmeler, 1 = Grubun Önerileri).
/// Falls back to [fallbackTitle]'s detail if the group is gone.
Future<void> openGroup(
  int groupId, {
  int tab = 0,
  TitleModel? fallbackTitle,
}) async {
  final social = Get.find<SocialController>();
  var group = social.groups.firstWhereOrNull((g) => g.id == groupId);
  if (group == null) {
    await social.reload(); // just joined / list is stale
    group = social.groups.firstWhereOrNull((g) => g.id == groupId);
  }
  if (group != null) {
    Get.to(() => GroupDetailView(group: group!, initialTab: tab));
  } else if (fallbackTitle != null) {
    openTitle(fallbackTitle);
  } else {
    Get.snackbar('Bulunamadı', 'Bu grup artık yok.');
  }
}

void openTitle(TitleModel title) =>
    Get.toNamed(AppRoutes.detail, arguments: title);

/// The Takip tab on the plan's Tek Başına / Grupla / Arkadaşlarla tab.
void openPlan(PlanModel plan) {
  Get.until((route) => route.isFirst); // back to the bottom-nav root
  Get.find<TakipController>().selectKind(plan.kind);
  Get.find<RootController>().changeTab(RootController.takipTab);
}

void openFriends() => Get.to(() => const FriendsView());

/// A suggestion (inbox or response): a group one opens that group's
/// "Grubun Önerileri"; a direct one opens the title.
void openSuggestion(TitleModel title, {int? groupId}) => groupId != null
    ? openGroup(groupId, tab: 1, fallbackTitle: title)
    : openTitle(title);
