import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signInWithGoogle() async {
    // GoogleSignIn integration wired in Task 6 (sign-in screen).
    // Stub throws so tests calling this fail loudly.
    throw UnimplementedError('signInWithGoogle — wired in sign-in screen task');
  }

  @override
  Future<void> signInWithApple() async {
    throw UnimplementedError('signInWithApple — wired in sign-in screen task');
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
