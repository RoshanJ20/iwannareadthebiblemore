import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'auth_providers.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    // Keep state in sync with Firebase auth stream.
    // _authStreamProvider is a StreamProvider so its value is AsyncValue<User?>.
    ref.listen<AsyncValue<User?>>(
      _authStreamProvider,
      (_, next) => state = next.when(
        data: AsyncData.new,
        loading: () => const AsyncLoading(),
        error: AsyncError.new,
      ),
    );
    return repo.currentUser;
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
  }
}

// Internal: raw stream provider
final _authStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
