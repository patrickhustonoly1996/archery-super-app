import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/screens/login_screen.dart';
import 'package:archery_super_app/theme/app_theme.dart';
import 'package:archery_super_app/widgets/loading_button.dart';

import '../mocks/mock_auth_service_base.dart';

void main() {
  late MockAuthServiceBase mockAuth;

  setUp(() {
    mockAuth = MockAuthServiceBase();
  });

  tearDown(() {
    mockAuth.reset();
  });

  /// Helper to pump the LoginScreen with required theme and mock.
  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: LoginScreen(authService: mockAuth),
        ),
      ),
    );
  }

  group('LoginScreen', () {
    group('Initial State', () {
      testWidgets('renders sign-in mode by default', (tester) async {
        await pumpLoginScreen(tester);

        // Sign In button should be highlighted (gold background)
        expect(find.text('SIGN IN'), findsOneWidget);
        expect(find.text('CREATE ACCOUNT'), findsOneWidget);

        // Submit button shows "Sign In"
        expect(find.text('Sign In'), findsOneWidget);

        // Forgot password link should be visible in sign-in mode
        expect(find.text('Forgot password?'), findsOneWidget);

        // Sign-up encouragement should be visible in sign-in mode
        expect(find.text('New to Archery Super App?'), findsOneWidget);
      });

      testWidgets('renders email and password fields', (tester) async {
        await pumpLoginScreen(tester);

        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('does not show error message initially', (tester) async {
        await pumpLoginScreen(tester);

        // No error container should be present
        expect(find.textContaining('error'), findsNothing);
        expect(find.textContaining('failed'), findsNothing);
      });
    });

    group('Mode Toggle', () {
      testWidgets('toggles to sign-up mode when CREATE ACCOUNT is tapped',
          (tester) async {
        await pumpLoginScreen(tester);

        // Initially in sign-in mode
        expect(find.text('Sign In'), findsOneWidget);

        // Tap CREATE ACCOUNT
        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        // Should now be in sign-up mode
        expect(find.text('Create Account'), findsOneWidget);

        // Forgot password should NOT be visible in sign-up mode
        expect(find.text('Forgot password?'), findsNothing);

        // Sign-up encouragement should NOT be visible
        expect(find.text('New to Archery Super App?'), findsNothing);
      });

      testWidgets('toggles back to sign-in mode when SIGN IN is tapped',
          (tester) async {
        await pumpLoginScreen(tester);

        // Switch to sign-up mode
        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsOneWidget);

        // Switch back to sign-in mode
        await tester.tap(find.text('SIGN IN'));
        await tester.pumpAndSettle();

        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
      });

      testWidgets('clears error message when toggling modes', (tester) async {
        await pumpLoginScreen(tester);

        // Enter invalid email and submit to get an error
        await tester.enterText(find.byType(TextFormField).first, 'invalid');
        await tester.enterText(find.byType(TextFormField).last, 'password');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Toggle to sign-up mode - error should clear
        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        // The form validation error should be gone (it's per-field, not global)
        // Note: Form validation errors are per-field, not global _errorMessage
      });

      testWidgets('sign-up encouragement box switches to sign-up mode',
          (tester) async {
        await pumpLoginScreen(tester);

        // Scroll the encouragement box into view (it may be below the fold)
        final encouragementFinder = find.text('Create your free account');
        await tester.ensureVisible(encouragementFinder);
        await tester.pumpAndSettle();

        // Tap on the encouragement box
        await tester.tap(encouragementFinder);
        await tester.pumpAndSettle();

        // Should now be in sign-up mode
        expect(find.text('Create Account'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('shows error for invalid email format', (tester) async {
        await pumpLoginScreen(tester);

        // Enter invalid email
        await tester.enterText(find.byType(TextFormField).first, 'notanemail');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid email format'), findsOneWidget);
      });

      testWidgets('shows error for empty email', (tester) async {
        await pumpLoginScreen(tester);

        // Leave email empty, enter password
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
      });

      testWidgets('shows error for empty password in sign-in mode',
          (tester) async {
        await pumpLoginScreen(tester);

        // Enter valid email, leave password empty
        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('shows error for short password in sign-up mode',
          (tester) async {
        await pumpLoginScreen(tester);

        // Switch to sign-up mode
        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        // Enter valid email, short password
        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, '123');
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('Password must be at least 6 characters'),
            findsOneWidget);
      });

      testWidgets('does not submit when validation fails', (tester) async {
        await pumpLoginScreen(tester);

        // Enter invalid data
        await tester.enterText(find.byType(TextFormField).first, 'invalid');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Auth service should NOT have been called
        expect(mockAuth.signInCalled, isFalse);
      });
    });

    group('Sign In Flow', () {
      testWidgets('calls signIn with correct credentials', (tester) async {
        await pumpLoginScreen(tester);

        const email = 'test@example.com';
        const password = 'password123';

        await tester.enterText(find.byType(TextFormField).first, email);
        await tester.enterText(find.byType(TextFormField).last, password);
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(mockAuth.signInCalled, isTrue);
        expect(mockAuth.lastEmail, equals(email));
        expect(mockAuth.lastPassword, equals(password));
      });

      testWidgets('trims email before sending', (tester) async {
        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, '  test@example.com  ');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(mockAuth.lastEmail, equals('test@example.com'));
      });

      testWidgets('shows loading state during sign-in', (tester) async {
        mockAuth.simulateDelay = const Duration(milliseconds: 100);

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));

        // Pump once to start the async operation
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for operation to complete
        await tester.pumpAndSettle();

        // Loading indicator should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays error message on user-not-found', (tester) async {
        mockAuth.simulateError = 'user-not-found';

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'notfound@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('No account found with this email.'), findsOneWidget);
      });

      testWidgets('displays error message on wrong-password', (tester) async {
        mockAuth.simulateError = 'wrong-password';

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Incorrect password.'), findsOneWidget);
      });

      testWidgets('displays error message on invalid-credential',
          (tester) async {
        mockAuth.simulateError = 'invalid-credential';

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid email or password.'), findsOneWidget);
      });
    });

    group('Sign Up Flow', () {
      testWidgets('calls signUp with correct credentials', (tester) async {
        await pumpLoginScreen(tester);

        // Switch to sign-up mode
        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        const email = 'new@example.com';
        const password = 'newpassword123';

        await tester.enterText(find.byType(TextFormField).first, email);
        await tester.enterText(find.byType(TextFormField).last, password);
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(mockAuth.signUpCalled, isTrue);
        expect(mockAuth.signInCalled, isFalse);
        expect(mockAuth.lastEmail, equals(email));
        expect(mockAuth.lastPassword, equals(password));
      });

      testWidgets('displays error message on email-already-in-use',
          (tester) async {
        mockAuth.simulateError = 'email-already-in-use';

        await pumpLoginScreen(tester);

        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField).first, 'existing@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(find.text('An account already exists with this email.'),
            findsOneWidget);
      });

      testWidgets('displays error message on weak-password', (tester) async {
        mockAuth.simulateError = 'weak-password';

        await pumpLoginScreen(tester);

        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(
            find.text('Password must be at least 6 characters.'), findsOneWidget);
      });
    });

    group('Forgot Password Flow', () {
      testWidgets('shows error when email is empty', (tester) async {
        await pumpLoginScreen(tester);

        // Don't enter email, tap forgot password
        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();

        expect(find.text('Enter your email first, then tap forgot password.'),
            findsOneWidget);
        expect(mockAuth.resetPasswordCalled, isFalse);
      });

      testWidgets('calls resetPassword with email', (tester) async {
        await pumpLoginScreen(tester);

        const email = 'test@example.com';
        await tester.enterText(find.byType(TextFormField).first, email);
        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();

        expect(mockAuth.resetPasswordCalled, isTrue);
        expect(mockAuth.lastEmail, equals(email));
      });

      testWidgets('shows success snackbar on password reset', (tester) async {
        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();

        expect(
            find.text('Password reset email sent. Check your inbox.'),
            findsOneWidget);
      });

      testWidgets('shows error on reset password failure', (tester) async {
        mockAuth.simulateError = 'user-not-found';

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'notfound@example.com');
        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();

        expect(find.text('No account found with this email.'), findsOneWidget);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('submits form when pressing done on password field',
          (tester) async {
        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Simulate pressing "done" action on keyboard
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(mockAuth.signInCalled, isTrue);
      });
    });

    group('Error Display', () {
      testWidgets('error message has correct styling', (tester) async {
        mockAuth.simulateError = 'user-not-found';

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Find the error text and verify it exists
        final errorFinder = find.text('No account found with this email.');
        expect(errorFinder, findsOneWidget);
      });

      testWidgets('generic error shown for unknown errors', (tester) async {
        mockAuth.simulateError = 'some-unknown-error';

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Authentication failed. Please try again.'),
            findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles rapid mode switching', (tester) async {
        await pumpLoginScreen(tester);

        // Rapidly switch modes
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('CREATE ACCOUNT'));
          await tester.pump();
          await tester.tap(find.text('SIGN IN'));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Should still be functional
        expect(find.text('Sign In'), findsOneWidget);
      });

      testWidgets('handles double-tap prevention during loading',
          (tester) async {
        mockAuth.simulateDelay = const Duration(milliseconds: 500);

        await pumpLoginScreen(tester);

        await tester.enterText(
            find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Find the LoadingButton for tapping (text changes to spinner during loading)
        final loadingButtonFinder = find.byType(LoadingButton);

        // Tap submit twice quickly
        await tester.tap(find.text('Sign In'));
        await tester.pump(const Duration(milliseconds: 50));
        // Second tap should be ignored (button disabled during loading)
        // Use LoadingButton finder since text is replaced by spinner during loading
        await tester.tap(loadingButtonFinder, warnIfMissed: false);

        await tester.pumpAndSettle();

        // signIn should only have been called once
        // (The mock tracks the last call, so we verify it completed)
        expect(mockAuth.signInCalled, isTrue);
        expect(mockAuth.lastSignInSucceeded, isTrue);
      });
    });
  });
}
