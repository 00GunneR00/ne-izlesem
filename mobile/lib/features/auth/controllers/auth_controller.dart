import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

/// Giriş Yap / Kayıt Ol / (old accounts) Şifreni belirle.
enum AuthMode { login, register, setPassword }

class AuthController extends GetxController {
  final AuthService _auth = AuthService();
  final SessionService _session = Get.find();

  /// `/register` opens straight on Kayıt Ol.
  late final Rx<AuthMode> mode =
      (Get.arguments == AuthMode.register ? AuthMode.register : AuthMode.login)
          .obs;
  final RxBool isSubmitting = false.obs;

  /// Inline error under the form; cleared on edit / mode switch.
  final RxnString error = RxnString();

  /// Bumped on every failure — the form card shakes when it changes.
  final RxInt errorTick = 0.obs;

  void switchMode(AuthMode next) {
    if (mode.value == next) return;
    mode.value = next;
    error.value = null;
  }

  void clearError() => error.value = null;

  Future<void> login(String email, String password) => _submit(() async {
    try {
      return await _auth.login(email.trim(), password);
    } on AuthFailure catch (f) {
      if (f.code == 'password_not_set') {
        // Account from before passwords: pick one now to claim it.
        mode.value = AuthMode.setPassword;
        error.value = null;
        return null;
      }
      rethrow;
    }
  });

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) => _submit(
    () => _auth.register(
      email: email.trim(),
      password: password,
      displayName: name.trim(),
      username: username.trim(),
    ),
  );

  Future<void> setInitialPassword(String email, String password) =>
      _submit(() => _auth.setInitialPassword(email.trim(), password));

  Future<void> _submit(Future<AuthResult?> Function() call) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    error.value = null;
    try {
      final result = await call();
      if (result == null) return;
      await _session.signIn(token: result.token, userId: result.user.id);
      _goHome(result.user);
    } on AuthFailure catch (f) {
      error.value = f.message;
      errorTick.value++;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _goHome(UserModel user) => Get.offAllNamed(
    user.preferredGenreIds.isEmpty ? AppRoutes.onboarding : AppRoutes.root,
  );
}
