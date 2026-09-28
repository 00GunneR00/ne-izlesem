import 'package:get/get.dart';
import '../../discover/controllers/discover_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../social/controllers/social_controller.dart';
import '../../swipe/controllers/swipe_controller.dart';
import '../controllers/root_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RootController());
    Get.lazyPut(() => SwipeController());
    Get.lazyPut(() => DiscoverController());
    // Unlike the other root controllers, ProfileController has no
    // permanently-mounted consumer (Kütüphanem/Profil are pushed pages, not
    // an always-alive IndexedStack tab) — GetX's smart management disposes
    // it once no pushed page using it is on screen. fenix: true makes it
    // transparently re-created via this same factory on the next
    // Get.find(), instead of throwing "not found".
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => SocialController());
    Get.lazyPut(() => AppSearchController());
  }
}
