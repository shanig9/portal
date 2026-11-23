import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:employee/main.dart';
import 'package:employee/screens/reels_screen.dart';
import 'package:employee/services/reels_service.dart';
import 'package:employee/state/employee_controller.dart';

void main() {
  testWidgets('Home opens reels and can enter and exit full screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialPage: 'Reels'));
    await tester.pumpAndSettle();
    expect(find.text('Add video'), findsOneWidget);
    expect(find.byTooltip('Refresh reels'), findsOneWidget);
    expect(find.text('Reels'), findsNothing);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Full screen'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reel Like button toggles the selected reel', (tester) async {
    final state = EmployeeController();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (_, _) => ReelsScreen(
              state: state,
              immersive: false,
              onToggleImmersive: () {},
              service: _PreviewReels(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Like reel'));
    await tester.pumpAndSettle();
    expect(state.likedReels, {'test-reel'});
    await tester.tap(find.byTooltip('Unlike reel'));
    expect(state.likedReels, isEmpty);
  });
  testWidgets('Shared navigation opens each main screen', (tester) async {
    await tester.pumpWidget(const MyApp(initialPage: 'Home'));
    for (final name in ['Jobs', 'Messages', 'Profile', 'Home']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(name),
        ),
      );
      await tester.pumpAndSettle();
      if (name == 'Home') {
        expect(find.byType(ReelsScreen), findsOneWidget);
      } else {
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text(name)),
          findsOneWidget,
        );
      }
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

class _PreviewReels extends ReelsService {
  @override
  Future<List<Reel>> deviceReels() async => [];

  @override
  Future<ReelsPage> list({String? cursor}) async => ReelsPage([
    Reel.fromJson({
      'id': 'test-reel',
      'url': 'https://example.com/reel.jpg',
      'type': 'image',
      'caption': 'Test reel',
      'author': 'Career Connect',
    }),
  ], null);
}
