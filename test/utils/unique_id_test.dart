import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/unique_id.dart';

void main() {
  group('UniqueId', () {
    group('generate', () {
      test('returns non-empty string', () {
        final id = UniqueId.generate();
        expect(id, isNotEmpty);
      });

      test('returns valid UUID v4 format', () {
        final id = UniqueId.generate();
        // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        // where x is any hex digit and y is one of 8, 9, a, or b
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(id), isTrue,
            reason: 'ID "$id" is not a valid UUID v4');
      });

      test('generates unique IDs in rapid succession', () {
        final ids = <String>{};

        // Generate 1000 IDs as fast as possible
        for (int i = 0; i < 1000; i++) {
          ids.add(UniqueId.generate());
        }

        // All should be unique
        expect(ids.length, equals(1000));
      });

      test('generates unique IDs across many calls', () {
        final ids = <String>{};

        for (int i = 0; i < 10000; i++) {
          final id = UniqueId.generate();
          expect(ids.contains(id), isFalse,
              reason: 'Duplicate ID generated: $id at iteration $i');
          ids.add(id);
        }
      });

      test('ID length is 36 characters (standard UUID)', () {
        final id = UniqueId.generate();
        expect(id.length, equals(36));
      });
    });

    group('withPrefix', () {
      test('prepends prefix to generated ID', () {
        final id = UniqueId.withPrefix('session');
        expect(id, startsWith('session_'));
      });

      test('contains valid UUID after prefix', () {
        final id = UniqueId.withPrefix('bow');
        final parts = id.split('_');
        expect(parts.length, equals(2));
        expect(parts[0], equals('bow'));

        // Check UUID format
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(parts[1]), isTrue,
            reason: 'UUID part "${parts[1]}" is not valid');
      });

      test('generates unique prefixed IDs', () {
        final ids = <String>{};

        for (int i = 0; i < 100; i++) {
          ids.add(UniqueId.withPrefix('test'));
        }

        expect(ids.length, equals(100));
      });

      test('different prefixes create different IDs', () {
        final id1 = UniqueId.withPrefix('session');
        final id2 = UniqueId.withPrefix('arrow');

        expect(id1, startsWith('session_'));
        expect(id2, startsWith('arrow_'));
        expect(id1, isNot(equals(id2)));
      });
    });

    group('ID Format', () {
      test('format is standard UUID v4', () {
        final id = UniqueId.generate();
        // UUID v4: 8-4-4-4-12 hex chars with dashes
        final regex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
        expect(regex.hasMatch(id), isTrue,
            reason: 'ID "$id" does not match UUID format');
      });

      test('prefixed format is prefix_uuid', () {
        final id = UniqueId.withPrefix('test');
        expect(id.startsWith('test_'), isTrue);
        final uuidPart = id.substring(5);
        final regex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
        expect(regex.hasMatch(uuidPart), isTrue,
            reason: 'UUID part "$uuidPart" does not match expected format');
      });
    });
  });
}
