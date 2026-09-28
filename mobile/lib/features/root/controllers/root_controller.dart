import 'package:get/get.dart';
import '../../takip/controllers/takip_controller.dart';

class RootController extends GetxController {
  // Tab order: Swipe · Keşfet · Takip · Arama · Sosyal.
  static const takipTab = 2;

  final RxInt tabIndex = 0.obs;

  void changeTab(int index) {
    tabIndex.value = index;
    // Takip stays mounted in the IndexedStack; refresh it on every visit so
    // progress logged elsewhere (detail page, Listem) shows up.
    if (index == takipTab) Get.find<TakipController>().reload();
  }
}
