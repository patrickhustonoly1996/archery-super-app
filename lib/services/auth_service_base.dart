/// Abstract base class for authentication services.
///
/// This interface allows dependency injection for testing by defining
/// the contract that both [AuthService] and [MockAuthService] implement.
abstract class AuthServiceBase {
  /// Sign up with email and password.
  ///
  /// Throws an exception on failure with an error code accessible via
  /// the exception type (FirebaseAuthException for production,
  /// AuthException for mocks).
  Future<void> signUp({
    required String email,
    required String password,
  });

  /// Sign in with email and password.
  ///
  /// Throws an exception on failure with an error code accessible via
  /// the exception type.
  Future<void> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send password reset email.
  Future<void> resetPassword(String email);
}

/// Exception thrown by mock auth service for testing.
///
/// Mimics FirebaseAuthException structure with a [code] field
/// for error type identification.
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, [this.message = '']);

  @override
  String toString() => 'AuthException: $code - $message';
}
