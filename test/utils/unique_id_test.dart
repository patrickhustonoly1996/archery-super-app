import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/unique_id.dart';

void main() {
  group('UniqueId', () {
    group('generate', () {
      test('returns non-empty string', () {
        final id = UniqueId.generate();
        expect(id, isNotEmpty);
      });

      test('contains underscore separator', () {
        final id = UniqueId.generate();
        expect(id, contains('_'));
      });

      test('starts with timestamp', () {
        final before = DateTime.now().millisecondsSinceEpoch;
        final id = UniqueId.generate();
        final after = DateTime.now().millisecondsSinceEpoch;

        final parts = id.split('_');
        expect(parts.length, equals(3)); // timestamp_counter_random

        final timestamp = int.tryParse(parts[0]);
        expect(timestamp, isNotNull);
        expect(timestamp, greaterThanOrEqualTo(before));
        expect(timestamp, lessThanOrEqualTo(after));
      });

      test('has counter and random suffix', () {
        final id = UniqueId.generate();
        final parts = id.split('_');
        expect(parts.length, equals(3)); // timestamp_counter_random

        // Counter part
        expect(parts[1].length, equals(3));
        final counter = int.tryParse(parts[1]);
        expect(counter, isNotNull);
        expect(counter, greaterThanOrEqualTo(0));

        // Random suffix part
        expect(parts[2].length, equals(4));
        final suffix = int.tryParse(parts[2]);
        expect(suffix, isNotNull);
        expect(suffix, greaterThanOrEqualTo(0));
        expect(suffix, lessThan(10000));
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
    });

    group('withPrefix', () {
      test('prepends prefix to generated ID', () {
        final id = UniqueId.withPrefix('session');
        expect(id, startsWith('session_'));
      });

      test('contains three underscores (prefix + timestamp + counter)', () {
        final id = UniqueId.withPrefix('bow');
        final underscoreCount = '_'.allMatches(id).length;
        expect(underscoreCount, equals(3));
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
      test('format is timestamp_counter_random', () {
        final id = UniqueId.generate();
        final regex = RegExp(r'^\d{13}_\d{3}_\d{4}$');
        expect(regex.hasMatch(id), isTrue,
            reason: 'ID "$id" does not match expected format');
      });

      test('prefixed format is prefix_timestamp_counter_random', () {
        final id = UniqueId.withPrefix('test');
        final regex = RegExp(r'^test_\d{13}_\d{3}_\d{4}$');
        expect(regex.hasMatch(id), isTrue,
            reason: 'ID "$id" does not match expected format');
      });
    });
  });
}
