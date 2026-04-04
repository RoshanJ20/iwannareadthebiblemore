import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_repository.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_notifier.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_providers.dart';

void main() {
  group('AuthNotifier', () {
    test('initial state is loading then resolves to unauthenticated', () async {
      final mockAuth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(mockAuth),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initially loading
      expect(
        container.read(authNotifierProvider),
        isA<AsyncLoading<User?>>(),
      );

      // After stream emits null — unauthenticated
      await container.read(authNotifierProvider.future);
      expect(container.read(authNotifierProvider).value, isNull);
    });

    test('state is authenticated when Firebase has a signed-in user', () async {
      final mockUser = MockUser(uid: 'uid-abc', displayName: 'Rosh');
      final mockAuth = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(mockAuth),
          ),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authNotifierProvider.future);
      expect(user?.uid, 'uid-abc');
    });
  });
}
