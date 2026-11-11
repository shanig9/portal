import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:employee/main.dart';
import 'package:employee/screens/login_screen.dart';
import 'package:employee/screens/registration_screen.dart';
import 'package:employee/screens/personal_details_screen.dart';

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
  testWidgets('App starts on login and validates before entering the preview', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LoginScreen), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Login');
    await tapVisible(tester, submit);
    expect(find.text('Enter email or mobile number'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);
    await enter(tester, 'Email or Mobile Number', 'candidate@example.com');
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
  });

  testWidgets('Registration checks confirmation and opens personal details', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialPage: 'Registration'));
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
    await enter(tester, 'Confirm Password', 'password123');
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );
    expect(find.byType(PersonalDetailsScreen), findsOneWidget);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('asha@example.com'), findsOneWidget);
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
