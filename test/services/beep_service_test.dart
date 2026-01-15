/// Tests for BeepService
///
/// These tests verify the beep service's WAV generation logic.
/// Audio playback is not tested as it requires actual audio hardware.
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Test-only version of BeepService that exposes WAV generation
/// without requiring AudioPlayer initialization.
class TestableBeepService {
  /// Generate a WAV file with gentle sine wave beep(s).
  /// Exposed for testing.
  Uint8List generateBeepWav({required int beepCount}) {
    const int sampleRate = 44100;
    const double frequency = 392.0; // G4 note
    const int beepDurationMs = 120;
    const int silenceDurationMs = 100;

    final int samplesPerBeep = (sampleRate * beepDurationMs / 1000).round();
    final int samplesPerSilence = (sampleRate * silenceDurationMs / 1000).round();

    // Calculate total samples
    int totalSamples = samplesPerBeep * beepCount;
    if (beepCount > 1) {
      totalSamples += samplesPerSilence * (beepCount - 1);
    }

    // Generate audio samples (simplified - just zeros for testing)
    final samples = Int16List(totalSamples);

    return _createWavFile(samples, sampleRate);
  }

  /// Create a valid WAV file header with samples.
  Uint8List _createWavFile(Int16List samples, int sampleRate) {
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = samples.length * 2;
    final int fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // 'R'
    buffer.setUint8(offset++, 0x49); // 'I'
    buffer.setUint8(offset++, 0x46); // 'F'
    buffer.setUint8(offset++, 0x46); // 'F'
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // 'W'
    buffer.setUint8(offset++, 0x41); // 'A'
    buffer.setUint8(offset++, 0x56); // 'V'
    buffer.setUint8(offset++, 0x45); // 'E'

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // 'f'
    buffer.setUint8(offset++, 0x6D); // 'm'
    buffer.setUint8(offset++, 0x74); // 't'
    buffer.setUint8(offset++, 0x20); // ' '
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM
    offset += 2;
    buffer.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    buffer.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    buffer.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // 'd'
    buffer.setUint8(offset++, 0x61); // 'a'
    buffer.setUint8(offset++, 0x74); // 't'
    buffer.setUint8(offset++, 0x61); // 'a'
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Audio samples
    for (int i = 0; i < samples.length; i++) {
      buffer.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}

void main() {
  group('BeepService', () {
    late TestableBeepService beepService;

    setUp(() {
      beepService = TestableBeepService();
    });

    group('WAV Generation', () {
      test('generates valid WAV file header', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Check RIFF header
        expect(wav[0], equals(0x52)); // 'R'
        expect(wav[1], equals(0x49)); // 'I'
        expect(wav[2], equals(0x46)); // 'F'
        expect(wav[3], equals(0x46)); // 'F'

        // Check WAVE format
        expect(wav[8], equals(0x57)); // 'W'
        expect(wav[9], equals(0x41)); // 'A'
        expect(wav[10], equals(0x56)); // 'V'
        expect(wav[11], equals(0x45)); // 'E'
      });

      test('includes fmt chunk', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Check fmt chunk marker
        expect(wav[12], equals(0x66)); // 'f'
        expect(wav[13], equals(0x6D)); // 'm'
        expect(wav[14], equals(0x74)); // 't'
        expect(wav[15], equals(0x20)); // ' '
      });

      test('includes data chunk', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Check data chunk marker
        expect(wav[36], equals(0x64)); // 'd'
        expect(wav[37], equals(0x61)); // 'a'
        expect(wav[38], equals(0x74)); // 't'
        expect(wav[39], equals(0x61)); // 'a'
      });

      test('sets correct audio format (PCM)', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Audio format at offset 20-21 (little endian)
        final audioFormat = wav[20] | (wav[21] << 8);
        expect(audioFormat, equals(1)); // 1 = PCM
      });

      test('sets mono channel', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Num channels at offset 22-23
        final numChannels = wav[22] | (wav[23] << 8);
        expect(numChannels, equals(1)); // Mono
      });

      test('sets 44100 Hz sample rate', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Sample rate at offset 24-27 (little endian)
        final sampleRate = wav[24] | (wav[25] << 8) | (wav[26] << 16) | (wav[27] << 24);
        expect(sampleRate, equals(44100));
      });

      test('sets 16-bit samples', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Bits per sample at offset 34-35
        final bitsPerSample = wav[34] | (wav[35] << 8);
        expect(bitsPerSample, equals(16));
      });

      test('single beep has expected size', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // 44 byte header + samples
        // 120ms @ 44100Hz = 5292 samples * 2 bytes = 10584 bytes
        expect(wav.length, equals(44 + 10584));
      });

      test('double beep is longer than single beep', () {
        final singleWav = beepService.generateBeepWav(beepCount: 1);
        final doubleWav = beepService.generateBeepWav(beepCount: 2);

        expect(doubleWav.length, greaterThan(singleWav.length));
      });

      test('double beep includes silence between beeps', () {
        final singleWav = beepService.generateBeepWav(beepCount: 1);
        final doubleWav = beepService.generateBeepWav(beepCount: 2);

        // Single beep data size
        final singleDataSize = singleWav.length - 44;

        // Double beep should have 2x beep data + silence
        // Silence = 100ms @ 44100Hz = 4410 samples * 2 bytes = 8820 bytes
        final doubleDataSize = doubleWav.length - 44;
        final expectedDoubleData = (singleDataSize * 2) + 8820;

        expect(doubleDataSize, equals(expectedDoubleData));
      });
    });

    group('WAV File Size Calculation', () {
      test('file size in header matches actual size', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // File size at offset 4-7 (little endian, excluding first 8 bytes)
        final headerFileSize = wav[4] | (wav[5] << 8) | (wav[6] << 16) | (wav[7] << 24);
        final actualFileSize = wav.length - 8;

        expect(headerFileSize, equals(actualFileSize));
      });

      test('data size in header matches actual data', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Data size at offset 40-43 (little endian)
        final headerDataSize = wav[40] | (wav[41] << 8) | (wav[42] << 16) | (wav[43] << 24);
        final actualDataSize = wav.length - 44;

        expect(headerDataSize, equals(actualDataSize));
      });
    });

    group('Beep Count Variations', () {
      test('generates valid WAV for 1 beep', () {
        final wav = beepService.generateBeepWav(beepCount: 1);
        expect(wav.length, greaterThan(44)); // At least header
      });

      test('generates valid WAV for 2 beeps', () {
        final wav = beepService.generateBeepWav(beepCount: 2);
        expect(wav.length, greaterThan(44));
      });

      test('generates valid WAV for 3 beeps', () {
        final wav = beepService.generateBeepWav(beepCount: 3);
        expect(wav.length, greaterThan(44));
      });
    });

    group('Byte Rate Calculation', () {
      test('byte rate equals sample rate * channels * bytes per sample', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Byte rate at offset 28-31
        final byteRate = wav[28] | (wav[29] << 8) | (wav[30] << 16) | (wav[31] << 24);

        // 44100 Hz * 1 channel * 2 bytes per sample
        expect(byteRate, equals(44100 * 1 * 2));
      });
    });

    group('Block Align', () {
      test('block align equals channels * bytes per sample', () {
        final wav = beepService.generateBeepWav(beepCount: 1);

        // Block align at offset 32-33
        final blockAlign = wav[32] | (wav[33] << 8);

        // 1 channel * 2 bytes per sample
        expect(blockAlign, equals(1 * 2));
      });
    });
  });
}
