import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Result of a successful sign-up / sign-in.
typedef AuthResult = ({String token, UserModel user});

/// Backend auth error with a machine-readable [code] (e.g. `password_not_set`,
/// `invalid_credentials`, `email_taken`) and a Turkish [message] to show.
class AuthFailure implements Exception {
  AuthFailure(this.code, this.message);

  final String code;
  final String message;

  /// Maps a Dio error from the auth endpoints to a readable failure.
  factory AuthFailure.from(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['code'] is String) {
        return AuthFailure(data['code'] as String, (data['message'] as String?) ?? 'Bir sorun oluştu.');
      }
      if (error.response?.statusCode == 429) {
        return AuthFailure('rate_limited', 'Çok fazla deneme yaptın. Bir dakika sonra tekrar dene.');
      }
      if (error.response == null) {
        return AuthFailure('network', 'Sunucuya ulaşılamadı. İnternet bağlantını kontrol et.');
      }
    }
    return AuthFailure('unknown', 'Bir sorun oluştu, tekrar dene.');
  }

  @override
  String toString() => message;
}

class AuthService {
  final _dio = ApiClient.instance.dio;

  AuthResult _parse(Response response) => (
        token: response.data['token'] as String,
        user: UserModel.fromJson(response.data['user'] as Map<String, dynamic>),
      );

  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    try {
      return _parse(await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'username': username,
      }));
    } catch (e) {
      throw AuthFailure.from(e);
    }
  }

  /// Throws [AuthFailure] with code `password_not_set` for accounts made
  /// before passwords existed — follow up with [setInitialPassword].
  Future<AuthResult> login(String email, String password) async {
    try {
      return _parse(await _dio.post('/auth/login', data: {'email': email, 'password': password}));
    } catch (e) {
      throw AuthFailure.from(e);
    }
  }

  Future<AuthResult> setInitialPassword(String email, String password) async {
    try {
      return _parse(await _dio.post('/auth/set-password', data: {'email': email, 'password': password}));
    } catch (e) {
      throw AuthFailure.from(e);
    }
  }

  /// Permanently deletes the signed-in account (password re-entry).
  Future<void> deleteAccount(String password) async {
    try {
      await _dio.delete('/auth/account', data: {'password': password});
    } catch (e) {
      throw AuthFailure.from(e);
    }
  }
}
