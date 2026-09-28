import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the local device's user id once onboarding creates it. No real auth in MVP.
class SessionService extends GetxService {
  static const _userIdKey = 'user_id';

  final Rxn<int> userId = Rxn<int>();

  bool get hasUser => userId.value != null;

  Future<SessionService> init() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getInt(_userIdKey);
    return this;
  }

  Future<void> setUserId(int id) async {
    userId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
  }

  Future<void> logout() async {
    userId.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
