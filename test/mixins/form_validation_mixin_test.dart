import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/mixins/form_validation_mixin.dart';

// Test class to use the mixin
class _TestClass with FormValidationMixin {}

void main() {
  late _TestClass validator;

  setUp(() {
    validator = _TestClass();
  });

  group('Email Validation', () {
    test('valid email passes', () {
      expect(validator.validateEmail('test@example.com'), null);
      expect(validator.validateEmail('user.name@domain.co.uk'), null);
      expect(validator.validateEmail('test+tag@gmail.com'), null);
    });

    test('invalid email format shows error', () {
      expect(validator.validateEmail('not-an-email'), 'Invalid email format');
      expect(validator.validateEmail('missing@domain'), 'Invalid email format');
      expect(validator.validateEmail('@domain.com'), 'Invalid email format');
      expect(validator.validateEmail('user@'), 'Invalid email format');
    });

    test('empty email shows required error', () {
      expect(validator.validateEmail(''), 'Email is required');
      expect(validator.validateEmail(null), 'Email is required');
    });
  });

  group('Required Field Validation', () {
    test('non-empty value passes', () {
      expect(validator.validateRequired('test'), null);
      expect(validator.validateRequired('  value  '), null);
    });

    test('empty value shows error', () {
      expect(
        validator.validateRequired(''),
        'This field is required',
      );
      expect(
        validator.validateRequired(null),
        'This field is required',
      );
      expect(
        validator.validateRequired('   '),
        'This field is required',
      );
    });

    test('custom field name in error message', () {
      expect(
        validator.validateRequired('', fieldName: 'Name'),
        'Name is required',
      );
      expect(
        validator.validateRequired(null, fieldName: 'Email'),
        'Email is required',
      );
    });
  });

  group('Number Validation', () {
    test('valid numbers pass', () {
      expect(validator.validateNumber('42'), null);
      expect(validator.validateNumber('3.14'), null);
      expect(validator.validateNumber('-10'), null);
      expect(validator.validateNumber('0'), null);
    });

    test('non-numeric values show error', () {
      expect(
        validator.validateNumber('not-a-number'),
        'This field must be a number',
      );
      expect(
        validator.validateNumber('12abc'),
        'This field must be a number',
      );
    });

    test('min/max bounds validation', () {
      expect(validator.validateNumber('5', min: 0, max: 10), null);
      expect(
        validator.validateNumber('15', max: 10),
        'This field must be at most 10.0',
      );
      expect(
        validator.validateNumber('-5', min: 0),
        'This field must be at least 0.0',
      );
    });

    test('allowEmpty parameter works', () {
      expect(validator.validateNumber('', allowEmpty: true), null);
      expect(
        validator.validateNumber('', allowEmpty: false),
        'This field is required',
      );
    });

    test('custom field name in error messages', () {
      expect(
        validator.validateNumber('abc', fieldName: 'Age'),
        'Age must be a number',
      );
      expect(
        validator.validateNumber('15', fieldName: 'Score', max: 10),
        'Score must be at most 10.0',
      );
    });
  });

  group('Password Validation', () {
    test('valid passwords pass', () {
      expect(validator.validatePassword('12345678'), null);
      expect(validator.validatePassword('password123'), null);
      expect(validator.validatePassword('P@ssw0rd!'), null);
    });

    test('short passwords show error', () {
      expect(
        validator.validatePassword('1234567'),
        'Password must be at least 8 characters',
      );
      expect(
        validator.validatePassword('short'),
        'Password must be at least 8 characters',
      );
    });

    test('custom minimum length', () {
      expect(validator.validatePassword('123456', minLength: 6), null);
      expect(
        validator.validatePassword('12345', minLength: 6),
        'Password must be at least 6 characters',
      );
    });

    test('empty password shows error', () {
      expect(validator.validatePassword(''), 'Password is required');
      expect(validator.validatePassword(null), 'Password is required');
    });
  });

  group('Integer Validation', () {
    test('valid integers pass', () {
      expect(validator.validateInteger('42'), null);
      expect(validator.validateInteger('-10'), null);
      expect(validator.validateInteger('0'), null);
    });

    test('decimal numbers show error', () {
      expect(
        validator.validateInteger('3.14'),
        'This field must be a whole number',
      );
    });

    test('min/max bounds validation', () {
      expect(validator.validateInteger('5', min: 0, max: 10), null);
      expect(
        validator.validateInteger('15', max: 10),
        'This field must be at most 10',
      );
      expect(
        validator.validateInteger('-5', min: 0),
        'This field must be at least 0',
      );
    });
  });

  group('Password Confirmation', () {
    test('matching passwords pass', () {
      expect(
        validator.validatePasswordConfirmation('password123', 'password123'),
        null,
      );
    });

    test('non-matching passwords show error', () {
      expect(
        validator.validatePasswordConfirmation('password1', 'password2'),
        'Passwords do not match',
      );
    });

    test('empty confirmation shows error', () {
      expect(
        validator.validatePasswordConfirmation('', 'password123'),
        'Please confirm your password',
      );
      expect(
        validator.validatePasswordConfirmation(null, 'password123'),
        'Please confirm your password',
      );
    });
  });

  group('Length Validation', () {
    test('valid lengths pass', () {
      expect(validator.validateLength('test'), null);
      expect(validator.validateLength('test', minLength: 4, maxLength: 10), null);
    });

    test('min/max length validation', () {
      expect(
        validator.validateLength('ab', minLength: 3),
        'This field must be at least 3 characters',
      );
      expect(
        validator.validateLength('toolongstring', maxLength: 10),
        'This field must be at most 10 characters',
      );
    });

    test('allowEmpty parameter works', () {
      expect(validator.validateLength('', allowEmpty: true), null);
      expect(
        validator.validateLength('', allowEmpty: false),
        'This field is required',
      );
    });
  });

  group('Composed Validators', () {
    test('all validators pass', () {
      expect(
        validator.validateComposed('test@example.com', [
          validator.validateEmail,
          (value) => validator.validateLength(value, minLength: 5),
        ]),
        null,
      );
    });

    test('returns first error found', () {
      expect(
        validator.validateComposed('', [
          (value) => validator.validateRequired(value, fieldName: 'Email'),
          validator.validateEmail,
        ]),
        'Email is required',
      );

      expect(
        validator.validateComposed('not-an-email', [
          (value) => validator.validateRequired(value, fieldName: 'Email'),
          validator.validateEmail,
        ]),
        'Invalid email format',
      );
    });
  });
}
