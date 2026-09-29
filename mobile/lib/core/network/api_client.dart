import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../config.dart';
import '../routes/app_routes.dart';
import '../session/session_service.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Every call carries the signed-in user's token; the backend reads
          // who you are from it (never from ids in the request).
          final token = Get.isRegistered<SessionService>()
              ? Get.find<SessionService>().token
              : null;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Expired / revoked token (or deleted account) outside the auth
          // screens → back to sign-in instead of a broken app.
          final isAuthCall = error.requestOptions.path.startsWith('/auth/');
          if (error.response?.statusCode == 401 &&
              !isAuthCall &&
              Get.isRegistered<SessionService>() &&
              Get.find<SessionService>().hasUser) {
            await Get.find<SessionService>().logout();
            Get.offAllNamed(AppRoutes.login);
            Get.snackbar('Oturum sona erdi', 'Lütfen tekrar giriş yap.');
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}
