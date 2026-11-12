import 'package:employee/services/auth_service.dart';

class FakeAuthService implements AuthService {
  AuthAccount? account;
  Object? failure;
  String? lastEmail, lastPhone, lastCode;
  int loginCalls = 0, registrationCalls = 0, googleCalls = 0;
  bool automaticPhone = false;

  void _check() {
    if (failure != null) throw failure!;
  }

  @override
  AuthAccount? get currentAccount => account;

  @override
  Future<AuthAccount> signIn(String email, String password) async {
    loginCalls++;
    lastEmail = email;
    _check();
    return account = AuthAccount(uid: 'test-user', email: email);
  }

  @override
  Future<AuthAccount> register(
    String name,
    String email,
    String password,
  ) async {
    registrationCalls++;
    _check();
    return account = AuthAccount(uid: 'test-user', name: name, email: email);
  }

  @override
  Future<AuthAccount> google() async {
    googleCalls++;
    _check();
    return account = const AuthAccount(
      uid: 'google-user',
      name: 'Asha Rao',
      email: 'asha@example.com',
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    lastEmail = email;
    _check();
  }

  @override
  Future<void> signOut() async {
    _check();
    account = null;
  }

  @override
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(PhoneChallenge) onCodeSent,
    required void Function(AuthAccount) onVerified,
    required void Function(Object) onError,
  }) async {
    lastPhone = phone;
    if (failure != null) {
      onError(failure!);
      return;
    }
    final result = AuthAccount(uid: 'phone-user', phone: phone);
    if (automaticPhone) {
      account = result;
      onVerified(result);
      return;
    }
    onCodeSent(
      PhoneChallenge((code) async {
        lastCode = code;
        _check();
        return account = result;
      }),
    );
  }
}
