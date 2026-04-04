import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_providers.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_repository.dart';
import 'package:iwannareadthebiblemore/core/navigation/app_router.dart';
import 'package:iwannareadthebiblemore/core/navigation/routes.dart';

void main() {
  group('AppRouter', () {
    testWidgets('unauthenticated user is redirected to /login', (tester) async {
      final mockAuth = MockFirebaseAuth(); // not signed in
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(mockAuth),
        ),
      ]);

      final router = AppRouter.create(container);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          Routes.login);
    });

    testWidgets('authenticated user lands on /home', (tester) async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-1'),
        signedIn: true,
      );
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(mockAuth),
        ),
      ]);

      final router = AppRouter.create(container);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          Routes.home);
    });
  });
}
