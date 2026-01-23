import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/scoring_timer_service.dart';

void main() {
  late ScoringTimerService service;

  setUp(() {
    service = ScoringTimerService();
    service.stop(); // Reset to idle state
  });

  tearDown(() {
    service.stop();
  });

  group('ScoringTimerService', () {
    test('starts in idle state', () {
      expect(service.state, equals(ScoringTimerState.idle));
      expect(service.isIdle, isTrue);
      expect(service.isRunning, isFalse);
    });

    test('configure sets lead-in and main duration', () {
      service.configure(leadInSeconds: 15, mainDurationSeconds: 180);
      expect(service.leadInSeconds, equals(15));
      expect(service.mainDurationSeconds, equals(180));
    });

    test('start transitions to leadIn state when lead-in configured', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();

      expect(service.state, equals(ScoringTimerState.leadIn));
      expect(service.secondsRemaining, equals(10));
      expect(service.isRunning, isTrue);
    });

    test('start transitions to running state when no lead-in', () {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 120);
      service.start();

      expect(service.state, equals(ScoringTimerState.running));
      expect(service.secondsRemaining, equals(120));
      expect(service.isRunning, isTrue);
    });

    test('stop resets to idle state', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();
      service.stop();

      expect(service.state, equals(ScoringTimerState.idle));
      expect(service.secondsRemaining, equals(0));
      expect(service.isIdle, isTrue);
    });

    test('displayTime shows lead-in seconds as single number', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();

      expect(service.displayTime, equals('10'));
    });

    test('displayTime shows MM:SS format for main timer', () {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 90);
      service.start();

      expect(service.displayTime, equals('01:30'));
    });

    test('displayTime handles 4 minute timer', () {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 240);
      service.start();

      expect(service.displayTime, equals('04:00'));
    });

    test('callbacks are triggered on tick', () async {
      service.configure(leadInSeconds: 1, mainDurationSeconds: 5);

      final states = <ScoringTimerState>[];
      final secondsList = <int>[];

      service.setCallbacks(
        onTick: (state, seconds) {
          states.add(state);
          secondsList.add(seconds);
        },
      );

      service.start();

      // Wait for first tick
      await Future.delayed(const Duration(milliseconds: 150));

      expect(states, isNotEmpty);
      expect(states.first, equals(ScoringTimerState.leadIn));
    });

    test('audio callback triggers on lead-in start', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);

      TimerAudioEvent? receivedEvent;
      service.setCallbacks(
        onAudio: (event) => receivedEvent = event,
      );

      service.start();

      expect(receivedEvent, equals(TimerAudioEvent.leadInStart));
    });

    test('audio callback triggers on main timer start without lead-in', () {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 120);

      TimerAudioEvent? receivedEvent;
      service.setCallbacks(
        onAudio: (event) => receivedEvent = event,
      );

      service.start();

      expect(receivedEvent, equals(TimerAudioEvent.mainTimerStart));
    });

    test('pause stops the timer', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();

      final secondsBefore = service.secondsRemaining;
      service.pause();

      // State should remain unchanged after pause
      expect(service.state, equals(ScoringTimerState.leadIn));
      expect(service.secondsRemaining, equals(secondsBefore));
    });

    test('resume continues the timer after pause', () async {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();

      service.pause();
      await Future.delayed(const Duration(milliseconds: 200));

      // Seconds should not have decreased during pause
      expect(service.secondsRemaining, equals(10));

      service.resume();
      expect(service.isRunning, isTrue);
    });

    test('singleton pattern returns same instance', () {
      final service1 = ScoringTimerService();
      final service2 = ScoringTimerService();

      expect(identical(service1, service2), isTrue);
    });

    test('reset is alias for stop', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();
      service.reset();

      expect(service.state, equals(ScoringTimerState.idle));
      expect(service.isIdle, isTrue);
    });

    test('start does nothing if already running', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.start();

      final stateBefore = service.state;
      service.start(); // Try to start again

      expect(service.state, equals(stateBefore));
    });

    test('resume does nothing if idle', () {
      service.configure(leadInSeconds: 10, mainDurationSeconds: 120);
      service.resume();

      expect(service.state, equals(ScoringTimerState.idle));
    });
  });

  group('Timer State Transitions', () {
    test('transitions from leadIn to running after lead-in completes', () async {
      service.configure(leadInSeconds: 1, mainDurationSeconds: 5);

      final audioEvents = <TimerAudioEvent>[];
      service.setCallbacks(
        onAudio: (event) => audioEvents.add(event),
      );

      service.start();
      expect(service.state, equals(ScoringTimerState.leadIn));

      // Wait for lead-in to complete (1 second + buffer)
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(service.state, equals(ScoringTimerState.running));
      expect(audioEvents, contains(TimerAudioEvent.mainTimerStart));
    });

    test('transitions to warning at 30 seconds remaining', () async {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 31);

      service.start();

      // Wait for 2 seconds to pass (31 - 2 = 29, which is <= 30)
      await Future.delayed(const Duration(milliseconds: 2100));

      expect(service.state, equals(ScoringTimerState.warning));
    });

    test('triggers 10-second warning audio', () async {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 11);

      final audioEvents = <TimerAudioEvent>[];
      service.setCallbacks(
        onAudio: (event) => audioEvents.add(event),
      );

      service.start();

      // Wait for 10 seconds warning (at 1 second elapsed, 10 remaining)
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(audioEvents, contains(TimerAudioEvent.tenSecWarning));
    });

    test('transitions to expired when time runs out', () async {
      service.configure(leadInSeconds: 0, mainDurationSeconds: 1);

      final audioEvents = <TimerAudioEvent>[];
      service.setCallbacks(
        onAudio: (event) => audioEvents.add(event),
      );

      service.start();

      // Wait for timer to expire
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(service.state, equals(ScoringTimerState.expired));
      expect(service.secondsRemaining, equals(0));
      expect(audioEvents, contains(TimerAudioEvent.timerExpired));
    });
  });
}
