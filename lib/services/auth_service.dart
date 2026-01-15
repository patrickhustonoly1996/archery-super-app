import 'package:firebase_auth/firebase_auth.dart';

/// Simple authentication service wrapping Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// User ID (null if not logged in)
  String? get userId => _auth.currentUser?.uid;

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
