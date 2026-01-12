import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Simple authentication service wrapping Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignInInstance;

  // Key for storing email pending magic link verification
  static const String _pendingEmailKey = 'pending_magic_link_email';

  /// Lazy-initialize GoogleSignIn to avoid web errors when client ID isn't set
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn();
    return _googleSignInInstance!;
  }

  /// Current user stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// User ID (null if not logged in)
  String? get userId => _auth.currentUser?.uid;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Trigger Google sign-in flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // User cancelled sign-in
      return null;
    }

    // Get auth details from Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with Google credential
    return await _auth.signInWithCredential(credential);
  }

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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ============ MAGIC LINK AUTHENTICATION ============

  /// Send a magic link (sign-in link) to the user's email
  Future<void> sendMagicLink(String email) async {
    // Configure the action code settings
    // The URL must be whitelisted in Firebase Console > Authentication > Settings > Authorized domains
    final actionCodeSettings = ActionCodeSettings(
      // URL to redirect to after clicking the link
      // For web PWA, this should be your deployed domain
      url: kIsWeb
          ? 'https://archery-super-app.web.app/login'
          : 'https://archery-super-app.web.app/login',
      handleCodeInApp: true,
      // iOS settings (for future native app)
      iOSBundleId: 'com.patrickhuston.archerySuperApp',
      // Android settings (for future native app)
      androidPackageName: 'com.patrickhuston.archery_super_app',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    // Send the sign-in link
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );

    // Store the email locally so we can complete sign-in when user returns
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);
  }

  /// Check if a URL is a valid sign-in link
  bool isSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  /// Complete sign-in with the magic link
  /// Call this when the app opens from a magic link
  Future<UserCredential?> signInWithMagicLink(String emailLink) async {
    // Get the stored email
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingEmailKey);

    if (email == null) {
      // No pending email - user may need to enter it manually
      return null;
    }

    // Complete the sign-in
    final credential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    // Clear the stored email
    await prefs.remove(_pendingEmailKey);

    return credential;
  }

  /// Complete sign-in with magic link using a manually provided email
  /// Use this if the stored email was lost (e.g., different browser)
  Future<UserCredential> signInWithMagicLinkAndEmail({
    required String email,
    required String emailLink,
  }) async {
    final credential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    // Clear any stored email
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);

    return credential;
  }

  /// Get the pending email (if any) for magic link sign-in
  Future<String?> getPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingEmailKey);
  }

  /// Clear the pending email
  Future<void> clearPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);
  }
}
