import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:employee/main.dart';

void main() {
  testWidgets('Reels open full screen, swipe, and return to the tab', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialPage: 'Reels'));
    await tester.tap(
      find.text('Your next interview.\nYour best first impression.'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
    expect(find.byTooltip('Back to reels'), findsOneWidget);
    await tester.drag(find.byType(PageView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      find.text('Make your resume\nstand out.').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Like reel').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unlike reel').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Back to reels'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shared navigation opens each main screen', (tester) async {
    await tester.pumpWidget(const MyApp(initialPage: 'Home'));
    for (final name in ['Jobs', 'Reels', 'Messages', 'Profile', 'Home']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(name),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(name)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Create post adds content to the feed', (tester) async {
    await tester.pumpWidget(const MyApp(initialPage: 'Home'));
    await tester.tap(find.byTooltip('Create Post'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(1),
      'My new career milestone',
    );
    final post = find.widgetWithText(FilledButton, 'Post');
    await tester.ensureVisible(post);
    await tester.tap(post);
    await tester.pumpAndSettle();
    expect(find.text('My new career milestone'), findsOneWidget);
  });
  testWidgets('Every reference screen opens without layout errors on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp(initialPage: 'Home'));
    for (final name in [
      'My Applications',
      'Candidate Details',
      'Refer & Earn',
      'Saved Jobs',
      'Login',
      'Registration',
      'Personal Details',
      'Job Preferences',
      'Education',
      'Work Experience',
      'Skills',
      'Resume',
    ]) {
      await tester.pumpWidget(MyApp(key: ValueKey(name), initialPage: 'Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('All screens'));
      await tester.pumpAndSettle();
      final target = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(ListTile, name),
      );
      await tester.scrollUntilVisible(
        target,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
    }
  });
}
