import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> requestOtp(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> verifyOtp(String email, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return code == '123456';
  }
}
