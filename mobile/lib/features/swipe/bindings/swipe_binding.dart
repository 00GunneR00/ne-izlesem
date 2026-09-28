import 'package:get/get.dart';
import '../controllers/swipe_controller.dart';

class SwipeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SwipeController());
  }
}
