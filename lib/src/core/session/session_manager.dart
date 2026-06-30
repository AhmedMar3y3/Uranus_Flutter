import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _tokenKey = 'uranus_token';
  static const _completedProfileKey = 'uranus_completed_profile';
  static const _emailKey = 'uranus_email';

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

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_completedProfileKey);
    await prefs.remove(_emailKey);
  }
}
