import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:employee/main.dart';
import 'package:employee/screens/login_screen.dart';
import 'package:employee/screens/registration_screen.dart';
import 'package:employee/screens/personal_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:employee/services/auth_service.dart';

import 'fake_auth_service.dart';

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final field = find.byKey(ValueKey(label));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Login validates before authenticating with the service', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(MyApp(auth: auth));
    expect(find.byType(LoginScreen), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Login');
    await tapVisible(tester, submit);
    expect(find.text('Enter email address'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);
    expect(auth.loginCalls, 0);
    await enter(tester, 'Email Address', 'candidate@example.com');
    await enter(tester, 'Password', 'password123');
    await tapVisible(tester, find.byTooltip('Show Password'));
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('Password')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.obscureText, isFalse);
    await tapVisible(tester, submit);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byTooltip('Create Post'), findsOneWidget);
    expect(auth.loginCalls, 1);
  });

  testWidgets('Registration checks confirmation and opens personal details', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(MyApp(initialPage: 'Registration', auth: auth));
    expect(find.byType(RegistrationScreen), findsOneWidget);
    await enter(tester, 'Full Name', 'Asha Rao');
    await enter(tester, 'Email Address', 'asha@example.com');
    await enter(tester, 'Mobile Number', '9876543210');
    await enter(tester, 'Password', 'password123');
    await enter(tester, 'Confirm Password', 'different');
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(auth.registrationCalls, 0);
    await enter(tester, 'Confirm Password', 'password123');
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );
    expect(find.byType(PersonalDetailsScreen), findsOneWidget);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('asha@example.com'), findsOneWidget);
    expect(auth.registrationCalls, 1);
  });

  testWidgets('Rejected credentials stay on login and display an error', (
    tester,
  ) async {
    final auth = FakeAuthService()
      ..failure = FirebaseAuthException(code: 'invalid-credential');
    await tester.pumpWidget(MyApp(auth: auth));
    await enter(tester, 'Email Address', 'asha@example.com');
    await enter(tester, 'Password', 'wrong-password');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Login'));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Google signs in and profile sign-out clears the session', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(MyApp(auth: auth));
    await tapVisible(tester, find.text('Continue with Google'));
    expect(auth.googleCalls, 1);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out'), 300);
    await tapVisible(tester, find.text('Sign out'));
    expect(auth.currentAccount, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('OTP verification rejects an invalid code then signs in', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(MyApp(auth: auth));
    await tapVisible(tester, find.text('Sign in with phone OTP'));
    await enter(tester, 'Phone Number', '+919876543210');
    await tapVisible(tester, find.text('Send OTP'));
    expect(auth.lastPhone, '+919876543210');
    auth.failure = FirebaseAuthException(code: 'invalid-verification-code');
    await enter(tester, 'Verification Code', '123456');
    await tapVisible(tester, find.text('Verify and sign in'));
    expect(
      find.text('The verification code is incorrect. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    auth.failure = null;
    await tapVisible(tester, find.text('Verify and sign in'));
    expect(auth.lastCode, '123456');
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Phone automatic verification opens Home', (tester) async {
    final auth = FakeAuthService()..automaticPhone = true;
    await tester.pumpWidget(MyApp(auth: auth));
    await tapVisible(tester, find.text('Sign in with phone OTP'));
    await enter(tester, 'Phone Number', '+919876543210');
    await tapVisible(tester, find.text('Send OTP'));
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Password reset calls the service', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(MyApp(initialPage: 'Forgot Password', auth: auth));
    await enter(tester, 'Email Address', 'asha@example.com');
    await tapVisible(tester, find.text('Request Reset Link'));
    expect(auth.lastEmail, 'asha@example.com');
    expect(find.textContaining('a reset link will arrive'), findsOneWidget);
  });

  testWidgets('Existing Firebase session restores Home', (tester) async {
    final auth = FakeAuthService()
      ..account = const AuthAccount(
        uid: 'returning-user',
        email: 'asha@example.com',
      );
    await tester.pumpWidget(MyApp(auth: auth));
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('Auth screens fit a $width pixel viewport', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in ['Login', 'Registration', 'Forgot Password']) {
        await tester.pumpWidget(MyApp(key: ValueKey(page), initialPage: page));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: page);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
