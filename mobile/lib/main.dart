import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/likes/likes_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/session/session_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await SessionService().init();
  Get.put(session, permanent: true);
  Get.put(LikesController(), permanent: true);
  runApp(const NeizlesemApp());
}

class NeizlesemApp extends StatelessWidget {
  const NeizlesemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ne İzlesem?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
