import 'package:get/get.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/auth_view.dart';
import '../../features/detail/bindings/detail_binding.dart';
import '../../features/detail/views/detail_view.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/root/bindings/root_binding.dart';
import '../../features/root/views/root_view.dart';
import '../../features/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(
      name: AppRoutes.login,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.root,
      page: () => const RootView(),
      binding: RootBinding(),
    ),
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailView(),
      binding: DetailBinding(),
    ),
  ];
}
