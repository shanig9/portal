import 'package:employee/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Employee screens fit a small phone with bundled artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in [
      'Login',
      'Registration',
      'Home',
      'Jobs',
      'Messages',
      'Profile',
      'My Applications',
      'Candidate Details',
      'Refer & Earn',
      'Saved Jobs',
      'Personal Details',
      'Job Preferences',
      'Education',
      'Work Experience',
      'Skills',
      'Resume',
      'Notifications',
      'Phone Login',
      'Forgot Password',
    ]) {
      await tester.pumpWidget(MyApp(key: ValueKey(page), initialPage: page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: page);
      if (page == 'Resume') {
        expect(
          find.text('Save & Complete Profile').hitTestable(),
          findsOneWidget,
        );
      }
    }
  });
}
