import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _tokenKey = 'uranus_token';
  static const _completedProfileKey = 'uranus_completed_profile';
  static const _emailKey = 'uranus_email';
  static const _userIdKey = 'uranus_user_id';
  static const _usernameKey = 'uranus_username';

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> get hasToken async => (await token)?.isNotEmpty ?? false;

  Future<bool> get completedProfile async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedProfileKey) ?? false;
  }

  Future<String?> get email async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> get usernameFromEmail async {
    final value = await email;
    return value?.split('@').first;
  }

  Future<String?> get userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> get username async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> saveSession({
    required String token,
    required bool completedProfile,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setBool(_completedProfileKey, completedProfile);
  }

  Future<void> markProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedProfileKey, true);
  }

  Future<void> saveUserIdentity({
    required String id,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (id.isNotEmpty) {
      await prefs.setString(_userIdKey, id);
    }
    if (username.isNotEmpty) {
      await prefs.setString(_usernameKey, username);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_completedProfileKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }
}
