import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr/main.dart';
import 'package:hr/auth_service.dart';
import 'package:hr/auth_screens.dart';
import 'package:hr/screens.dart' show PortalScreen, WelcomeScreen;
import 'fake_auth_service.dart';

Future<void> tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  for (var attempt = 0; target.evaluate().isEmpty && attempt < 30; attempt++) {
    final bounds = tester.getRect(find.byType(ListView).first);
    await tester.dragFrom(Offset(bounds.left + 5, bounds.center.dy), const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final target = find.ancestor(of: find.text(label), matching: find.byType(TextFormField));
  for (var attempt = 0; target.evaluate().isEmpty && attempt < 30; attempt++) {
    final bounds = tester.getRect(find.byType(ListView).first);
    await tester.dragFrom(Offset(bounds.left + 5, bounds.center.dy), const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Email login validates, rejects invalid credentials, then signs in', (tester) async {
    final auth = FakeHrAuthService();
    await tester.pumpWidget(MyApp(auth: auth));
    expect(find.text('Explore frontend preview'), findsNothing);
    await tap(tester, 'Login as Employer');
    await tap(tester, 'Sign in');
    expect(auth.loginCalls, 0);
    await enter(tester, 'Email Address', 'hr@example.com');
    await enter(tester, 'Password', 'password123');
    auth.failure = FirebaseAuthException(code: 'invalid-credential');
    await tap(tester, 'Sign in');
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.byType(PortalScreen), findsNothing);
    auth.failure = null;
    await tap(tester, 'Sign in');
    expect(find.byType(PortalScreen), findsOneWidget);
    expect(auth.lastEmail, 'hr@example.com');
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('Email registration checks passwords and creates a Firebase account', (tester) async {
    final auth = FakeHrAuthService();
    await tester.pumpWidget(HrAuthScope(auth: auth, child: const MaterialApp(home: RegistrationScreen())));
    await enter(tester, 'Company Name *', 'Career Connect Test Company');
    await enter(tester, 'Location *', 'Pune');
    await enter(tester, 'Company Phone *', '+919876543210');
    await enter(tester, 'Official Email *', 'hr@example.com');
    await enter(tester, 'Password', 'password123');
    await enter(tester, 'Confirm Password', 'different');
    await tap(tester, 'Create Employer Account');
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(auth.registerCalls, 0);
    await enter(tester, 'Confirm Password', 'password123');
    await tap(tester, 'I agree to the Terms & Conditions and Privacy Policy');
    await tap(tester, 'Create Employer Account');
    expect(auth.registerCalls, 1);
    expect(find.byType(PortalScreen), findsOneWidget);
  });

  testWidgets('Incorrect OTP stays on verification and a valid OTP signs in', (tester) async {
    final auth = FakeHrAuthService();
    await tester.pumpWidget(HrAuthScope(auth: auth, child: const MaterialApp(home: OtpScreen(phone: '+919876543210'))));
    await tester.pumpAndSettle();
    expect(auth.phoneCalls, 1);
    await enter(tester, 'Verification code', '123456');
    auth.failure = FirebaseAuthException(code: 'invalid-verification-code');
    await tap(tester, 'Verify and sign in');
    expect(find.text('The verification code is incorrect. Please try again.'), findsOneWidget);
    expect(find.byType(PortalScreen), findsNothing);
    auth.failure = null;
    await tap(tester, 'Verify and sign in');
    expect(find.byType(PortalScreen), findsOneWidget);
    expect(auth.lastCode, '123456');
  });

  testWidgets('OTP resend waits for cooldown and sends another request', (tester) async {
    final auth = FakeHrAuthService();
    await tester.pumpWidget(HrAuthScope(auth: auth, child: const MaterialApp(home: OtpScreen(phone: '+919876543210'))));
    await tester.pumpAndSettle();
    expect(auth.phoneCalls, 1);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Resend code in 60s')).onPressed, isNull);
    await tester.pump(const Duration(seconds: 61));
    await tap(tester, 'Send code again');
    expect(auth.phoneCalls, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Automatic phone verification opens the dashboard', (tester) async {
    final auth = FakeHrAuthService()..automaticPhone = true;
    await tester.pumpWidget(HrAuthScope(auth: auth, child: const MaterialApp(home: OtpScreen(phone: '+919876543210'))));
    await tester.pumpAndSettle();
    expect(find.byType(PortalScreen), findsOneWidget);
  });

  testWidgets('Failed SMS request can retry without entering dashboard', (tester) async {
    final auth = FakeHrAuthService()..failure = FirebaseAuthException(code: 'too-many-requests');
    await tester.pumpWidget(HrAuthScope(auth: auth, child: const MaterialApp(home: OtpScreen(phone: '+919876543210'))));
    await tester.pumpAndSettle();
    expect(find.text('Too many attempts. Please wait before trying again.'), findsOneWidget);
    expect(find.byType(PortalScreen), findsNothing);
    auth.failure = null;
    await tap(tester, 'Send code again');
    expect(auth.phoneCalls, 2);
    expect(find.byKey(const ValueKey('Verification code')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Password reset submits the account email', (tester) async {
    final auth = FakeHrAuthService();
    await tester.pumpWidget(HrAuthScope(auth: auth, child: const MaterialApp(home: ResetPasswordScreen())));
    await enter(tester, 'Email Address', 'hr@example.com');
    await tap(tester, 'Send reset link');
    expect(auth.lastEmail, 'hr@example.com');
    expect(find.textContaining('a reset link will arrive'), findsOneWidget);
  });

  testWidgets('Restored session signs out and removes dashboard from history', (tester) async {
    final auth = signedInAuth();
    await tester.pumpWidget(MyApp(auth: auth));
    expect(find.byType(PortalScreen), findsOneWidget);
    await tap(tester, 'Profile');
    await tap(tester, 'Sign out');
    expect(auth.currentAccount, isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(PortalScreen), findsNothing);
  });
}
