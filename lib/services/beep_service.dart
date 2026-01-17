import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

/// Service for playing gentle beep sounds during breathing exercises.
/// One beep for inhale, two beeps for exhale.
class BeepService {
  static final BeepService _instance = BeepService._internal();
  factory BeepService() => _instance;
  BeepService._internal();

  AudioPlayer? _player;
  BytesSource? _longBeepSource;   // Single longer beep for exhale
  BytesSource? _doubleBeepSource; // Two quick beeps for inhale
  bool _initialized = false;

  /// Initialize the beep service and pre-generate the beep sounds.
  Future<void> initialize() async {
    if (_initialized) return;

    _player = AudioPlayer();
    await _player!.setVolume(0.3); // Gentle volume

    // Generate the beep audio data
    _longBeepSource = BytesSource(_generateBeepWav(beepCount: 1, durationMs: 250));   // Longer exhale beep
    _doubleBeepSource = BytesSource(_generateBeepWav(beepCount: 2, durationMs: 120)); // Two quick inhale beeps

    _initialized = true;
  }

  /// Play two gentle beeps (for inhale - matches vibration pattern).
  Future<void> playInhaleBeep() async {
    if (!_initialized) await initialize();
    try {
      await _player!.stop();
      await _player!.play(_doubleBeepSource!);
    } catch (e) {
      // Silently fail - beeps are non-critical
    }
  }

  /// Play a single longer beep (for exhale - matches vibration pattern).
  Future<void> playExhaleBeep() async {
    if (!_initialized) await initialize();
    try {
      await _player!.stop();
      await _player!.play(_longBeepSource!);
    } catch (e) {
      // Silently fail - beeps are non-critical
    }
  }

  /// Generate a WAV file with gentle sine wave beep(s).
  /// Uses a soft frequency (392Hz - G4 note) for a calm, pleasant tone.
  Uint8List _generateBeepWav({required int beepCount, int durationMs = 120}) {
    const int sampleRate = 44100;
    const double frequency = 392.0; // G4 note - gentle and musical
    final int beepDurationMs = durationMs; // Configurable beep duration
    const int silenceDurationMs = 100; // Gap between beeps
    const double fadeMs = 20.0; // Fade in/out for softness

    final int samplesPerBeep = (sampleRate * beepDurationMs / 1000).round();
    final int samplesPerSilence = (sampleRate * silenceDurationMs / 1000).round();
    final int fadeSamples = (sampleRate * fadeMs / 1000).round();

    // Calculate total samples
    int totalSamples = samplesPerBeep * beepCount;
    if (beepCount > 1) {
      totalSamples += samplesPerSilence * (beepCount - 1);
    }

    // Generate audio samples (16-bit PCM)
    final samples = Int16List(totalSamples);
    int sampleIndex = 0;

    for (int beep = 0; beep < beepCount; beep++) {
      // Add silence between beeps (not before first beep)
      if (beep > 0) {
        for (int i = 0; i < samplesPerSilence; i++) {
          samples[sampleIndex++] = 0;
        }
      }

      // Generate beep with fade in/out
      for (int i = 0; i < samplesPerBeep; i++) {
        // Calculate envelope (fade in and out for gentleness)
        double envelope = 1.0;
        if (i < fadeSamples) {
          // Fade in using smooth sine curve
          envelope = math.sin((i / fadeSamples) * (math.pi / 2));
        } else if (i > samplesPerBeep - fadeSamples) {
          // Fade out using smooth sine curve
          final fadeIndex = samplesPerBeep - i;
          envelope = math.sin((fadeIndex / fadeSamples) * (math.pi / 2));
        }

        // Generate sine wave sample
        final t = i / sampleRate;
        final sampleValue = math.sin(2 * math.pi * frequency * t) * envelope;

        // Convert to 16-bit integer with moderate amplitude (0.4 = gentle)
        samples[sampleIndex++] = (sampleValue * 32767 * 0.4).round().clamp(-32768, 32767);
      }
    }

    // Create WAV file
    return _createWavFile(samples, sampleRate);
  }

  /// Create a valid WAV file from audio samples.
  Uint8List _createWavFile(Int16List samples, int sampleRate) {
    const int numChannels = 1; // Mono
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = samples.length * 2; // 2 bytes per sample
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
    buffer.setUint32(offset, 16, Endian.little); // Subchunk1Size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // AudioFormat (PCM)
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

  /// Dispose of resources.
  void dispose() {
    _player?.dispose();
    _player = null;
    _initialized = false;
  }
}
