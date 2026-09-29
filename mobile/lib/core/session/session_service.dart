import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user: their id and the API token (JWT), kept in the
/// platform's secure storage (Android Keystore / iOS Keychain). Every API
/// call sends the token; the backend takes the user's identity from it.
class SessionService extends GetxService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Rxn<int> userId = Rxn<int>();
  String? _token;

  String? get token => _token;
  bool get hasUser => userId.value != null && _token != null;

  Future<SessionService> init() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      userId.value = int.tryParse(await _storage.read(key: _userIdKey) ?? '');
    } catch (_) {
      // Unreadable storage (e.g. restored backup on a new device) → sign in again.
      await _storage.deleteAll();
    }
    if (_token == null) userId.value = null;

    // Sessions from before passwords existed only stored a user id in plain
    // prefs — they have no token, so those users sign in once more.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    return this;
  }

  Future<void> signIn({required String token, required int userId}) async {
    _token = token;
    this.userId.value = userId;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: '$userId');
  }

  Future<void> logout() async {
    _token = null;
    userId.value = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }
}
