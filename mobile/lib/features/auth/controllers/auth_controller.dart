import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/user_service.dart';

class AuthController extends GetxController {
  final UserService _userService = UserService();
  final SessionService _session = Get.find();

  final RxBool isSubmitting = false.obs;

  /// Social login (Google/Apple) isn't supported.
  void notifyLoginNotReady() {
    Get.snackbar(
      'Yakında',
      'Bu giriş yöntemi henüz eklenmedi.',
      backgroundColor: AppColors.surfaceContainerHigh,
      colorText: AppColors.onSurface,
    );
  }

  /// Backend has no password field yet, so this looks the account up by
  /// email only — real password verification is still a separate, later
  /// piece of work.
  Future<void> login({required String email}) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final user = await _userService.getByEmail(email);
      await _session.setUserId(user.id);
      if (user.preferredGenreIds.isEmpty) {
        Get.offAllNamed(AppRoutes.onboarding);
      } else {
        Get.offAllNamed(AppRoutes.root);
      }
    } on DioException catch (e) {
      final message = e.response?.statusCode == 404
          ? 'Bu e-posta ile bir hesap bulunamadı.'
          : 'Giriş sırasında bir sorun oluştu, tekrar dene.';
      Get.snackbar('Giriş yapılamadı', message,
          backgroundColor: AppColors.surfaceContainerHigh, colorText: AppColors.onSurface);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> register({required String name, required String email, required String username}) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final user = await _userService.createOrGet(email, name, username);
      await _session.setUserId(user.id);
      if (user.preferredGenreIds.isEmpty) {
        Get.offAllNamed(AppRoutes.onboarding);
      } else {
        Get.offAllNamed(AppRoutes.root);
      }
    } on DioException catch (e) {
      final message = e.response?.statusCode == 409
          ? 'Bu kullanıcı adı zaten alınmış, başka bir tane dene.'
          : 'Kayıt sırasında bir sorun oluştu, tekrar dene.';
      Get.snackbar('Kayıt olunamadı', message,
          backgroundColor: AppColors.surfaceContainerHigh, colorText: AppColors.onSurface);
    } finally {
      isSubmitting.value = false;
    }
  }
}
