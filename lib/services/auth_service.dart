import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service_base.dart';
import 'sync_service.dart';

/// Simple authentication service wrapping Firebase Auth
class AuthService implements AuthServiceBase {
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

  /// Sign out - syncs data to cloud first, then clears local data
  ///
  /// This is critical for data safety:
  /// 1. Attempt to sync any pending data to cloud (with timeout)
  /// 2. Clear all local data to prevent data leak between accounts
  /// 3. Clear "was logged in" flag
  /// 4. Sign out of Firebase
  ///
  /// If sync fails, we still proceed with logout to prevent stuck state,
  /// but the user's data is already in the cloud from previous syncs.
  Future<void> signOut() async {
    final syncService = SyncService();

    // Step 1: Attempt final sync before logout (with 10s timeout)
    // This ensures any pending data gets uploaded before we wipe local
    try {
      if (syncService.isAuthenticated) {
        debugPrint('SignOut: Attempting final sync before logout...');
        await syncService.syncAll().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('SignOut: Final sync timed out, proceeding with logout');
            return SyncResult(success: false, message: 'Sync timed out');
          },
        );
        debugPrint('SignOut: Final sync completed');
      }
    } catch (e) {
      // Don't block logout if sync fails - data should already be in cloud
      // from previous syncs during normal app usage
      debugPrint('SignOut: Final sync failed ($e), proceeding with logout');
    }

    // Step 2: Clear local data to prevent data leak between accounts
    try {
      await syncService.clearLocalData();
      debugPrint('SignOut: Local data cleared');
    } catch (e) {
      // Log but continue - we must complete signout
      debugPrint('SignOut: Failed to clear local data ($e), continuing with signout');
    }

    // Step 3: Clear "was logged in" flag
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('was_logged_in');
      debugPrint('SignOut: Cleared was_logged_in flag');
    } catch (e) {
      debugPrint('SignOut: Failed to clear prefs ($e), continuing with signout');
    }

    // Step 4: Sign out of Firebase (must happen last)
    await _auth.signOut();
    debugPrint('SignOut: Firebase signout complete');
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
