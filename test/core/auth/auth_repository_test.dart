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

    test('currentUser is non-null after any sign-in event', () async {
      // Uses signInAnonymously to trigger mock state change (Google/Apple
      // sign-in require platform plugins not available in unit tests).
      final authWithUser = MockFirebaseAuth(mockUser: MockUser(
        uid: 'uid-123',
        displayName: 'Test User',
        email: 'test@example.com',
        isAnonymous: true,
      ));
      final repoWithUser = FirebaseAuthRepository(authWithUser);

      await authWithUser.signInAnonymously();
      expect(repoWithUser.currentUser, isNotNull);
    });

    test('signInWithGoogle throws UnimplementedError (stub until Task 6)', () {
      expect(() => repo.signInWithGoogle(), throwsA(isA<UnimplementedError>()));
    });

    test('signInWithApple throws UnimplementedError (stub until Task 6)', () {
      expect(() => repo.signInWithApple(), throwsA(isA<UnimplementedError>()));
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
