import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'verified_phone_registration.dart';

class HrAccount {
  const HrAccount({required this.uid, this.name, this.email, this.phone});
  final String uid;
  final String? name, email, phone;
}

class HrPhoneChallenge {
  const HrPhoneChallenge(this.confirm, {this.resendToken});
  final int? resendToken;
  final Future<HrAccount> Function(String code) confirm;
}

abstract class HrAuthService {
  HrAccount? get currentAccount;
  Future<HrAccount> signIn(String email, String password);
  Future<HrAccount> register(
    String companyName,
    String email,
    String password, {
    required String verifiedPhoneUid,
  });
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> sendPhoneCode(
    String phone, {
    int? resendToken,
    required void Function(HrPhoneChallenge) onCodeSent,
    required void Function(HrAccount) onVerified,
    required void Function(Object) onError,
  });
}

class FirebaseHrAuthService implements HrAuthService {
  static final instance = FirebaseHrAuthService();
  FirebaseAuth get _auth => FirebaseAuth.instance;
  HrAccount _account(User user) => HrAccount(
    uid: user.uid,
    name: user.displayName,
    email: user.email,
    phone: user.phoneNumber,
  );
  HrAccount _result(UserCredential result) => _account(result.user!);

  @override
  HrAccount? get currentAccount {
    if (Firebase.apps.isEmpty) return null;
    final user = _auth.currentUser;
    return user == null ? null : _account(user);
  }

  @override
  Future<HrAccount> signIn(String email, String password) async => _result(
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<HrAccount> register(
    String companyName,
    String email,
    String password, {
    required String verifiedPhoneUid,
  }) async {
    final user = await linkVerifiedPhoneRegistration(
      _auth,
      verifiedPhoneUid: verifiedPhoneUid,
      displayName: companyName,
      email: email,
      password: password,
    );
    return HrAccount(
      uid: user.uid,
      name: companyName.trim(),
      email: email.trim(),
      phone: user.phoneNumber,
    );
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPhoneCode(
    String phone, {
    int? resendToken,
    required void Function(HrPhoneChallenge) onCodeSent,
    required void Function(HrAccount) onVerified,
    required void Function(Object) onError,
  }) async {
    if (kIsWeb) {
      final result = await _auth.signInWithPhoneNumber(phone);
      onCodeSent(
        HrPhoneChallenge((code) async => _result(await result.confirm(code))),
      );
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          onVerified(_result(await _auth.signInWithCredential(credential)));
        } catch (error) {
          onError(error);
        }
      },
      verificationFailed: onError,
      codeSent: (id, token) => onCodeSent(
        HrPhoneChallenge(
          (code) async => _result(
            await _auth.signInWithCredential(
              PhoneAuthProvider.credential(verificationId: id, smsCode: code),
            ),
          ),
          resendToken: token,
        ),
      ),
      codeAutoRetrievalTimeout: (_) {},
    );
  }
}

class HrAuthScope extends InheritedWidget {
  const HrAuthScope({super.key, required this.auth, required super.child});
  final HrAuthService auth;
  static HrAuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HrAuthScope>()?.auth ??
      FirebaseHrAuthService.instance;
  @override
  bool updateShouldNotify(HrAuthScope oldWidget) => auth != oldWidget.auth;
}

String hrAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'email-already-in-use' =>
        'This email already has an account. Please sign in.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a stronger password with at least 8 characters.',
      'user-disabled' => 'This account has been disabled.',
      'invalid-phone-number' => 'Enter a valid 10-digit Indian mobile number.',
      'phone-verification-required' => 'Verify your mobile number to register.',
      'phone-already-registered' =>
        'This mobile number already has an account. Please sign in.',
      'registration-failed' => 'Could not finish registration. Try again or sign in if you already have an account.',
      'invalid-verification-code' =>
        'The verification code is incorrect. Please try again.',
      'session-expired' ||
      'invalid-verification-id' => 'This code has expired. Request a new code.',
      'too-many-requests' =>
        'Too many attempts. Please wait before trying again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'quota-exceeded' =>
        'SMS is temporarily unavailable. Please try again later.',
      'app-not-authorized' ||
      'invalid-app-credential' ||
      'missing-client-identifier' =>
        'Firebase could not verify this Android app for phone sign-in.',
      'operation-not-allowed' =>
        'This sign-in method is currently unavailable.',
      _ => 'Authentication could not complete. Please try again.',
    };
  }
  return 'Unable to connect. Please try again.';
}
