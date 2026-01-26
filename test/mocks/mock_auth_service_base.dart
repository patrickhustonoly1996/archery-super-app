/// Mock authentication service implementing AuthServiceBase for widget testing.
///
/// This mock is specifically designed for testing the LoginScreen widget.
/// It allows tests to:
/// - Simulate successful sign-in/sign-up
/// - Simulate various error conditions
/// - Track method calls and arguments
library;

import 'package:archery_super_app/services/auth_service_base.dart';

/// Mock authentication service for widget testing.
///
/// Use [simulateError] to make the next auth call throw an [AuthException].
/// Use [signInCalled], [signUpCalled], etc. to verify method calls.
class MockAuthServiceBase implements AuthServiceBase {
  // Call tracking
  bool signInCalled = false;
  bool signUpCalled = false;
  bool signOutCalled = false;
  bool resetPasswordCalled = false;

  String? lastEmail;
  String? lastPassword;

  // Error simulation - set to non-null to simulate an error
  String? simulateError;

  // Delay simulation for loading states
  Duration? simulateDelay;

  // Track successful completions
  bool lastSignInSucceeded = false;
  bool lastSignUpSucceeded = false;

  void reset() {
    signInCalled = false;
    signUpCalled = false;
    signOutCalled = false;
    resetPasswordCalled = false;
    lastEmail = null;
    lastPassword = null;
    simulateError = null;
    simulateDelay = null;
    lastSignInSucceeded = false;
    lastSignUpSucceeded = false;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastEmail = email;
    lastPassword = password;

    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }

    if (simulateError != null) {
      final error = simulateError!;
      simulateError = null; // Clear after throwing
      throw AuthException(error);
    }

    lastSignInSucceeded = true;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalled = true;
    lastEmail = email;
    lastPassword = password;

    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }

    if (simulateError != null) {
      final error = simulateError!;
      simulateError = null; // Clear after throwing
      throw AuthException(error);
    }

    lastSignUpSucceeded = true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;

    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }

    if (simulateError != null) {
      final error = simulateError!;
      simulateError = null;
      throw AuthException(error);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    resetPasswordCalled = true;
    lastEmail = email;

    if (simulateDelay != null) {
      await Future.delayed(simulateDelay!);
    }

    if (simulateError != null) {
      final error = simulateError!;
      simulateError = null;
      throw AuthException(error);
    }
  }
}
