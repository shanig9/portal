import 'dart:async';

import 'package:employee/career_connect_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final role in ['Employee / Job Seeker', 'HR / Employer']) {
    testWidgets('Back stays in $role until sign-out', (tester) async {
      final auth = StreamController<bool>();
      addTearDown(auth.close);
      await tester.pumpWidget(CareerConnectApp(signedInChanges: auth.stream));
      await tester.pumpAndSettle();
      final roleCard = find.text(role);
      await tester.ensureVisible(roleCard);
      await tester.tap(roleCard);
      await tester.pumpAndSettle();

      auth.add(true);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(roleCard, findsNothing);

      auth.add(false);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(roleCard, findsOneWidget);
    });
  }

  testWidgets('opens both role flows from the Career Connect welcome screen', (
    tester,
  ) async {
    await tester.pumpWidget(const CareerConnectApp());
    await tester.pumpAndSettle();

    final employee = find.text('Employee / Job Seeker');
    await tester.ensureVisible(employee);
    await tester.tap(employee);
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Choose a role'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final employer = find.text('HR / Employer');
    await tester.ensureVisible(employer);
    await tester.tap(employer);
    await tester.pumpAndSettle();
    expect(find.text('Choose a role'), findsNothing);
    final employerLogin = find.text('Login as Employer');
    await tester.scrollUntilVisible(employerLogin, 200);
    await tester.tap(employerLogin);
    await tester.pumpAndSettle();
    expect(employerLogin, findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Login as Employer'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('HR / Employer'), findsOneWidget);
  });
}
