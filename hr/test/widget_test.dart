import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr/main.dart';
import 'package:hr/models.dart';
import 'package:hr/screens.dart';
import 'package:hr/job_screens.dart';
import 'package:hr/profile_screens.dart';
import 'package:hr/auth_service.dart';

import 'fake_auth_service.dart';

Finder field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

Future<void> tapVisible(WidgetTester tester, String label) async {
  final target = find.text(label);
  // Drag in the list padding so multiline inputs cannot consume the gesture.
  for (var attempt = 0; target.evaluate().isEmpty && attempt < 30; attempt++) {
    final bounds = tester.getRect(find.byType(ListView).first);
    await tester.dragFrom(
      Offset(bounds.left + 5, bounds.center.dy),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Signed-in employer restores the portal and opens the job form', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(auth: signedInAuth()));
    expect(find.text('Job Applications'), findsOneWidget);
    expect(find.text('Sneha Kulkarni'), findsOneWidget);
    await tester.tap(find.text('Post Job'));
    await tester.pumpAndSettle();
    expect(find.text('Basic Details'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login validates mobile number before showing OTP', (
    tester,
  ) async {
    final auth = FakeHrAuthService();
    await tester.pumpWidget(MyApp(auth: auth));
    await tapVisible(tester, 'Login as Employer');
    await tester.tap(find.text('Phone OTP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(
      find.text('Include your country code, for example +91.'),
      findsOneWidget,
    );
    expect(auth.phoneCalls, 0);
    await tester.enterText(find.byType(TextFormField), '+919876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Mobile Number'), findsOneWidget);
    expect(auth.phoneCalls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Job creation returns a draft and profile edits can be cancelled',
    (tester) async {
      await tester.pumpWidget(MyApp(auth: signedInAuth()));
      await tester.tap(find.text('Post Job'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Job Title *'), 'Product Designer');
      await tester.tap(find.text('Save Draft'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Product Designer'), 200);
      expect(find.text('Product Designer'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Edit Profile');
      await tester.enterText(field('Company Name *'), 'Unsaved company');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved company'), findsNothing);
      expect(find.text('Career Connect Pvt. Ltd.'), findsWidgets);
    },
  );

  testWidgets('Job can be previewed, published, edited and deleted', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(auth: signedInAuth()));
    await tester.tap(find.text('Post Job'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Job Title *'), 'New Engineer');
    await tapVisible(tester, '+ Add Skill');
    await tester.enterText(find.byType(TextField).last, 'Flutter');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Preview');
    expect(find.text('Job Preview'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Publish Job');
    await tapVisible(tester, 'New Engineer');
    expect(find.text('Job Details'), findsOneWidget);
    await tapVisible(tester, 'Edit Job');
    await tester.enterText(field('Job Title *'), 'Senior Engineer');
    await tapVisible(tester, 'Save Job');
    await tester.scrollUntilVisible(
      find.text('Senior Engineer'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Senior Engineer'), findsOneWidget);
    await tapVisible(tester, 'Delete Job');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Job Details'), findsOneWidget);
    await tester.tap(find.text('Delete Job'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Job Applications'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Job Applications'), findsOneWidget);
    expect(find.text('Senior Engineer'), findsNothing);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('HR screens fit a $width pixel viewport', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final company = Company();
      final screens = <Widget>[
        const WelcomeScreen(),
        const LoginScreen(),
        const RegistrationScreen(),
        OtpScreen(company: company, phone: '+919876543210'),
        PortalScreen(company: company),
        const JobFormScreen(),
        JobDetailsScreen(job: Job()),
        EditProfileScreen(company: company),
        Scaffold(
          body: EmployerProfile(company: company, onChanged: () {}),
        ),
      ];
      for (final screen in screens) {
        await tester.pumpWidget(
          HrAuthScope(
            auth: FakeHrAuthService(),
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} should fit',
        );
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
