import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

/// Fake FirebaseUser for web demo/testing when real Firebase auth is unavailable.
class _MockUser implements User {
  @override
  String get uid => 'demo-user-001';
  @override
  String? get displayName => 'Demo User';
  @override
  String? get email => 'demo@iwannareadthebiblemore.app';
  @override
  String? get photoURL => null;
  @override
  bool get isAnonymous => false;
  @override
  bool get emailVerified => true;
  @override
  String? get phoneNumber => null;
  @override
  List<UserInfo> get providerData => [];
  @override
  String? get tenantId => null;
  @override
  UserMetadata get metadata => throw UnimplementedError();
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
  @override
  Future<void> delete() async {}
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock-token';
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  @override
  Future<void> updateEmail(String newEmail) async {}
  @override
  Future<void> updatePassword(String newPassword) async {}
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();
  @override
  String? get refreshToken => null;
}

class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  final List<void Function(User?)> _listeners = [];

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.multi((controller) {
        // Replay current state immediately to new subscribers
        controller.add(_currentUser);
        _listeners.add(controller.add);
        controller.onCancel = () => _listeners.remove(controller.add);
      });

  void _notify() {
    for (final fn in List.of(_listeners)) {
      fn(_currentUser);
    }
  }

  @override
  Future<UserCredential?> signInWithGoogle() => signInAnonymously();

  @override
  Future<UserCredential?> signInWithApple() => signInAnonymously();

  @override
  Future<UserCredential?> signInAnonymously() async {
    _currentUser = _MockUser();
    _notify();
    return null;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _notify();
  }
}
