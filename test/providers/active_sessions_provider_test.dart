/// Tests for ActiveSessionsProvider
///
/// Tests session persistence, resume logic, and state management
/// for the central active sessions tracking system.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archery_super_app/providers/active_sessions_provider.dart';

void main() {
  group('ActiveSessionsProvider', () {
    late ActiveSessionsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ActiveSessionsProvider();
    });

    group('ActiveSession', () {
      test('toJson serializes all fields', () {
        final session = ActiveSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'WA 720',
          subtitle: '70m',
          pausedAt: DateTime(2024, 1, 15, 10, 30),
          state: {'endNumber': 5, 'score': 250},
        );

        final json = session.toJson();

        expect(json['type'], equals(0)); // scoring index
        expect(json['id'], equals('session1'));
        expect(json['title'], equals('WA 720'));
        expect(json['subtitle'], equals('70m'));
        expect(json['pausedAt'], equals('2024-01-15T10:30:00.000'));
        expect(json['state']['endNumber'], equals(5));
        expect(json['state']['score'], equals(250));
      });

      test('fromJson deserializes all fields', () {
        final json = {
          'type': 1, // bowTraining
          'id': 'training1',
          'title': 'Session 1.5',
          'subtitle': 'In Progress',
          'pausedAt': '2024-01-15T14:00:00.000',
          'state': {'exerciseIndex': 3, 'remainingSeconds': 45},
        };

        final session = ActiveSession.fromJson(json);

        expect(session.type, equals(ActiveSessionType.bowTraining));
        expect(session.id, equals('training1'));
        expect(session.title, equals('Session 1.5'));
        expect(session.subtitle, equals('In Progress'));
        expect(session.pausedAt, equals(DateTime(2024, 1, 15, 14, 0)));
        expect(session.state['exerciseIndex'], equals(3));
        expect(session.state['remainingSeconds'], equals(45));
      });

      test('fromJson handles null subtitle', () {
        final json = {
          'type': 0,
          'id': 'session1',
          'title': 'Test',
          'subtitle': null,
          'pausedAt': '2024-01-15T10:00:00.000',
          'state': {},
        };

        final session = ActiveSession.fromJson(json);

        expect(session.subtitle, isNull);
      });
    });

    group('ActiveSessionType', () {
      test('all session types have unique indices', () {
        final indices = ActiveSessionType.values.map((t) => t.index).toSet();
        expect(indices.length, equals(ActiveSessionType.values.length));
      });

      test('scoring type has index 0', () {
        expect(ActiveSessionType.scoring.index, equals(0));
      });

      test('bowTraining type has index 1', () {
        expect(ActiveSessionType.bowTraining.index, equals(1));
      });

      test('breathHold type has index 2', () {
        expect(ActiveSessionType.breathHold.index, equals(2));
      });

      test('pacedBreathing type has index 3', () {
        expect(ActiveSessionType.pacedBreathing.index, equals(3));
      });

      test('patrickBreath type has index 4', () {
        expect(ActiveSessionType.patrickBreath.index, equals(4));
      });
    });

    group('Initial State', () {
      test('starts with no sessions', () {
        expect(provider.hasAnySessions, isFalse);
        expect(provider.sessions, isEmpty);
      });

      test('getSession returns null for empty provider', () {
        expect(provider.getSession(ActiveSessionType.scoring), isNull);
        expect(provider.getSession(ActiveSessionType.bowTraining), isNull);
      });

      test('hasSession returns false for all types initially', () {
        for (final type in ActiveSessionType.values) {
          expect(provider.hasSession(type), isFalse);
        }
      });
    });

    group('pauseSession', () {
      test('adds session to provider', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'WA 720',
          state: {'endNumber': 3},
        );

        expect(provider.hasAnySessions, isTrue);
        expect(provider.hasSession(ActiveSessionType.scoring), isTrue);
      });

      test('stores session details correctly', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'WA 720',
          subtitle: '70m Practice',
          state: {'endNumber': 3, 'score': 150},
        );

        final session = provider.getSession(ActiveSessionType.scoring);
        expect(session, isNotNull);
        expect(session!.id, equals('session1'));
        expect(session.title, equals('WA 720'));
        expect(session.subtitle, equals('70m Practice'));
        expect(session.state['endNumber'], equals(3));
        expect(session.state['score'], equals(150));
      });

      test('sets pausedAt to current time', () async {
        final before = DateTime.now();
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );
        final after = DateTime.now();

        final session = provider.getSession(ActiveSessionType.scoring);
        expect(session!.pausedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(session.pausedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('replaces existing session of same type', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'First',
          state: {'value': 1},
        );
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session2',
          title: 'Second',
          state: {'value': 2},
        );

        expect(provider.sessions.length, equals(1));
        final session = provider.getSession(ActiveSessionType.scoring);
        expect(session!.id, equals('session2'));
        expect(session.title, equals('Second'));
      });

      test('allows multiple sessions of different types', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'score1',
          title: 'Scoring',
          state: {},
        );
        await provider.pauseSession(
          type: ActiveSessionType.bowTraining,
          id: 'bow1',
          title: 'Bow Training',
          state: {},
        );
        await provider.pauseSession(
          type: ActiveSessionType.breathHold,
          id: 'breath1',
          title: 'Breath Hold',
          state: {},
        );

        expect(provider.sessions.length, equals(3));
        expect(provider.hasSession(ActiveSessionType.scoring), isTrue);
        expect(provider.hasSession(ActiveSessionType.bowTraining), isTrue);
        expect(provider.hasSession(ActiveSessionType.breathHold), isTrue);
      });

      test('notifies listeners', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        expect(notifyCount, equals(1));
      });
    });

    group('resumeSession', () {
      test('returns session data', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'WA 720',
          state: {'endNumber': 5},
        );

        final resumed = await provider.resumeSession(ActiveSessionType.scoring);

        expect(resumed, isNotNull);
        expect(resumed!.id, equals('session1'));
        expect(resumed.title, equals('WA 720'));
        expect(resumed.state['endNumber'], equals(5));
      });

      test('removes session from provider', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        await provider.resumeSession(ActiveSessionType.scoring);

        expect(provider.hasSession(ActiveSessionType.scoring), isFalse);
        expect(provider.hasAnySessions, isFalse);
      });

      test('returns null for non-existent session', () async {
        final resumed = await provider.resumeSession(ActiveSessionType.scoring);
        expect(resumed, isNull);
      });

      test('only removes specified type', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'score1',
          title: 'Scoring',
          state: {},
        );
        await provider.pauseSession(
          type: ActiveSessionType.bowTraining,
          id: 'bow1',
          title: 'Bow Training',
          state: {},
        );

        await provider.resumeSession(ActiveSessionType.scoring);

        expect(provider.hasSession(ActiveSessionType.scoring), isFalse);
        expect(provider.hasSession(ActiveSessionType.bowTraining), isTrue);
      });

      test('notifies listeners', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.resumeSession(ActiveSessionType.scoring);

        expect(notifyCount, equals(1));
      });

      test('does not notify listeners if session not found', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.resumeSession(ActiveSessionType.scoring);

        expect(notifyCount, equals(0));
      });
    });

    group('clearSession', () {
      test('removes specified session', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        await provider.clearSession(ActiveSessionType.scoring);

        expect(provider.hasSession(ActiveSessionType.scoring), isFalse);
      });

      test('only removes specified type', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'score1',
          title: 'Scoring',
          state: {},
        );
        await provider.pauseSession(
          type: ActiveSessionType.bowTraining,
          id: 'bow1',
          title: 'Bow Training',
          state: {},
        );

        await provider.clearSession(ActiveSessionType.scoring);

        expect(provider.hasSession(ActiveSessionType.scoring), isFalse);
        expect(provider.hasSession(ActiveSessionType.bowTraining), isTrue);
      });

      test('notifies listeners when session cleared', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.clearSession(ActiveSessionType.scoring);

        expect(notifyCount, equals(1));
      });

      test('does not notify if session not found', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.clearSession(ActiveSessionType.scoring);

        expect(notifyCount, equals(0));
      });
    });

    group('clearAllSessions', () {
      test('removes all sessions', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'score1',
          title: 'Scoring',
          state: {},
        );
        await provider.pauseSession(
          type: ActiveSessionType.bowTraining,
          id: 'bow1',
          title: 'Bow Training',
          state: {},
        );
        await provider.pauseSession(
          type: ActiveSessionType.breathHold,
          id: 'breath1',
          title: 'Breath Hold',
          state: {},
        );

        await provider.clearAllSessions();

        expect(provider.hasAnySessions, isFalse);
        expect(provider.sessions, isEmpty);
      });

      test('notifies listeners', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.clearAllSessions();

        expect(notifyCount, equals(1));
      });
    });

    group('Persistence', () {
      test('sessions persist across loadSessions calls', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'WA 720',
          subtitle: '70m',
          state: {'endNumber': 5, 'score': 250},
        );

        // Create new provider and load
        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        expect(newProvider.hasSession(ActiveSessionType.scoring), isTrue);
        final session = newProvider.getSession(ActiveSessionType.scoring);
        expect(session!.id, equals('session1'));
        expect(session.title, equals('WA 720'));
        expect(session.subtitle, equals('70m'));
        expect(session.state['endNumber'], equals(5));
      });

      test('multiple session types persist correctly', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'score1',
          title: 'Scoring',
          state: {'data': 1},
        );
        await provider.pauseSession(
          type: ActiveSessionType.bowTraining,
          id: 'bow1',
          title: 'Bow Training',
          state: {'data': 2},
        );

        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        expect(newProvider.sessions.length, equals(2));
        expect(newProvider.getSession(ActiveSessionType.scoring)!.id, equals('score1'));
        expect(newProvider.getSession(ActiveSessionType.bowTraining)!.id, equals('bow1'));
      });

      test('cleared sessions are removed from persistence', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );
        await provider.clearSession(ActiveSessionType.scoring);

        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        expect(newProvider.hasSession(ActiveSessionType.scoring), isFalse);
      });

      test('resumed sessions are removed from persistence', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );
        await provider.resumeSession(ActiveSessionType.scoring);

        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        expect(newProvider.hasSession(ActiveSessionType.scoring), isFalse);
      });

      test('loadSessions handles empty storage gracefully', () async {
        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        expect(newProvider.hasAnySessions, isFalse);
      });

      test('loadSessions notifies listeners', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        final newProvider = ActiveSessionsProvider();
        int notifyCount = 0;
        newProvider.addListener(() => notifyCount++);

        await newProvider.loadSessions();

        expect(notifyCount, equals(1));
      });
    });

    group('Static Helpers', () {
      test('getIconForType returns correct icons', () {
        expect(ActiveSessionsProvider.getIconForType(ActiveSessionType.scoring), equals('target'));
        expect(ActiveSessionsProvider.getIconForType(ActiveSessionType.bowTraining), equals('bow'));
        expect(ActiveSessionsProvider.getIconForType(ActiveSessionType.breathHold), equals('lungs'));
        expect(ActiveSessionsProvider.getIconForType(ActiveSessionType.pacedBreathing), equals('lungs'));
        expect(ActiveSessionsProvider.getIconForType(ActiveSessionType.patrickBreath), equals('lungs'));
      });

      test('getLabelForType returns correct labels', () {
        expect(ActiveSessionsProvider.getLabelForType(ActiveSessionType.scoring), equals('SCORE'));
        expect(ActiveSessionsProvider.getLabelForType(ActiveSessionType.bowTraining), equals('BOW DRILLS'));
        expect(ActiveSessionsProvider.getLabelForType(ActiveSessionType.breathHold), equals('BREATH HOLD'));
        expect(ActiveSessionsProvider.getLabelForType(ActiveSessionType.pacedBreathing), equals('PACED BREATHING'));
        expect(ActiveSessionsProvider.getLabelForType(ActiveSessionType.patrickBreath), equals('LONG EXHALE'));
      });
    });

    group('Sessions Map Immutability', () {
      test('sessions getter returns unmodifiable map', () async {
        // Add a session first
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Test',
          state: {},
        );

        // The sessions getter should return an unmodifiable view
        final sessions = provider.sessions;

        // Attempting to modify should throw
        expect(
          () => (sessions as Map<ActiveSessionType, ActiveSession?>)[ActiveSessionType.bowTraining] = sessions[ActiveSessionType.scoring],
          throwsUnsupportedError,
        );
      });
    });

    group('Complex State Objects', () {
      test('handles nested state objects', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Complex',
          state: {
            'nested': {
              'level1': {
                'level2': 'deep value',
              },
            },
            'list': [1, 2, 3],
          },
        );

        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        final session = newProvider.getSession(ActiveSessionType.scoring);
        expect(session!.state['nested']['level1']['level2'], equals('deep value'));
        expect(session.state['list'], equals([1, 2, 3]));
      });

      test('handles empty state object', () async {
        await provider.pauseSession(
          type: ActiveSessionType.scoring,
          id: 'session1',
          title: 'Empty State',
          state: {},
        );

        final newProvider = ActiveSessionsProvider();
        await newProvider.loadSessions();

        final session = newProvider.getSession(ActiveSessionType.scoring);
        expect(session!.state, isEmpty);
      });
    });
  });
}
