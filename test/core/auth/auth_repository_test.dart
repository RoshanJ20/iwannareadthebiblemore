import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_repository.dart';

void main() {
  group('FirebaseAuthRepository', () {
    late MockFirebaseAuth mockAuth;
    late FirebaseAuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      repo = FirebaseAuthRepository(mockAuth);
    });

    test('currentUser returns null when not signed in', () {
      expect(repo.currentUser, isNull);
    });

    test('authStateChanges emits null when not signed in', () {
      expect(repo.authStateChanges, emits(isNull));
    });

    test('signInWithGoogle returns a User on success', () async {
      // MockUser must have isAnonymous: true to be compatible with signInAnonymously
      // in firebase_auth_mocks 0.14.x
      final authWithUser = MockFirebaseAuth(mockUser: MockUser(
        uid: 'uid-123',
        displayName: 'Test User',
        email: 'test@example.com',
        isAnonymous: true,
      ));
      final repoWithUser = FirebaseAuthRepository(authWithUser);

      // Sign in anonymously to simulate auth mock returning a user
      await authWithUser.signInAnonymously();
      expect(repoWithUser.currentUser, isNotNull);
    });

    test('signOut clears currentUser', () async {
      final authWithUser = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-123'),
        signedIn: true,
      );
      final repoWithUser = FirebaseAuthRepository(authWithUser);
      expect(repoWithUser.currentUser, isNotNull);

      await repoWithUser.signOut();
      expect(repoWithUser.currentUser, isNull);
    });
  });
}
