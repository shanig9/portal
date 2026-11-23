import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

Future<User> linkVerifiedPhoneRegistration(
  FirebaseAuth auth, {
  required String verifiedPhoneUid,
  required String displayName,
  required String email,
  required String password,
}) async {
  final user = auth.currentUser;
  if (user == null ||
      user.uid != verifiedPhoneUid ||
      user.phoneNumber == null) {
    throw FirebaseAuthException(code: 'phone-verification-required');
  }
  try {
    if (user.email != null) {
      throw FirebaseAuthException(code: 'phone-already-registered');
    }
    // Identity Platform supports linking email/password through this endpoint
    // when email enumeration protection is enabled.
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw FirebaseAuthException(code: 'phone-verification-required');
    }
    final response = await http
        .post(
          Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:signUp', {
            'key': auth.app.options.apiKey,
          }),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            'email': email.trim(),
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (body['error'] as Map?)?['message'] as String? ?? '';
      throw FirebaseAuthException(
        code: switch (message.split(' ').first) {
          'EMAIL_EXISTS' => 'email-already-in-use',
          'INVALID_EMAIL' => 'invalid-email',
          'WEAK_PASSWORD' ||
          'PASSWORD_DOES_NOT_MEET_REQUIREMENTS' => 'weak-password',
          'OPERATION_NOT_ALLOWED' => 'operation-not-allowed',
          'TOO_MANY_ATTEMPTS_TRY_LATER' => 'too-many-requests',
          _ => 'registration-failed',
        },
      );
    }
  } catch (_) {
    if (auth.currentUser?.uid == user.uid) await auth.signOut();
    rethrow;
  }
  // Use the SDK to pick up the newly linked provider and refresh its session.
  final account = await auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
  final registered = account.user;
  if (registered == null || registered.uid != verifiedPhoneUid) {
    await auth.signOut();
    throw FirebaseAuthException(code: 'registration-failed');
  }
  try {
    await registered.updateDisplayName(displayName.trim());
  } on FirebaseAuthException catch (_) {
    // The account and its sign-in methods are already linked.
  }
  return registered;
}
