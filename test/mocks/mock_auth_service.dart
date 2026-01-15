/// Mock authentication service for testing
///
/// Provides a simple mock of AuthService that doesn't require
/// Firebase infrastructure for testing.
library;

import 'dart:async';

/// Mock user class for testing
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });
}

/// Mock user credential for testing
class MockUserCredential {
  final MockUser? user;
  final bool isNewUser;

  MockUserCredential({
    this.user,
    this.isNewUser = false,
  });
}

/// Mock authentication service for testing
///
/// Simulates Firebase Auth behavior without actual Firebase dependency.
class MockAuthService {
  MockUser? _currentUser;
  final _authStateController = StreamController<MockUser?>.broadcast();
  String? _pendingMagicLinkEmail;

  // Simulated users database
  final Map<String, MockUser> _users = {};
  final Map<String, String> _passwords = {};

  // Error simulation flags
  bool simulateNetworkError = false;
  bool simulateInvalidCredentials = false;
  bool simulateUserNotFound = false;
  bool simulateWeakPassword = false;
  bool simulateEmailInUse = false;

  /// Stream of auth state changes
  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  /// Current user (null if not logged in)
  MockUser? get currentUser => _currentUser;

  /// User ID (null if not logged in)
  String? get userId => _currentUser?.uid;

  /// Sign in with Google (simulated)
  Future<MockUserCredential?> signInWithGoogle() async {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }

    // Simulate successful Google sign-in
    final user = MockUser(
      uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
      email: 'test@gmail.com',
      displayName: 'Test User',
    );

    _setCurrentUser(user);
    return MockUserCredential(user: user, isNewUser: true);
  }

  /// Sign up with email and password
  Future<MockUserCredential> signUp({
    required String email,
    required String password,
  }) async {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }

    if (simulateWeakPassword || password.length < 6) {
      throw Exception('Password too weak');
    }

    if (simulateEmailInUse || _users.values.any((u) => u.email == email)) {
      throw Exception('Email already in use');
    }

    final user = MockUser(
      uid: 'email_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );

    _users[user.uid] = user;
    _passwords[user.uid] = password;
    _setCurrentUser(user);

    return MockUserCredential(user: user, isNewUser: true);
  }

  /// Sign in with email and password
  Future<MockUserCredential> signIn({
    required String email,
    required String password,
  }) async {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }

    // Find user by email
    MockUser? user;
    String? userId;
    for (final entry in _users.entries) {
      if (entry.value.email == email) {
        user = entry.value;
        userId = entry.key;
        break;
      }
    }

    if (simulateUserNotFound || user == null) {
      throw Exception('User not found');
    }

    if (simulateInvalidCredentials || _passwords[userId] != password) {
      throw Exception('Invalid credentials');
    }

    _setCurrentUser(user);
    return MockUserCredential(user: user);
  }

  /// Sign out
  Future<void> signOut() async {
    _setCurrentUser(null);
  }

  /// Send password reset email (simulated)
  Future<void> resetPassword(String email) async {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }

    // Just simulate success - no actual email sent
  }

  /// Send magic link (simulated)
  Future<void> sendMagicLink(String email) async {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }

    _pendingMagicLinkEmail = email;
  }

  /// Check if a URL is a valid sign-in link
  bool isSignInLink(String link) {
    return link.contains('magic_link_token=');
  }

  /// Complete sign-in with magic link
  Future<MockUserCredential?> signInWithMagicLink(String emailLink) async {
    if (_pendingMagicLinkEmail == null) {
      return null;
    }

    final user = MockUser(
      uid: 'magic_${DateTime.now().millisecondsSinceEpoch}',
      email: _pendingMagicLinkEmail,
    );

    _users[user.uid] = user;
    _pendingMagicLinkEmail = null;
    _setCurrentUser(user);

    return MockUserCredential(user: user);
  }

  /// Complete sign-in with magic link using provided email
  Future<MockUserCredential> signInWithMagicLinkAndEmail({
    required String email,
    required String emailLink,
  }) async {
    if (simulateNetworkError) {
      throw Exception('Network error');
    }

    final user = MockUser(
      uid: 'magic_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );

    _users[user.uid] = user;
    _pendingMagicLinkEmail = null;
    _setCurrentUser(user);

    return MockUserCredential(user: user);
  }

  /// Get pending email for magic link
  Future<String?> getPendingEmail() async => _pendingMagicLinkEmail;

  /// Clear pending email
  Future<void> clearPendingEmail() async {
    _pendingMagicLinkEmail = null;
  }

  // ============================================================================
  // TEST HELPERS
  // ============================================================================

  /// Set current user (for test setup)
  void setCurrentUser(MockUser? user) {
    _setCurrentUser(user);
  }

  void _setCurrentUser(MockUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// Create and set a test user
  MockUser createTestUser({
    String? uid,
    String? email,
    String? displayName,
  }) {
    final user = MockUser(
      uid: uid ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
      email: email ?? 'test@example.com',
      displayName: displayName ?? 'Test User',
    );
    _users[user.uid] = user;
    return user;
  }

  /// Pre-register a user for testing sign-in
  void registerUser(String email, String password) {
    final user = MockUser(
      uid: 'pre_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );
    _users[user.uid] = user;
    _passwords[user.uid] = password;
  }

  /// Reset all error simulation flags
  void resetErrors() {
    simulateNetworkError = false;
    simulateInvalidCredentials = false;
    simulateUserNotFound = false;
    simulateWeakPassword = false;
    simulateEmailInUse = false;
  }

  /// Clear all state
  void clear() {
    _currentUser = null;
    _users.clear();
    _passwords.clear();
    _pendingMagicLinkEmail = null;
    resetErrors();
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
