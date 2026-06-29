abstract interface class AuthRepository {
  Future<void> requestOtp(String email);
  Future<bool> verifyOtp(String email, String code);
}
