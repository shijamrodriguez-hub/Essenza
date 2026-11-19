import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String userIdKey = 'logged_user_id';
  static const String userRoleKey = 'logged_user_role';

  static Future<void> saveSession({
    required String userId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(userIdKey, userId);
    await prefs.setString(userRoleKey, role);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(userIdKey);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(userRoleKey);
  }

  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();

    return userId != null && userId.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(userIdKey);
    await prefs.remove(userRoleKey);
  }
}