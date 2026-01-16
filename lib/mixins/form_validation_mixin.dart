/// Form validation mixin providing common validators for Flutter forms.
///
/// Provides reusable validators that return error messages or null if valid.
/// All validators support inline validation (as user types).
///
/// Usage:
/// ```dart
/// class _MyFormState extends State<MyForm> with FormValidationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return TextFormField(
///       validator: validateEmail,
///       autovalidateMode: AutovalidateMode.onUserInteraction,
///     );
///   }
/// }
/// ```
mixin FormValidationMixin {
  /// Validate email format.
  /// Returns error message or null if valid.
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Basic email regex that covers most common formats
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    return null;
  }

  /// Validate that a field is not empty.
  /// [fieldName] is used in the error message for clarity.
  String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate a numeric value with optional min/max bounds.
  /// Returns error message or null if valid.
  String? validateNumber(
    String? value, {
    String fieldName = 'This field',
    double? min,
    double? max,
    bool allowEmpty = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  /// Validate an integer value with optional min/max bounds.
  String? validateInteger(
    String? value, {
    String fieldName = 'This field',
    int? min,
    int? max,
    bool allowEmpty = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a whole number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  /// Validate password with minimum length requirement.
  /// Default minimum is 8 characters.
  String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  /// Validate that password confirmation matches the original.
  String? validatePasswordConfirmation(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate text length within bounds.
  String? validateLength(
    String? value, {
    String fieldName = 'This field',
    int? minLength,
    int? maxLength,
    bool allowEmpty = false,
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : '$fieldName is required';
    }

    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }

    return null;
  }

  /// Combine multiple validators into one.
  /// Returns the first error found, or null if all pass.
  String? validateComposed(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
