import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_providers.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_repository.dart';
import 'package:iwannareadthebiblemore/core/navigation/app_router.dart';
import 'package:iwannareadthebiblemore/core/design_system/app_theme.dart';

Widget _buildApp(GoRouter router, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.dark(),
      routerConfig: router,
    ),
  );
}

void main() {
  group('ShellScreen', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-1', displayName: 'Test'),
        signedIn: true,
      );
      container = ProviderContainer(overrides: [
        authRepositoryProvider
            .overrideWithValue(FirebaseAuthRepository(mockAuth)),
      ]);
      router = AppRouter.create(container);
    });

    tearDown(() => container.dispose());

    testWidgets('bottom nav renders 5 tabs', (tester) async {
      await tester.pumpWidget(_buildApp(router, container));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('tapping Profile tab shows profile screen content',
        (tester) async {
      await tester.pumpWidget(_buildApp(router, container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      expect(find.byKey(const Key('sign_out_button')), findsOneWidget);
    });
  });
}
