import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

enum LoginMode {
  magicLink,    // Primary: email-only, passwordless
  emailPassword // Fallback: traditional email + password
}

class LoginScreen extends StatefulWidget {
  /// Optional email link for completing magic link sign-in
  final String? emailLink;

  const LoginScreen({super.key, this.emailLink});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  LoginMode _loginMode = LoginMode.magicLink;
  bool _isSignUp = false;
  String? _errorMessage;
  bool _magicLinkSent = false;

  @override
  void initState() {
    super.initState();
    // Check if we're returning from a magic link
    if (widget.emailLink != null) {
      _handleMagicLinkReturn();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleMagicLinkReturn() async {
    if (widget.emailLink == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if this is a valid sign-in link
      if (!_authService.isSignInLink(widget.emailLink!)) {
        setState(() {
          _errorMessage = 'Invalid sign-in link.';
          _isLoading = false;
        });
        return;
      }

      // Try to complete sign-in with stored email
      final credential = await _authService.signInWithMagicLink(widget.emailLink!);

      if (credential != null && mounted) {
        _navigateToHome();
      } else {
        // No stored email - need user to enter it
        final pendingEmail = await _authService.getPendingEmail();
        setState(() {
          _isLoading = false;
          if (pendingEmail != null) {
            _emailController.text = pendingEmail;
          }
          _errorMessage = 'Please enter your email to complete sign-in.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendMagicLink(email);
      setState(() {
        _magicLinkSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send sign-in link. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeMagicLinkSignIn() async {
    if (widget.emailLink == null) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithMagicLinkAndEmail(
        email: email,
        emailLink: widget.emailLink!,
      );
      if (mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'expired-action-code':
        return 'This link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This link is invalid. Please request a new one.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null && mounted) {
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email to reset password.';
      });
      return;
    }

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If magic link was sent, show confirmation screen
    if (_magicLinkSent) {
      return _buildMagicLinkSentScreen();
    }

    // If returning from magic link and need email
    if (widget.emailLink != null && !_isLoading) {
      return _buildCompleteSignInScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  Icon(
                    Icons.track_changes,
                    size: 64,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Archery Super App',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getSubtitle(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Email field (always shown)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Password field (only for email/password mode)
                  if (_loginMode == LoginMode.emailPassword) ...[
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (_isSignUp && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Primary action button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getPrimaryAction(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundDark,
                            ),
                          )
                        : Text(_getPrimaryButtonText()),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Google Sign In button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mode toggle
                  _buildModeToggle(),

                  // Sign up/in toggle (for email/password mode)
                  if (_loginMode == LoginMode.emailPassword) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Create one",
                      ),
                    ),
                    // Forgot password
                    if (!_isSignUp)
                      TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return TextButton(
      onPressed: () {
        setState(() {
          _loginMode = _loginMode == LoginMode.magicLink
              ? LoginMode.emailPassword
              : LoginMode.magicLink;
          _errorMessage = null;
        });
      },
      child: Text(
        _loginMode == LoginMode.magicLink
            ? 'Use password instead'
            : 'Use magic link instead',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  String _getSubtitle() {
    if (_loginMode == LoginMode.magicLink) {
      return 'Enter your email to receive a sign-in link';
    }
    return _isSignUp ? 'Create your account' : 'Sign in to continue';
  }

  String _getPrimaryButtonText() {
    if (_loginMode == LoginMode.magicLink) {
      return 'Send Sign-in Link';
    }
    return _isSignUp ? 'Create Account' : 'Sign In';
  }

  VoidCallback _getPrimaryAction() {
    if (_loginMode == LoginMode.magicLink) {
      return _sendMagicLink;
    }
    return _submitEmailPassword;
  }

  Widget _buildMagicLinkSentScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: AppColors.gold,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'We sent a sign-in link to',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _emailController.text.trim(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Click the link in the email to sign in.\nThe link expires in 1 hour.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _magicLinkSent = false;
                    });
                  },
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteSignInScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.link,
                  size: 64,
                  color: AppColors.gold,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Complete Sign In',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the email you used to request the sign-in link',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                ElevatedButton(
                  onPressed: _isLoading ? null : _completeMagicLinkSignIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundDark,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
