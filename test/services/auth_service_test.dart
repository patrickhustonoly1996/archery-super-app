/// Tests for MockAuthService
///
/// These tests verify the authentication service mock behavior,
/// which serves as both a test double and documentation of expected
/// authentication patterns.
import 'package:flutter_test/flutter_test.dart';
import '../mocks/mock_auth_service.dart';

void main() {
  group('MockAuthService', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    group('Initial State', () {
      test('starts with no current user', () {
        expect(authService.currentUser, isNull);
        expect(authService.userId, isNull);
      });

      test('isAuthenticated returns false initially', () {
        // Implicitly tested via currentUser being null
        expect(authService.currentUser == null, isTrue);
      });
    });

    group('Google Sign-In', () {
      test('signInWithGoogle returns user credential', () async {
        final result = await authService.signInWithGoogle();

        expect(result, isNotNull);
        expect(result!.user, isNotNull);
        expect(result.user!.email, equals('test@gmail.com'));
        expect(result.isNewUser, isTrue);
      });

      test('signInWithGoogle sets current user', () async {
        await authService.signInWithGoogle();

        expect(authService.currentUser, isNotNull);
        expect(authService.userId, isNotNull);
      });

      test('signInWithGoogle emits auth state change', () async {
        final states = <MockUser?>[];
        authService.authStateChanges.listen(states.add);

        await authService.signInWithGoogle();

        // Give stream time to emit
        await Future.delayed(const Duration(milliseconds: 10));
        expect(states, isNotEmpty);
        expect(states.last, isNotNull);
      });

      test('signInWithGoogle throws on network error', () async {
        authService.simulateNetworkError = true;

        expect(
          () => authService.signInWithGoogle(),
          throwsException,
        );
      });
    });

    group('Email/Password Sign-Up', () {
      test('signUp creates new user', () async {
        final result = await authService.signUp(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(result.user, isNotNull);
        expect(result.user!.email, equals('new@example.com'));
        expect(result.isNewUser, isTrue);
      });

      test('signUp sets current user', () async {
        await authService.signUp(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, equals('new@example.com'));
      });

      test('signUp throws on weak password', () async {
        expect(
          () => authService.signUp(
            email: 'new@example.com',
            password: '123', // Too short
          ),
          throwsException,
        );
      });

      test('signUp throws on email already in use', () async {
        await authService.signUp(
          email: 'existing@example.com',
          password: 'password123',
        );

        await authService.signOut();

        expect(
          () => authService.signUp(
            email: 'existing@example.com',
            password: 'differentPassword',
          ),
          throwsException,
        );
      });

      test('signUp throws on network error', () async {
        authService.simulateNetworkError = true;

        expect(
          () => authService.signUp(
            email: 'new@example.com',
            password: 'password123',
          ),
          throwsException,
        );
      });
    });

    group('Email/Password Sign-In', () {
      setUp(() {
        authService.registerUser('user@example.com', 'password123');
      });

      test('signIn with valid credentials succeeds', () async {
        final result = await authService.signIn(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(result.user, isNotNull);
        expect(result.user!.email, equals('user@example.com'));
      });

      test('signIn sets current user', () async {
        await authService.signIn(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(authService.currentUser, isNotNull);
      });

      test('signIn throws on invalid password', () async {
        expect(
          () => authService.signIn(
            email: 'user@example.com',
            password: 'wrongpassword',
          ),
          throwsException,
        );
      });

      test('signIn throws on user not found', () async {
        expect(
          () => authService.signIn(
            email: 'nonexistent@example.com',
            password: 'password123',
          ),
          throwsException,
        );
      });

      test('signIn throws on network error', () async {
        authService.simulateNetworkError = true;

        expect(
          () => authService.signIn(
            email: 'user@example.com',
            password: 'password123',
          ),
          throwsException,
        );
      });
    });

    group('Sign-Out', () {
      test('signOut clears current user', () async {
        await authService.signInWithGoogle();
        expect(authService.currentUser, isNotNull);

        await authService.signOut();

        expect(authService.currentUser, isNull);
        expect(authService.userId, isNull);
      });

      test('signOut emits null auth state', () async {
        final states = <MockUser?>[];
        authService.authStateChanges.listen(states.add);

        await authService.signInWithGoogle();
        await authService.signOut();

        await Future.delayed(const Duration(milliseconds: 10));
        expect(states.last, isNull);
      });
    });

    group('Password Reset', () {
      test('resetPassword completes without error', () async {
        // Should not throw
        await authService.resetPassword('user@example.com');
      });

      test('resetPassword throws on network error', () async {
        authService.simulateNetworkError = true;

        expect(
          () => authService.resetPassword('user@example.com'),
          throwsException,
        );
      });
    });

    group('Magic Link Authentication', () {
      test('sendMagicLink stores pending email', () async {
        await authService.sendMagicLink('magic@example.com');

        final pending = await authService.getPendingEmail();
        expect(pending, equals('magic@example.com'));
      });

      test('sendMagicLink throws on network error', () async {
        authService.simulateNetworkError = true;

        expect(
          () => authService.sendMagicLink('magic@example.com'),
          throwsException,
        );
      });

      test('isSignInLink returns true for valid links', () {
        expect(
          authService.isSignInLink('https://app.com?magic_link_token=abc123'),
          isTrue,
        );
      });

      test('isSignInLink returns false for invalid links', () {
        expect(
          authService.isSignInLink('https://app.com?other_param=value'),
          isFalse,
        );
      });

      test('signInWithMagicLink returns null without pending email', () async {
        final result = await authService.signInWithMagicLink(
          'https://app.com?magic_link_token=abc123',
        );

        expect(result, isNull);
      });

      test('signInWithMagicLink succeeds with pending email', () async {
        await authService.sendMagicLink('magic@example.com');

        final result = await authService.signInWithMagicLink(
          'https://app.com?magic_link_token=abc123',
        );

        expect(result, isNotNull);
        expect(result!.user!.email, equals('magic@example.com'));
      });

      test('signInWithMagicLink clears pending email', () async {
        await authService.sendMagicLink('magic@example.com');
        await authService.signInWithMagicLink(
          'https://app.com?magic_link_token=abc123',
        );

        final pending = await authService.getPendingEmail();
        expect(pending, isNull);
      });

      test('signInWithMagicLinkAndEmail succeeds', () async {
        final result = await authService.signInWithMagicLinkAndEmail(
          email: 'manual@example.com',
          emailLink: 'https://app.com?magic_link_token=abc123',
        );

        expect(result.user, isNotNull);
        expect(result.user!.email, equals('manual@example.com'));
      });

      test('clearPendingEmail removes stored email', () async {
        await authService.sendMagicLink('magic@example.com');
        await authService.clearPendingEmail();

        final pending = await authService.getPendingEmail();
        expect(pending, isNull);
      });
    });

    group('Auth State Changes', () {
      test('emits user on sign in', () async {
        final states = <MockUser?>[];
        final subscription = authService.authStateChanges.listen(states.add);

        await authService.signInWithGoogle();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(states.where((s) => s != null), isNotEmpty);
        await subscription.cancel();
      });

      test('emits null on sign out', () async {
        final states = <MockUser?>[];
        final subscription = authService.authStateChanges.listen(states.add);

        await authService.signInWithGoogle();
        await authService.signOut();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(states.last, isNull);
        await subscription.cancel();
      });
    });

    group('Test Helpers', () {
      test('createTestUser creates user without signing in', () {
        final user = authService.createTestUser(
          email: 'test@example.com',
          displayName: 'Test User',
        );

        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(authService.currentUser, isNull);
      });

      test('setCurrentUser directly sets user', () {
        final user = authService.createTestUser(email: 'test@example.com');
        authService.setCurrentUser(user);

        expect(authService.currentUser, equals(user));
      });

      test('resetErrors clears all error flags', () {
        authService.simulateNetworkError = true;
        authService.simulateInvalidCredentials = true;
        authService.simulateUserNotFound = true;

        authService.resetErrors();

        expect(authService.simulateNetworkError, isFalse);
        expect(authService.simulateInvalidCredentials, isFalse);
        expect(authService.simulateUserNotFound, isFalse);
      });

      test('clear resets all state', () async {
        await authService.signInWithGoogle();
        authService.simulateNetworkError = true;

        authService.clear();

        expect(authService.currentUser, isNull);
        expect(authService.simulateNetworkError, isFalse);
      });
    });
  });
}
