import 'package:get/get.dart';
import '../../discover/controllers/discover_controller.dart';
import '../../swipe/controllers/swipe_controller.dart';
import '../../takip/controllers/takip_controller.dart';

class RootController extends GetxController {
  // Tab order: Swipe · Keşfet · Takip · Arama · Sosyal.
  static const swipeTab = 0;
  static const discoverTab = 1;
  static const takipTab = 2;

  final RxInt tabIndex = 0.obs;

  void changeTab(int index) {
    // Tapping the tab you're already on starts a fresh feed / deck.
    if (index == tabIndex.value) {
      if (index == discoverTab) Get.find<DiscoverController>().refreshFeed();
      if (index == swipeTab) Get.find<SwipeController>().reload();
      return;
    }
    tabIndex.value = index;
    // Takip stays mounted in the IndexedStack; refresh it on every visit so
    // progress logged elsewhere (detail page, Listem) shows up.
    if (index == takipTab) Get.find<TakipController>().reload();
  }
}
