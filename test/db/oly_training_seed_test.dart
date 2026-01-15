import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/oly_training_seed.dart';

void main() {
  group('OlyTrainingSeed', () {
    group('Exercise Types', () {
      late List<dynamic> exerciseTypes;

      setUpAll(() {
        exerciseTypes = getOlyExerciseTypesSeed();
      });

      test('returns non-empty list', () {
        expect(exerciseTypes, isNotEmpty);
      });

      test('all exercise types have unique IDs', () {
        final ids = exerciseTypes.map((e) => e.id.value).toSet();
        expect(ids.length, equals(exerciseTypes.length));
      });

      test('all exercise types have names', () {
        for (final exercise in exerciseTypes) {
          expect(exercise.name.value, isNotEmpty);
        }
      });

      test('has expected exercise types', () {
        final ids = exerciseTypes.map((e) => e.id.value).toSet();
        // Should have at least some core exercise types
        expect(ids.length, greaterThan(3));
      });
    });

    group('Session Templates', () {
      late List<OlySessionSeed> sessions;

      setUpAll(() {
        sessions = getOlySessionTemplatesSeed();
      });

      test('returns non-empty list', () {
        expect(sessions, isNotEmpty);
      });

      test('all sessions have unique IDs', () {
        final ids = sessions.map((s) => s.template.id.value).toSet();
        expect(ids.length, equals(sessions.length));
      });

      test('all sessions have names', () {
        for (final session in sessions) {
          expect(session.template.name.value, isNotEmpty);
        }
      });

      test('all sessions have exercises', () {
        for (final session in sessions) {
          expect(
            session.exercises,
            isNotEmpty,
            reason: '${session.template.id.value} has no exercises',
          );
        }
      });

      test('sessions have positive duration', () {
        for (final session in sessions) {
          expect(
            session.template.durationMinutes.value,
            greaterThan(0),
            reason: '${session.template.id.value} has invalid duration',
          );
        }
      });
    });
  });
}
