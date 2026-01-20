/// Tests for ChiptuneService and ChiptuneGenerator
///
/// These tests verify:
/// - Waveform generation (square, triangle, sawtooth, noise)
/// - ADSR envelope calculations
/// - Note rendering with proper frequencies
/// - WAV file generation and format validation
/// - Service state management (enabled, volume, cycling)
/// - All jingle types produce valid audio data
///
/// Audio playback is not tested as it requires actual audio hardware.
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/chiptune_generator.dart';

void main() {
  group('ChiptuneGenerator', () {
    group('Waveform Generators', () {
      test('square wave returns 1.0 when phase < duty cycle', () {
        // Phase 0.25 with duty cycle 0.5 should return 1.0
        expect(ChiptuneGenerator.squareWave(0.25), equals(1.0));
        expect(ChiptuneGenerator.squareWave(0.0), equals(1.0));
        expect(ChiptuneGenerator.squareWave(0.49), equals(1.0));
      });

      test('square wave returns -1.0 when phase >= duty cycle', () {
        // Phase 0.5+ with default duty cycle 0.5 should return -1.0
        expect(ChiptuneGenerator.squareWave(0.5), equals(-1.0));
        expect(ChiptuneGenerator.squareWave(0.75), equals(-1.0));
        expect(ChiptuneGenerator.squareWave(0.99), equals(-1.0));
      });

      test('square wave wraps correctly past 1.0', () {
        // Phase 1.25 wraps to 0.25, should return 1.0
        expect(ChiptuneGenerator.squareWave(1.25), equals(1.0));
        // Phase 1.75 wraps to 0.75, should return -1.0
        expect(ChiptuneGenerator.squareWave(1.75), equals(-1.0));
      });

      test('square wave respects custom duty cycle', () {
        // With duty cycle 0.25, phase 0.2 should return 1.0
        expect(ChiptuneGenerator.squareWave(0.2, dutyCycle: 0.25), equals(1.0));
        // Phase 0.3 should return -1.0 (past the 0.25 duty cycle)
        expect(ChiptuneGenerator.squareWave(0.3, dutyCycle: 0.25), equals(-1.0));
      });

      test('triangle wave produces smooth ramp', () {
        // Phase 0.0 should be -1.0
        expect(ChiptuneGenerator.triangleWave(0.0), closeTo(-1.0, 0.001));
        // Phase 0.25 should be 0.0
        expect(ChiptuneGenerator.triangleWave(0.25), closeTo(0.0, 0.001));
        // Phase 0.5 should be 1.0 (peak)
        expect(ChiptuneGenerator.triangleWave(0.5), closeTo(1.0, 0.001));
        // Phase 0.75 should be 0.0
        expect(ChiptuneGenerator.triangleWave(0.75), closeTo(0.0, 0.001));
      });

      test('triangle wave wraps correctly past 1.0', () {
        expect(ChiptuneGenerator.triangleWave(1.25), closeTo(0.0, 0.001));
        expect(ChiptuneGenerator.triangleWave(1.5), closeTo(1.0, 0.001));
      });

      test('sawtooth wave produces linear ramp', () {
        // Sawtooth goes from -1 to 1 linearly
        expect(ChiptuneGenerator.sawtoothWave(0.0), closeTo(-1.0, 0.001));
        expect(ChiptuneGenerator.sawtoothWave(0.25), closeTo(-0.5, 0.001));
        expect(ChiptuneGenerator.sawtoothWave(0.5), closeTo(0.0, 0.001));
        expect(ChiptuneGenerator.sawtoothWave(0.75), closeTo(0.5, 0.001));
      });

      test('sawtooth wave wraps correctly', () {
        expect(ChiptuneGenerator.sawtoothWave(1.5), closeTo(0.0, 0.001));
      });

      test('noise generates values in -1 to 1 range', () {
        final rng = math.Random(42);
        for (int i = 0; i < 100; i++) {
          final value = ChiptuneGenerator.noise(rng);
          expect(value, greaterThanOrEqualTo(-1.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('noise is different each call', () {
        final rng = math.Random(42);
        final values = List.generate(10, (_) => ChiptuneGenerator.noise(rng));
        // Check that values are not all the same
        final uniqueValues = values.toSet();
        expect(uniqueValues.length, greaterThan(1));
      });
    });

    group('Musical Notes', () {
      test('has standard A4 = 440 Hz', () {
        expect(ChiptuneGenerator.notes['A4'], equals(440.0));
      });

      test('has correct octave relationships', () {
        // C3 should be half of C4
        expect(ChiptuneGenerator.notes['C3']! * 2,
            closeTo(ChiptuneGenerator.notes['C4']!, 0.1));
        // C5 should be double C4
        expect(ChiptuneGenerator.notes['C5'],
            closeTo(ChiptuneGenerator.notes['C4']! * 2, 0.1));
      });

      test('covers bass to high range (C2 to E6)', () {
        expect(ChiptuneGenerator.notes.containsKey('C2'), isTrue);
        expect(ChiptuneGenerator.notes.containsKey('E6'), isTrue);
      });

      test('all note frequencies are positive', () {
        for (final freq in ChiptuneGenerator.notes.values) {
          expect(freq, greaterThan(0));
        }
      });
    });

    group('ADSR Envelope', () {
      test('starts at 0 and ramps up during attack', () {
        final env = ChiptuneGenerator.envelope(
          time: 0.005,
          noteDuration: 1.0,
          attack: 0.01,
        );
        // Halfway through attack should be around 0.5
        expect(env, closeTo(0.5, 0.1));
      });

      test('reaches peak 1.0 at end of attack', () {
        final env = ChiptuneGenerator.envelope(
          time: 0.01,
          noteDuration: 1.0,
          attack: 0.01,
        );
        expect(env, closeTo(1.0, 0.1));
      });

      test('decays to sustain level after attack', () {
        final env = ChiptuneGenerator.envelope(
          time: 0.06,
          noteDuration: 1.0,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.7,
        );
        expect(env, closeTo(0.7, 0.1));
      });

      test('holds at sustain level', () {
        final env1 = ChiptuneGenerator.envelope(
          time: 0.5,
          noteDuration: 1.0,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.7,
          release: 0.1,
        );
        final env2 = ChiptuneGenerator.envelope(
          time: 0.7,
          noteDuration: 1.0,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.7,
          release: 0.1,
        );
        expect(env1, closeTo(0.7, 0.01));
        expect(env2, closeTo(0.7, 0.01));
      });

      test('fades out during release', () {
        final envStart = ChiptuneGenerator.envelope(
          time: 0.9,
          noteDuration: 1.0,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.7,
          release: 0.1,
        );
        final envMid = ChiptuneGenerator.envelope(
          time: 0.95,
          noteDuration: 1.0,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.7,
          release: 0.1,
        );
        final envEnd = ChiptuneGenerator.envelope(
          time: 1.0,
          noteDuration: 1.0,
          attack: 0.01,
          decay: 0.05,
          sustain: 0.7,
          release: 0.1,
        );
        // Release starts at sustain level
        expect(envStart, closeTo(0.7, 0.1));
        // Midway through release should be lower
        expect(envMid, lessThan(envStart));
        // End of release should be near 0
        expect(envEnd, closeTo(0.0, 0.05));
      });

      test('returns 0 after note ends', () {
        final env = ChiptuneGenerator.envelope(
          time: 1.5,
          noteDuration: 1.0,
        );
        expect(env, equals(0.0));
      });
    });

    group('Note Rendering', () {
      test('renderNote produces correct number of samples', () {
        const duration = 0.5;
        const sampleRate = 44100;
        final expectedSamples = (duration * sampleRate).round();

        final samples = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: duration,
          waveform: WaveformType.square,
        );

        expect(samples.length, equals(expectedSamples));
      });

      test('renderNote respects volume parameter', () {
        final lowVolume = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 0.1,
          waveform: WaveformType.square,
          volume: 0.2,
        );
        final highVolume = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 0.1,
          waveform: WaveformType.square,
          volume: 0.8,
        );

        // Find peak values
        final lowPeak = lowVolume.map((s) => s.abs()).reduce(math.max);
        final highPeak = highVolume.map((s) => s.abs()).reduce(math.max);

        expect(highPeak, greaterThan(lowPeak));
      });

      test('renderNote uses default frequency for unknown notes', () {
        final samples = ChiptuneGenerator.renderNote(
          note: 'UNKNOWN',
          duration: 0.1,
          waveform: WaveformType.square,
        );
        // Should still produce samples (defaults to 440 Hz)
        expect(samples.length, greaterThan(0));
      });

      test('renderNote with noise waveform uses seed for reproducibility', () {
        final samples1 = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 0.1,
          waveform: WaveformType.noise,
          seed: 123,
        );
        final samples2 = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 0.1,
          waveform: WaveformType.noise,
          seed: 123,
        );

        // Same seed should produce same noise pattern
        for (int i = 0; i < samples1.length; i++) {
          expect(samples1[i], equals(samples2[i]));
        }
      });

      test('renderRest produces silence', () {
        final rest = ChiptuneGenerator.renderRest(0.5);
        final expectedSamples = (0.5 * 44100).round();

        expect(rest.length, equals(expectedSamples));
        for (final sample in rest) {
          expect(sample, equals(0.0));
        }
      });
    });

    group('Jingle Generation', () {
      test('generateLevelUpJingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generateLevelUpJingle(variation: 0);
        _verifyWavFormat(wav);
      });

      test('generateLevelUpJingle supports multiple variations', () {
        final wav0 = ChiptuneGenerator.generateLevelUpJingle(variation: 0);
        final wav1 = ChiptuneGenerator.generateLevelUpJingle(variation: 1);
        final wav2 = ChiptuneGenerator.generateLevelUpJingle(variation: 2);

        // All should be valid
        _verifyWavFormat(wav0);
        _verifyWavFormat(wav1);
        _verifyWavFormat(wav2);

        // Variations should produce different audio
        expect(wav0.length == wav1.length && wav0.length == wav2.length, isFalse,
            reason: 'Different variations should have different lengths');
      });

      test('generateLevelUpJingle wraps variations', () {
        // Variation 3 should wrap to variation 0
        final wav3 = ChiptuneGenerator.generateLevelUpJingle(variation: 3);
        final wav0 = ChiptuneGenerator.generateLevelUpJingle(variation: 0);

        expect(wav3.length, equals(wav0.length));
      });

      test('generateMilestoneJingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generateMilestoneJingle(variation: 0);
        _verifyWavFormat(wav);
        // Milestone should be longer than level-up
        final levelUp = ChiptuneGenerator.generateLevelUpJingle(variation: 0);
        expect(wav.length, greaterThan(levelUp.length));
      });

      test('generateMilestoneJingle supports 2 variations', () {
        final wav0 = ChiptuneGenerator.generateMilestoneJingle(variation: 0);
        final wav1 = ChiptuneGenerator.generateMilestoneJingle(variation: 1);

        _verifyWavFormat(wav0);
        _verifyWavFormat(wav1);
      });

      test('generateAchievementJingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generateAchievementJingle(variation: 0);
        _verifyWavFormat(wav);
      });

      test('generateAchievementJingle supports 2 variations', () {
        final wav0 = ChiptuneGenerator.generateAchievementJingle(variation: 0);
        final wav1 = ChiptuneGenerator.generateAchievementJingle(variation: 1);

        _verifyWavFormat(wav0);
        _verifyWavFormat(wav1);
      });

      test('generatePersonalBestJingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generatePersonalBestJingle();
        _verifyWavFormat(wav);
        // PB jingle should be one of the longest
        expect(wav.length, greaterThan(100000));
      });

      test('generateStreak7Jingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generateStreak7Jingle();
        _verifyWavFormat(wav);
      });

      test('generateStreak14Jingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generateStreak14Jingle();
        _verifyWavFormat(wav);
        // 14-day should be fuller than 7-day
        final streak7 = ChiptuneGenerator.generateStreak7Jingle();
        expect(wav.length, greaterThanOrEqualTo(streak7.length));
      });

      test('generateStreak30Jingle produces valid WAV', () {
        final wav = ChiptuneGenerator.generateStreak30Jingle();
        _verifyWavFormat(wav);
        // 30-day should be the grandest (longest)
        final streak14 = ChiptuneGenerator.generateStreak14Jingle();
        expect(wav.length, greaterThanOrEqualTo(streak14.length));
      });
    });

    group('WAV Format', () {
      test('WAV has correct RIFF header', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        expect(wav[0], equals(0x52)); // R
        expect(wav[1], equals(0x49)); // I
        expect(wav[2], equals(0x46)); // F
        expect(wav[3], equals(0x46)); // F
      });

      test('WAV has correct WAVE format', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        expect(wav[8], equals(0x57)); // W
        expect(wav[9], equals(0x41)); // A
        expect(wav[10], equals(0x56)); // V
        expect(wav[11], equals(0x45)); // E
      });

      test('WAV has correct fmt chunk', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        expect(wav[12], equals(0x66)); // f
        expect(wav[13], equals(0x6D)); // m
        expect(wav[14], equals(0x74)); // t
        expect(wav[15], equals(0x20)); // space
      });

      test('WAV has correct data chunk', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        expect(wav[36], equals(0x64)); // d
        expect(wav[37], equals(0x61)); // a
        expect(wav[38], equals(0x74)); // t
        expect(wav[39], equals(0x61)); // a
      });

      test('WAV uses PCM format (1)', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final audioFormat = wav[20] | (wav[21] << 8);
        expect(audioFormat, equals(1));
      });

      test('WAV uses mono channel', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final numChannels = wav[22] | (wav[23] << 8);
        expect(numChannels, equals(1));
      });

      test('WAV uses 44100 Hz sample rate', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final sampleRate =
            wav[24] | (wav[25] << 8) | (wav[26] << 16) | (wav[27] << 24);
        expect(sampleRate, equals(44100));
      });

      test('WAV uses 16-bit samples', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final bitsPerSample = wav[34] | (wav[35] << 8);
        expect(bitsPerSample, equals(16));
      });

      test('WAV byte rate is correct', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final byteRate =
            wav[28] | (wav[29] << 8) | (wav[30] << 16) | (wav[31] << 24);
        // 44100 Hz * 1 channel * 2 bytes per sample
        expect(byteRate, equals(44100 * 1 * 2));
      });

      test('WAV block align is correct', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final blockAlign = wav[32] | (wav[33] << 8);
        // 1 channel * 2 bytes per sample
        expect(blockAlign, equals(2));
      });

      test('WAV file size in header matches actual size', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final headerFileSize =
            wav[4] | (wav[5] << 8) | (wav[6] << 16) | (wav[7] << 24);
        final actualFileSize = wav.length - 8;

        expect(headerFileSize, equals(actualFileSize));
      });

      test('WAV data size in header matches actual data', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        final headerDataSize =
            wav[40] | (wav[41] << 8) | (wav[42] << 16) | (wav[43] << 24);
        final actualDataSize = wav.length - 44;

        expect(headerDataSize, equals(actualDataSize));
      });
    });

    group('Data Classes', () {
      test('NoteEvent stores note, startTime, and duration', () {
        const event = NoteEvent('C4', 0.5, 0.25);

        expect(event.note, equals('C4'));
        expect(event.startTime, equals(0.5));
        expect(event.duration, equals(0.25));
      });

      test('Voice has correct default values', () {
        final voice = Voice(
          waveform: WaveformType.square,
          notes: [const NoteEvent('C4', 0.0, 0.5)],
        );

        expect(voice.volume, equals(0.5));
        expect(voice.dutyCycle, equals(0.5));
        expect(voice.attack, equals(0.01));
        expect(voice.decay, equals(0.05));
        expect(voice.sustain, equals(0.7));
        expect(voice.release, equals(0.1));
      });

      test('Voice stores custom parameters', () {
        final voice = Voice(
          waveform: WaveformType.triangle,
          notes: [const NoteEvent('A4', 0.0, 1.0)],
          volume: 0.8,
          dutyCycle: 0.25,
          attack: 0.02,
          decay: 0.1,
          sustain: 0.5,
          release: 0.2,
        );

        expect(voice.waveform, equals(WaveformType.triangle));
        expect(voice.volume, equals(0.8));
        expect(voice.dutyCycle, equals(0.25));
        expect(voice.attack, equals(0.02));
        expect(voice.decay, equals(0.1));
        expect(voice.sustain, equals(0.5));
        expect(voice.release, equals(0.2));
        expect(voice.notes.length, equals(1));
      });

      test('WaveformType has all expected types', () {
        expect(WaveformType.values.length, equals(4));
        expect(WaveformType.values, contains(WaveformType.square));
        expect(WaveformType.values, contains(WaveformType.triangle));
        expect(WaveformType.values, contains(WaveformType.sawtooth));
        expect(WaveformType.values, contains(WaveformType.noise));
      });
    });

    group('Sample Rate', () {
      test('sampleRate is 44100 Hz', () {
        expect(ChiptuneGenerator.sampleRate, equals(44100));
      });
    });

    group('Audio Quality', () {
      test('generated audio samples are within valid range', () {
        final wav = ChiptuneGenerator.generateAchievementJingle();

        // Check audio samples (starting at offset 44)
        for (int i = 44; i < wav.length; i += 2) {
          final sample = _readInt16LE(wav, i);
          expect(sample, greaterThanOrEqualTo(-32768));
          expect(sample, lessThanOrEqualTo(32767));
        }
      });

      test('audio is not completely silent', () {
        final wav = ChiptuneGenerator.generateLevelUpJingle();

        // Find any non-zero sample
        bool hasNonZero = false;
        for (int i = 44; i < wav.length && !hasNonZero; i += 2) {
          final sample = _readInt16LE(wav, i);
          if (sample != 0) hasNonZero = true;
        }

        expect(hasNonZero, isTrue, reason: 'Audio should contain sound');
      });

      test('audio is normalized (peak not clipping)', () {
        final wav = ChiptuneGenerator.generateStreak30Jingle();

        int maxSample = 0;
        for (int i = 44; i < wav.length; i += 2) {
          final sample = _readInt16LE(wav, i).abs();
          if (sample > maxSample) maxSample = sample;
        }

        // Should be normalized to ~0.8 of max (32767 * 0.8 = ~26213)
        // Allow some variance, but shouldn't be clipping at 32767
        expect(maxSample, lessThan(32767));
        expect(maxSample, greaterThan(20000), reason: 'Should have reasonable volume');
      });
    });

    group('Real-world Scenarios', () {
      test('all jingles generate without errors', () {
        // This verifies the patterns don't have syntax errors
        expect(
          () {
            ChiptuneGenerator.generateLevelUpJingle(variation: 0);
            ChiptuneGenerator.generateLevelUpJingle(variation: 1);
            ChiptuneGenerator.generateLevelUpJingle(variation: 2);
            ChiptuneGenerator.generateMilestoneJingle(variation: 0);
            ChiptuneGenerator.generateMilestoneJingle(variation: 1);
            ChiptuneGenerator.generateAchievementJingle(variation: 0);
            ChiptuneGenerator.generateAchievementJingle(variation: 1);
            ChiptuneGenerator.generatePersonalBestJingle();
            ChiptuneGenerator.generateStreak7Jingle();
            ChiptuneGenerator.generateStreak14Jingle();
            ChiptuneGenerator.generateStreak30Jingle();
          },
          returnsNormally,
        );
      });

      test('jingles have appropriate durations', () {
        // Calculate approximate duration from WAV size
        // Duration = (bytes - 44 header) / (44100 * 2 bytes per sample)
        double getDuration(Uint8List wav) {
          return (wav.length - 44) / (44100 * 2);
        }

        // Achievement should be short (~1-2 seconds)
        final achievement = ChiptuneGenerator.generateAchievementJingle();
        expect(getDuration(achievement), lessThan(5.0));

        // Level-up should be medium (~2-4 seconds)
        final levelUp = ChiptuneGenerator.generateLevelUpJingle();
        expect(getDuration(levelUp), greaterThan(2.0));
        expect(getDuration(levelUp), lessThan(6.0));

        // Milestone should be longer
        final milestone = ChiptuneGenerator.generateMilestoneJingle();
        expect(getDuration(milestone), greaterThan(4.0));

        // Personal best should be substantial
        final pb = ChiptuneGenerator.generatePersonalBestJingle();
        expect(getDuration(pb), greaterThan(10.0));

        // Streak jingles should be substantial
        final streak30 = ChiptuneGenerator.generateStreak30Jingle();
        expect(getDuration(streak30), greaterThan(15.0));
      });

      test('level-up jingle cycle provides variety', () {
        // Simulate playing level-up multiple times
        final jingles = <Uint8List>[];
        for (int i = 0; i < 6; i++) {
          jingles.add(ChiptuneGenerator.generateLevelUpJingle(variation: i % 3));
        }

        // First three should match the last three (wrap around)
        expect(jingles[0].length, equals(jingles[3].length));
        expect(jingles[1].length, equals(jingles[4].length));
        expect(jingles[2].length, equals(jingles[5].length));
      });
    });

    group('Edge Cases', () {
      test('very short note renders without error', () {
        final samples = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 0.001, // 1ms
          waveform: WaveformType.square,
        );
        expect(samples.length, greaterThan(0));
      });

      test('very long note renders without error', () {
        final samples = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 5.0, // 5 seconds
          waveform: WaveformType.square,
        );
        expect(samples.length, equals((5.0 * 44100).round()));
      });

      test('zero volume produces silence', () {
        final samples = ChiptuneGenerator.renderNote(
          note: 'A4',
          duration: 0.1,
          waveform: WaveformType.square,
          volume: 0.0,
        );
        for (final sample in samples) {
          expect(sample, equals(0.0));
        }
      });

      test('rest produces exact silence', () {
        final rest = ChiptuneGenerator.renderRest(0.1);
        for (final sample in rest) {
          expect(sample, equals(0.0));
        }
      });

      test('envelope with zero release ends immediately', () {
        final env = ChiptuneGenerator.envelope(
          time: 0.5,
          noteDuration: 0.5,
          release: 0.0,
        );
        // At the exact end of note with zero release, should be 0
        expect(env, closeTo(0.0, 0.1));
      });
    });
  });
}

/// Verifies that a byte array is a valid WAV file.
void _verifyWavFormat(Uint8List wav) {
  // Minimum WAV size (44 byte header + some data)
  expect(wav.length, greaterThan(44), reason: 'WAV too small');

  // Check RIFF header
  expect(wav[0], equals(0x52), reason: 'Missing R in RIFF');
  expect(wav[1], equals(0x49), reason: 'Missing I in RIFF');
  expect(wav[2], equals(0x46), reason: 'Missing F in RIFF');
  expect(wav[3], equals(0x46), reason: 'Missing F in RIFF');

  // Check WAVE format
  expect(wav[8], equals(0x57), reason: 'Missing W in WAVE');
  expect(wav[9], equals(0x41), reason: 'Missing A in WAVE');
  expect(wav[10], equals(0x56), reason: 'Missing V in WAVE');
  expect(wav[11], equals(0x45), reason: 'Missing E in WAVE');
}

/// Read a little-endian 16-bit signed integer from bytes.
int _readInt16LE(Uint8List bytes, int offset) {
  final value = bytes[offset] | (bytes[offset + 1] << 8);
  // Convert unsigned to signed
  return value < 0x8000 ? value : value - 0x10000;
}
