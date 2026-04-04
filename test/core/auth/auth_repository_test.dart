import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mocks.dart';

void main() {
  group('FirebaseAuthRepository', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late FirebaseAuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      repo = FirebaseAuthRepository(mockAuth, googleSignIn: mockGoogleSignIn);
    });

    test('currentUser returns null when not signed in', () {
      expect(repo.currentUser, isNull);
    });

    test('authStateChanges emits null when not signed in', () {
      expect(repo.authStateChanges, emits(isNull));
    });

    test('currentUser is non-null after any sign-in event', () async {
      // Uses signInAnonymously to trigger mock state change (Google/Apple
      // sign-in require platform plugins not available in unit tests).
      final authWithUser = MockFirebaseAuth(mockUser: MockUser(
        uid: 'uid-123',
        displayName: 'Test User',
        email: 'test@example.com',
        isAnonymous: true,
      ));
      final repoWithUser = FirebaseAuthRepository(authWithUser,
          googleSignIn: mockGoogleSignIn);

      await authWithUser.signInAnonymously();
      expect(repoWithUser.currentUser, isNotNull);
    });

    test('signInWithGoogle throws when platform plugin is not configured', () {
      // In unit tests, GoogleSignIn throws MissingPluginException or similar.
      // We verify the method is callable and propagates errors rather than silently failing.
      when(() => mockGoogleSignIn.signIn()).thenThrow(Exception('platform not configured'));
      expect(
        () => repo.signInWithGoogle(),
        throwsA(anything), // exact exception depends on platform plugin availability
      );
    });

    test('signInWithApple throws when platform plugin is not configured', () {
      expect(
        () => repo.signInWithApple(),
        throwsA(anything),
      );
    });

    test('signOut clears currentUser', () async {
      final authWithUser = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-123'),
        signedIn: true,
      );
      final repoWithUser = FirebaseAuthRepository(authWithUser,
          googleSignIn: mockGoogleSignIn);
      expect(repoWithUser.currentUser, isNotNull);

      when(() => mockGoogleSignIn.signOut())
          .thenAnswer((_) async => null);
      await repoWithUser.signOut();
      expect(repoWithUser.currentUser, isNull);
    });
  });
}
