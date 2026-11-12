import 'package:hr/auth_service.dart';

class FakeHrAuthService implements HrAuthService {
  HrAccount? account;
  Object? failure;
  String? lastEmail, lastPhone, lastCode;
  int loginCalls = 0, registerCalls = 0, phoneCalls = 0;
  bool automaticPhone = false;
  void _check() {
    if (failure != null) throw failure!;
  }

  @override
  HrAccount? get currentAccount => account;
  @override
  Future<HrAccount> signIn(String email, String password) async {
    loginCalls++;
    lastEmail = email;
    _check();
    return account = HrAccount(uid: 'hr-user', email: email);
  }

  @override
  Future<HrAccount> register(
    String companyName,
    String email,
    String password,
  ) async {
    registerCalls++;
    lastEmail = email;
    _check();
    return account = HrAccount(uid: 'hr-user', name: companyName, email: email);
  }

  @override
  Future<void> signOut() async {
    _check();
    account = null;
  }

  @override
  Future<void> resetPassword(String email) async {
    lastEmail = email;
    _check();
  }

  @override
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(HrPhoneChallenge) onCodeSent,
    required void Function(HrAccount) onVerified,
    required void Function(Object) onError,
  }) async {
    phoneCalls++;
    lastPhone = phone;
    if (failure != null) {
      onError(failure!);
      return;
    }
    final result = HrAccount(uid: 'hr-phone-user', phone: phone);
    if (automaticPhone) {
      account = result;
      onVerified(result);
      return;
    }
    onCodeSent(
      HrPhoneChallenge((code) async {
        lastCode = code;
        _check();
        return account = result;
      }),
    );
  }
}

FakeHrAuthService signedInAuth() => FakeHrAuthService()
  ..account = const HrAccount(
    uid: 'returning-employer',
    name: 'Career Connect Pvt. Ltd.',
    email: 'hr@example.com',
  );
