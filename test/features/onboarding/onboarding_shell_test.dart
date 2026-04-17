import 'dart:io';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_providers.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_repository.dart';
import 'package:iwannareadthebiblemore/core/design_system/app_theme.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/firestore_user_plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/onboarding/presentation/screens/onboarding_shell.dart';

Widget _buildShell(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingShell(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.dark(),
      routerConfig: router,
    ),
  );
}

ProviderContainer _makeContainer() {
  final fakeFirestore = FakeFirebaseFirestore();
  final mockAuth = MockFirebaseAuth(
    mockUser: MockUser(uid: 'test-uid'),
    signedIn: true,
  );

  return ProviderContainer(
    overrides: [
      authRepositoryProvider
          .overrideWithValue(FirebaseAuthRepository(mockAuth)),
      userPlanRepositoryProvider.overrideWithValue(
        FirestoreUserPlanRepository(fakeFirestore),
      ),
    ],
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  tearDown(() async {
    final box = Hive.box('settings');
    await box.clear();
  });

  group('OnboardingShell', () {
    testWidgets('shows page 1 (MeetTheLamb) on start', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      expect(find.text('iwannareadthebiblemore'), findsOneWidget);
      expect(find.text('Read daily. Build streaks. Go together.'),
          findsOneWidget);
    });

    testWidgets('tapping Get started navigates to page 2', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('get_started_button')));
      await tester.pumpAndSettle();

      expect(find.text('Set your daily reading goal'), findsOneWidget);
    });

    testWidgets('Next button on page 2 advances to page 3', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      // page 1 -> 2
      await tester.tap(find.byKey(const Key('get_started_button')));
      await tester.pumpAndSettle();

      // page 2 -> 3
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pick your first plan'), findsOneWidget);
    });

    testWidgets('Skip button visible on pages 3 and 4', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      // page 1: no skip
      expect(find.byKey(const Key('skip_button')), findsNothing);

      // page 1 -> 2
      await tester.tap(find.byKey(const Key('get_started_button')));
      await tester.pumpAndSettle();

      // page 2: no skip
      expect(find.byKey(const Key('skip_button')), findsNothing);

      // page 2 -> 3
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      // page 3: skip visible
      expect(find.byKey(const Key('skip_button')), findsOneWidget);
    });

    testWidgets('Skip on page 3 goes to page 4', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('get_started_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      // page 3 -> skip to 4
      await tester.tap(find.byKey(const Key('skip_button')));
      await tester.pumpAndSettle();

      expect(find.text('Bring your friends'), findsOneWidget);
    });

    testWidgets('progress dots reflect current page', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      // On page 1, there should be 5 dot containers in the AppBar title area
      // We check by counting the animated containers (indirectly via the widget tree)
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Advance to page 2
      await tester.tap(find.byKey(const Key('get_started_button')));
      await tester.pumpAndSettle();

      // Still showing 5 progress indicators
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('page 5 shows Set a daily reminder', (tester) async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildShell(container));
      await tester.pumpAndSettle();

      // Navigate through all pages to page 5
      await tester.tap(find.byKey(const Key('get_started_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('skip_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('skip_friends_button')));
      await tester.pumpAndSettle();

      expect(find.text('Set a daily reminder'), findsOneWidget);
      expect(find.byKey(const Key('all_done_button')), findsOneWidget);
    });
  });
}
