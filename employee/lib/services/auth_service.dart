import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthAccount {
  const AuthAccount({required this.uid, this.name, this.email, this.phone});
  final String uid;
  final String? name, email, phone;
}

class PhoneChallenge {
  const PhoneChallenge(this.confirm);
  final Future<AuthAccount> Function(String code) confirm;
}

abstract class AuthService {
  AuthAccount? get currentAccount;
  Future<AuthAccount> signIn(String email, String password);
  Future<AuthAccount> register(String name, String email, String password);
  Future<AuthAccount> google();
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(PhoneChallenge) onCodeSent,
    required void Function(AuthAccount) onVerified,
    required void Function(Object) onError,
  });
}

class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  Future<void>? _googleInitialization;

  AuthAccount _account(User user) => AuthAccount(
    uid: user.uid,
    name: user.displayName,
    email: user.email,
    phone: user.phoneNumber,
  );

  AuthAccount _result(UserCredential result) => _account(result.user!);

  @override
  AuthAccount? get currentAccount {
    if (Firebase.apps.isEmpty) return null;
    final user = _auth.currentUser;
    return user == null ? null : _account(user);
  }

  @override
  Future<AuthAccount> signIn(String email, String password) async => _result(
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<AuthAccount> register(
    String name,
    String email,
    String password,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user!.updateDisplayName(name.trim());
    return AuthAccount(
      uid: result.user!.uid,
      name: name.trim(),
      email: result.user!.email,
    );
  }

  @override
  Future<AuthAccount> google() async {
    if (kIsWeb) {
      return _result(await _auth.signInWithPopup(GoogleAuthProvider()));
    }
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;
    final user = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: user.authentication.idToken,
    );
    return _result(await _auth.signInWithCredential(credential));
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb && _googleInitialization != null) {
      // Firebase sign-out is complete even if Google account cleanup fails.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  @override
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(PhoneChallenge) onCodeSent,
    required void Function(AuthAccount) onVerified,
    required void Function(Object) onError,
  }) async {
    if (kIsWeb) {
      final result = await _auth.signInWithPhoneNumber(phone);
      onCodeSent(
        PhoneChallenge((code) async => _result(await result.confirm(code))),
      );
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          onVerified(_result(await _auth.signInWithCredential(credential)));
        } catch (error) {
          onError(error);
        }
      },
      verificationFailed: onError,
      codeSent: (id, _) => onCodeSent(
        PhoneChallenge(
          (code) async => _result(
            await _auth.signInWithCredential(
              PhoneAuthProvider.credential(verificationId: id, smsCode: code),
            ),
          ),
        ),
      ),
      codeAutoRetrievalTimeout: (_) {},
    );
  }
}

String authErrorMessage(Object error) {
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Google sign-in was cancelled. Please try again.';
    }
    return 'Google sign-in could not complete. Please try again.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'email-already-in-use' =>
        'This email already has an account. Please sign in.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' =>
        'Choose a stronger password with at least 8 characters.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Please wait before trying again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'invalid-phone-number' =>
        'Enter your phone number with its country code, such as +91.',
      'invalid-verification-code' =>
        'The verification code is incorrect. Please try again.',
      'session-expired' ||
      'invalid-verification-id' => 'This code has expired. Request a new code.',
      'quota-exceeded' =>
        'SMS is temporarily unavailable. Please try again later.',
      'operation-not-allowed' =>
        'This sign-in method is currently unavailable.',
      'account-exists-with-different-credential' =>
        'Use your existing sign-in method for this email.',
      _ => 'Authentication could not complete. Please try again.',
    };
  }
  return 'Unable to connect. Please try again.';
}
