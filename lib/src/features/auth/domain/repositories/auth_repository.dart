class AuthResult {
  const AuthResult({required this.token, required this.completedProfile});

  final String token;
  final bool completedProfile;
}

abstract interface class AuthRepository {
  Future<void> requestOtp(String email);
  Future<AuthResult> verifyOtp(String email, String code);
}
