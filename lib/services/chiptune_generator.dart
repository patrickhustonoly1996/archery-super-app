import 'dart:math' as math;
import 'dart:typed_data';

/// Procedural chiptune jingle generator.
/// Creates authentic C64 SID-style chip music with square, triangle,
/// sawtooth, and noise waveforms.
class ChiptuneGenerator {
  static const int sampleRate = 44100;

  // ==========================================================================
  // WAVEFORM GENERATORS
  // ==========================================================================

  /// Square wave - classic chip lead sound, bright and punchy.
  /// Duty cycle controls harmonic content (0.5 = classic, 0.25 = nasal).
  static double squareWave(double phase, {double dutyCycle = 0.5}) {
    return phase % 1.0 < dutyCycle ? 1.0 : -1.0;
  }

  /// Triangle wave - smooth, flute-like, good for bass.
  static double triangleWave(double phase) {
    final p = phase % 1.0;
    return p < 0.5 ? (4.0 * p - 1.0) : (3.0 - 4.0 * p);
  }

  /// Sawtooth wave - buzzy, rich in harmonics.
  static double sawtoothWave(double phase) {
    return 2.0 * (phase % 1.0) - 1.0;
  }

  /// Noise - for percussion hits.
  static double noise(math.Random rng) {
    return rng.nextDouble() * 2.0 - 1.0;
  }

  // ==========================================================================
  // MUSICAL NOTES (Hz)
  // ==========================================================================

  // Note frequencies for octaves 2-6 (covers bass to lead range)
  static const Map<String, double> notes = {
    // Octave 2 (bass)
    'C2': 65.41, 'D2': 73.42, 'E2': 82.41, 'F2': 87.31,
    'G2': 98.00, 'A2': 110.00, 'B2': 123.47,
    // Octave 3
    'C3': 130.81, 'D3': 146.83, 'E3': 164.81, 'F3': 174.61,
    'G3': 196.00, 'A3': 220.00, 'B3': 246.94,
    // Octave 4 (middle)
    'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23,
    'G4': 392.00, 'A4': 440.00, 'B4': 493.88,
    // Octave 5
    'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'F5': 698.46,
    'G5': 783.99, 'A5': 880.00, 'B5': 987.77,
    // Octave 6 (high sparkle)
    'C6': 1046.50, 'D6': 1174.66, 'E6': 1318.51,
  };

  // ==========================================================================
  // ENVELOPE (ADSR)
  // ==========================================================================

  /// Calculate envelope amplitude at a given time within a note.
  static double envelope({
    required double time,
    required double noteDuration,
    double attack = 0.01,
    double decay = 0.05,
    double sustain = 0.7,
    double release = 0.1,
  }) {
    final releaseStart = noteDuration - release;

    if (time < attack) {
      // Attack phase - ramp up
      return time / attack;
    } else if (time < attack + decay) {
      // Decay phase - drop to sustain level
      final decayProgress = (time - attack) / decay;
      return 1.0 - (1.0 - sustain) * decayProgress;
    } else if (time < releaseStart) {
      // Sustain phase
      return sustain;
    } else if (time < noteDuration) {
      // Release phase - fade out
      final releaseProgress = (time - releaseStart) / release;
      return sustain * (1.0 - releaseProgress);
    }
    return 0.0;
  }

  // ==========================================================================
  // NOTE RENDERING
  // ==========================================================================

  /// Render a single note to samples.
  static List<double> renderNote({
    required String note,
    required double duration,
    required WaveformType waveform,
    double volume = 0.5,
    double dutyCycle = 0.5,
    double attack = 0.01,
    double decay = 0.05,
    double sustain = 0.7,
    double release = 0.1,
    int? seed,
  }) {
    final freq = notes[note] ?? 440.0;
    final numSamples = (duration * sampleRate).round();
    final samples = List<double>.filled(numSamples, 0.0);
    final rng = math.Random(seed ?? 42);

    for (int i = 0; i < numSamples; i++) {
      final time = i / sampleRate;
      final phase = freq * time;

      double sample;
      switch (waveform) {
        case WaveformType.square:
          sample = squareWave(phase, dutyCycle: dutyCycle);
          break;
        case WaveformType.triangle:
          sample = triangleWave(phase);
          break;
        case WaveformType.sawtooth:
          sample = sawtoothWave(phase);
          break;
        case WaveformType.noise:
          sample = noise(rng);
          break;
      }

      final env = envelope(
        time: time,
        noteDuration: duration,
        attack: attack,
        decay: decay,
        sustain: sustain,
        release: release,
      );

      samples[i] = sample * env * volume;
    }

    return samples;
  }

  /// Render silence (rest).
  static List<double> renderRest(double duration) {
    final numSamples = (duration * sampleRate).round();
    return List<double>.filled(numSamples, 0.0);
  }

  // ==========================================================================
  // JINGLE COMPOSITION
  // ==========================================================================

  /// Generate a level-up jingle (5-8 seconds).
  /// Triumphant ascending arpeggio with fanfare.
  static Uint8List generateLevelUpJingle({int variation = 0}) {
    final samples = <double>[];

    // Different variations for variety
    final patterns = [
      // Variation 0: Classic ascending major arpeggio
      _levelUpPattern1(),
      // Variation 1: Heroic fanfare
      _levelUpPattern2(),
      // Variation 2: Quick celebratory burst
      _levelUpPattern3(),
    ];

    final pattern = patterns[variation % patterns.length];
    samples.addAll(_renderPattern(pattern));

    return _samplesToWav(_mixDown(samples));
  }

  /// Generate a milestone jingle (8-12 seconds).
  /// More elaborate fanfare for special achievements.
  static Uint8List generateMilestoneJingle({int variation = 0}) {
    final samples = <double>[];

    final patterns = [
      _milestonePattern1(),
      _milestonePattern2(),
    ];

    final pattern = patterns[variation % patterns.length];
    samples.addAll(_renderPattern(pattern));

    return _samplesToWav(_mixDown(samples));
  }

  /// Generate an achievement jingle (3-5 seconds).
  /// Short, punchy reward sound.
  static Uint8List generateAchievementJingle({int variation = 0}) {
    final samples = <double>[];

    final patterns = [
      _achievementPattern1(),
      _achievementPattern2(),
    ];

    final pattern = patterns[variation % patterns.length];
    samples.addAll(_renderPattern(pattern));

    return _samplesToWav(_mixDown(samples));
  }

  /// Generate a Personal Best jingle (10-12 seconds).
  /// Extended celebration for beating your PB - three ascending loops
  /// with building urgency and glee.
  static Uint8List generatePersonalBestJingle() {
    final samples = <double>[];
    samples.addAll(_renderPattern(_personalBestPattern()));
    return _samplesToWav(_mixDown(samples));
  }

  /// Generate a 7-day streak jingle (12-15 seconds).
  /// Slow, respectful, jubilatory serenade acknowledging consistent effort.
  static Uint8List generateStreak7Jingle() {
    final samples = <double>[];
    samples.addAll(_renderPattern(_streak7Pattern()));
    return _samplesToWav(_mixDown(samples));
  }

  /// Generate a 14-day streak jingle (~14 seconds).
  /// Fuller than 7-day with added countermelody. "This is becoming a habit."
  static Uint8List generateStreak14Jingle() {
    final samples = <double>[];
    samples.addAll(_renderPattern(_streak14Pattern()));
    return _samplesToWav(_mixDown(samples));
  }

  /// Generate a 30-day streak jingle (~18 seconds).
  /// Grand, triumphant celebration. Multiple voices, key modulation.
  /// "You're committed."
  static Uint8List generateStreak30Jingle() {
    final samples = <double>[];
    samples.addAll(_renderPattern(_streak30Pattern()));
    return _samplesToWav(_mixDown(samples));
  }

  // ==========================================================================
  // JINGLE PATTERNS
  // ==========================================================================

  /// Level-up pattern 1: Euphoric ascending loops
  static List<Voice> _levelUpPattern1() {
    return [
      // Lead voice - ascending arpeggios that loop upward
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.25,
        volume: 0.4,
        notes: [
          // First ascending phrase
          NoteEvent('C4', 0.0, 0.12),
          NoteEvent('E4', 0.12, 0.12),
          NoteEvent('G4', 0.24, 0.12),
          NoteEvent('C5', 0.36, 0.18),
          // Second ascending phrase (higher)
          NoteEvent('E4', 0.6, 0.12),
          NoteEvent('G4', 0.72, 0.12),
          NoteEvent('C5', 0.84, 0.12),
          NoteEvent('E5', 0.96, 0.18),
          // Third ascending phrase (highest)
          NoteEvent('G4', 1.2, 0.12),
          NoteEvent('C5', 1.32, 0.12),
          NoteEvent('E5', 1.44, 0.12),
          NoteEvent('G5', 1.56, 0.24),
          // Triumphant peak
          NoteEvent('C6', 1.85, 0.15),
          NoteEvent('G5', 2.05, 0.1),
          NoteEvent('C6', 2.2, 0.15),
          NoteEvent('E6', 2.4, 0.15),
          NoteEvent('G5', 2.6, 0.15),
          NoteEvent('C6', 2.8, 0.6),
        ],
      ),
      // Bass voice - driving root progression
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C2', 0.0, 0.3),
          NoteEvent('C3', 0.36, 0.2),
          NoteEvent('G2', 0.6, 0.3),
          NoteEvent('G2', 0.96, 0.2),
          NoteEvent('C3', 1.2, 0.3),
          NoteEvent('E3', 1.56, 0.25),
          NoteEvent('G2', 1.85, 0.35),
          NoteEvent('C2', 2.4, 0.2),
          NoteEvent('C3', 2.8, 0.6),
        ],
      ),
      // Sparkle layer - high accents
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.2,
        attack: 0.005,
        decay: 0.03,
        sustain: 0.4,
        notes: [
          NoteEvent('C6', 0.36, 0.1),
          NoteEvent('E6', 0.96, 0.1),
          NoteEvent('G5', 1.56, 0.15),
          NoteEvent('C6', 2.2, 0.1),
          NoteEvent('E6', 2.4, 0.1),
          NoteEvent('G5', 2.8, 0.5),
        ],
      ),
    ];
  }

  /// Level-up pattern 2: Building euphoria with call-and-response
  static List<Voice> _levelUpPattern2() {
    return [
      // Lead - ascending call and response
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.3,
        volume: 0.4,
        notes: [
          // Call 1 - low
          NoteEvent('G3', 0.0, 0.1),
          NoteEvent('C4', 0.1, 0.1),
          NoteEvent('E4', 0.2, 0.15),
          // Response 1 - higher
          NoteEvent('G4', 0.4, 0.1),
          NoteEvent('C5', 0.5, 0.1),
          NoteEvent('E5', 0.6, 0.2),
          // Call 2 - mid
          NoteEvent('A4', 0.9, 0.1),
          NoteEvent('C5', 1.0, 0.1),
          NoteEvent('E5', 1.1, 0.15),
          // Response 2 - high
          NoteEvent('A5', 1.3, 0.1),
          NoteEvent('C6', 1.4, 0.1),
          NoteEvent('E6', 1.5, 0.25),
          // Ascending finale
          NoteEvent('C5', 1.85, 0.12),
          NoteEvent('E5', 1.97, 0.12),
          NoteEvent('G5', 2.09, 0.12),
          NoteEvent('C6', 2.21, 0.12),
          NoteEvent('E6', 2.33, 0.12),
          // Peak hold
          NoteEvent('G5', 2.5, 0.15),
          NoteEvent('C6', 2.7, 0.15),
          NoteEvent('E6', 2.9, 0.15),
          NoteEvent('C6', 3.1, 0.6),
        ],
      ),
      // Bass - pumping rhythm
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C2', 0.0, 0.2),
          NoteEvent('C3', 0.2, 0.15),
          NoteEvent('G2', 0.4, 0.2),
          NoteEvent('G2', 0.6, 0.25),
          NoteEvent('A2', 0.9, 0.2),
          NoteEvent('A2', 1.1, 0.15),
          NoteEvent('A2', 1.3, 0.25),
          NoteEvent('A3', 1.5, 0.3),
          NoteEvent('C3', 1.85, 0.35),
          NoteEvent('G2', 2.33, 0.15),
          NoteEvent('C2', 2.5, 0.2),
          NoteEvent('C3', 3.1, 0.6),
        ],
      ),
      // High sparkle accents
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.18,
        attack: 0.005,
        notes: [
          NoteEvent('E6', 0.2, 0.08),
          NoteEvent('E6', 0.6, 0.12),
          NoteEvent('E6', 1.1, 0.08),
          NoteEvent('E6', 1.5, 0.15),
          NoteEvent('G5', 2.5, 0.1),
          NoteEvent('C6', 2.7, 0.1),
          NoteEvent('E6', 2.9, 0.1),
          NoteEvent('G5', 3.1, 0.5),
        ],
      ),
    ];
  }

  /// Level-up pattern 3: Stairway to heaven - continuous ascent
  static List<Voice> _levelUpPattern3() {
    return [
      // Lead - staircase ascending pattern
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.25,
        volume: 0.4,
        attack: 0.005,
        decay: 0.02,
        notes: [
          // Step 1
          NoteEvent('C4', 0.0, 0.1),
          NoteEvent('D4', 0.1, 0.1),
          NoteEvent('E4', 0.2, 0.15),
          // Step 2
          NoteEvent('E4', 0.4, 0.1),
          NoteEvent('F4', 0.5, 0.1),
          NoteEvent('G4', 0.6, 0.15),
          // Step 3
          NoteEvent('G4', 0.8, 0.1),
          NoteEvent('A4', 0.9, 0.1),
          NoteEvent('B4', 1.0, 0.15),
          // Step 4 - breakthrough
          NoteEvent('C5', 1.2, 0.1),
          NoteEvent('D5', 1.3, 0.1),
          NoteEvent('E5', 1.4, 0.15),
          // Step 5 - soaring
          NoteEvent('E5', 1.6, 0.1),
          NoteEvent('G5', 1.7, 0.1),
          NoteEvent('C6', 1.8, 0.25),
          // Final flourish
          NoteEvent('G5', 2.1, 0.1),
          NoteEvent('C6', 2.25, 0.1),
          NoteEvent('E6', 2.4, 0.15),
          NoteEvent('C6', 2.6, 0.5),
        ],
      ),
      // Harmony - following thirds
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.5,
        volume: 0.2,
        notes: [
          NoteEvent('E4', 0.2, 0.15),
          NoteEvent('G4', 0.6, 0.15),
          NoteEvent('B4', 1.0, 0.15),
          NoteEvent('E5', 1.4, 0.15),
          NoteEvent('G5', 1.8, 0.25),
          NoteEvent('G5', 2.4, 0.1),
          NoteEvent('E5', 2.6, 0.5),
        ],
      ),
      // Bass - rising foundation
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C2', 0.0, 0.35),
          NoteEvent('E2', 0.4, 0.35),
          NoteEvent('G2', 0.8, 0.35),
          NoteEvent('C3', 1.2, 0.35),
          NoteEvent('E3', 1.6, 0.2),
          NoteEvent('G3', 1.8, 0.25),
          NoteEvent('C3', 2.1, 0.25),
          NoteEvent('C2', 2.6, 0.5),
        ],
      ),
    ];
  }

  /// Milestone pattern 1: Grand fanfare
  static List<Voice> _milestonePattern1() {
    return [
      // Lead - epic melody
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.25,
        volume: 0.4,
        notes: [
          // Opening flourish
          NoteEvent('C4', 0.0, 0.1),
          NoteEvent('E4', 0.1, 0.1),
          NoteEvent('G4', 0.2, 0.1),
          NoteEvent('C5', 0.3, 0.25),
          // Main theme
          NoteEvent('E5', 0.6, 0.2),
          NoteEvent('D5', 0.85, 0.15),
          NoteEvent('C5', 1.05, 0.15),
          NoteEvent('D5', 1.25, 0.15),
          NoteEvent('E5', 1.45, 0.35),
          // Climax
          NoteEvent('G5', 1.9, 0.2),
          NoteEvent('A5', 2.15, 0.2),
          NoteEvent('G5', 2.4, 0.2),
          NoteEvent('E5', 2.65, 0.15),
          NoteEvent('C5', 2.85, 0.15),
          // Resolution
          NoteEvent('D5', 3.1, 0.2),
          NoteEvent('C5', 3.4, 0.6),
          // Final chord
          NoteEvent('C5', 4.1, 0.15),
          NoteEvent('E5', 4.3, 0.15),
          NoteEvent('G5', 4.5, 0.15),
          NoteEvent('C6', 4.7, 0.8),
        ],
      ),
      // Counter melody
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.5,
        volume: 0.25,
        notes: [
          NoteEvent('G4', 0.6, 0.2),
          NoteEvent('G4', 0.85, 0.15),
          NoteEvent('E4', 1.05, 0.15),
          NoteEvent('G4', 1.45, 0.35),
          NoteEvent('C5', 1.9, 0.7),
          NoteEvent('G4', 2.65, 0.65),
          NoteEvent('E4', 3.4, 0.6),
          NoteEvent('G5', 4.7, 0.8),
        ],
      ),
      // Bass line
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C2', 0.0, 0.55),
          NoteEvent('C3', 0.6, 0.75),
          NoteEvent('G2', 1.45, 0.4),
          NoteEvent('A2', 1.9, 0.4),
          NoteEvent('G2', 2.4, 0.4),
          NoteEvent('C3', 2.85, 0.4),
          NoteEvent('G2', 3.4, 0.6),
          NoteEvent('C2', 4.1, 1.4),
        ],
      ),
    ];
  }

  /// Milestone pattern 2: Victory theme
  static List<Voice> _milestonePattern2() {
    return [
      // Lead
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.3,
        volume: 0.4,
        notes: [
          // Dramatic opening
          NoteEvent('G4', 0.0, 0.15),
          NoteEvent('G4', 0.2, 0.15),
          NoteEvent('G4', 0.4, 0.15),
          NoteEvent('C5', 0.6, 0.5),
          // Theme
          NoteEvent('B4', 1.2, 0.2),
          NoteEvent('C5', 1.45, 0.2),
          NoteEvent('D5', 1.7, 0.2),
          NoteEvent('E5', 1.95, 0.5),
          // Continuation
          NoteEvent('D5', 2.55, 0.2),
          NoteEvent('E5', 2.8, 0.2),
          NoteEvent('F5', 3.05, 0.2),
          NoteEvent('G5', 3.3, 0.7),
          // Grand finale
          NoteEvent('C5', 4.1, 0.15),
          NoteEvent('E5', 4.3, 0.15),
          NoteEvent('G5', 4.5, 0.15),
          NoteEvent('C6', 4.7, 1.0),
        ],
      ),
      // Harmony
      Voice(
        waveform: WaveformType.sawtooth,
        volume: 0.18,
        notes: [
          NoteEvent('E4', 0.6, 0.5),
          NoteEvent('G4', 1.2, 0.65),
          NoteEvent('G4', 1.95, 0.5),
          NoteEvent('B4', 2.55, 0.65),
          NoteEvent('D5', 3.3, 0.7),
          NoteEvent('E5', 4.7, 1.0),
        ],
      ),
      // Bass
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C2', 0.0, 0.55),
          NoteEvent('C3', 0.6, 0.55),
          NoteEvent('G2', 1.2, 0.7),
          NoteEvent('C3', 1.95, 0.55),
          NoteEvent('G2', 2.55, 0.7),
          NoteEvent('G2', 3.3, 0.7),
          NoteEvent('C2', 4.1, 1.6),
        ],
      ),
    ];
  }

  /// Achievement pattern 1: Triumphant unlock
  static List<Voice> _achievementPattern1() {
    return [
      // Lead - ascending unlock fanfare
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.25,
        volume: 0.4,
        attack: 0.005,
        notes: [
          // Quick ascending hook
          NoteEvent('G4', 0.0, 0.08),
          NoteEvent('C5', 0.08, 0.08),
          NoteEvent('E5', 0.16, 0.12),
          // Repeat higher
          NoteEvent('C5', 0.35, 0.08),
          NoteEvent('E5', 0.43, 0.08),
          NoteEvent('G5', 0.51, 0.12),
          // Peak phrase
          NoteEvent('E5', 0.7, 0.1),
          NoteEvent('G5', 0.8, 0.1),
          NoteEvent('C6', 0.9, 0.2),
          // Resolve
          NoteEvent('G5', 1.15, 0.1),
          NoteEvent('C6', 1.3, 0.12),
          NoteEvent('E6', 1.45, 0.12),
          NoteEvent('C6', 1.65, 0.45),
        ],
      ),
      // Sparkle
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.2,
        attack: 0.003,
        notes: [
          NoteEvent('E6', 0.16, 0.08),
          NoteEvent('G5', 0.51, 0.1),
          NoteEvent('C6', 0.9, 0.15),
          NoteEvent('G5', 1.65, 0.4),
        ],
      ),
      // Bass
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C3', 0.0, 0.3),
          NoteEvent('G2', 0.35, 0.3),
          NoteEvent('C3', 0.7, 0.4),
          NoteEvent('C2', 1.3, 0.8),
        ],
      ),
    ];
  }

  /// Achievement pattern 2: Shimmering success
  static List<Voice> _achievementPattern2() {
    return [
      // Lead - bouncy ascending
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.25,
        volume: 0.38,
        attack: 0.003,
        decay: 0.02,
        sustain: 0.6,
        notes: [
          // Bouncy intro
          NoteEvent('E5', 0.0, 0.1),
          NoteEvent('G5', 0.12, 0.1),
          NoteEvent('E5', 0.24, 0.08),
          NoteEvent('G5', 0.34, 0.08),
          NoteEvent('C6', 0.44, 0.18),
          // Echo higher
          NoteEvent('G5', 0.7, 0.08),
          NoteEvent('C6', 0.8, 0.08),
          NoteEvent('E6', 0.9, 0.2),
          // Resolve with sparkle
          NoteEvent('C6', 1.15, 0.1),
          NoteEvent('E6', 1.28, 0.1),
          NoteEvent('G5', 1.4, 0.08),
          NoteEvent('C6', 1.5, 0.5),
        ],
      ),
      // High shimmer
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.18,
        attack: 0.002,
        notes: [
          NoteEvent('C6', 0.44, 0.12),
          NoteEvent('E6', 0.9, 0.15),
          NoteEvent('G5', 1.5, 0.45),
        ],
      ),
      // Bass pulse
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          NoteEvent('C3', 0.0, 0.2),
          NoteEvent('G2', 0.24, 0.2),
          NoteEvent('C3', 0.44, 0.22),
          NoteEvent('G2', 0.7, 0.18),
          NoteEvent('C3', 0.9, 0.22),
          NoteEvent('C2', 1.15, 0.85),
        ],
      ),
    ];
  }

  /// Personal Best pattern: Three ascending loops with building urgency
  /// Based on level_up_3 "stairway" but extended with drops and repeats
  static List<Voice> _personalBestPattern() {
    return [
      // Lead - three loops of ascending staircase with variations
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.25,
        volume: 0.4,
        attack: 0.005,
        decay: 0.02,
        notes: [
          // === LOOP 1: Steady climb (tempo: normal) ===
          // Step 1
          NoteEvent('C4', 0.0, 0.1),
          NoteEvent('D4', 0.1, 0.1),
          NoteEvent('E4', 0.2, 0.15),
          // Step 2
          NoteEvent('E4', 0.4, 0.1),
          NoteEvent('F4', 0.5, 0.1),
          NoteEvent('G4', 0.6, 0.15),
          // Step 3
          NoteEvent('G4', 0.8, 0.1),
          NoteEvent('A4', 0.9, 0.1),
          NoteEvent('B4', 1.0, 0.15),
          // Step 4 - first peak
          NoteEvent('C5', 1.2, 0.1),
          NoteEvent('D5', 1.3, 0.1),
          NoteEvent('E5', 1.4, 0.2),
          // Drop down - breath
          NoteEvent('G4', 1.7, 0.12),
          NoteEvent('E4', 1.85, 0.12),
          NoteEvent('C4', 2.0, 0.15),

          // === LOOP 2: Faster, more urgent ===
          // Step 1 (faster)
          NoteEvent('C4', 2.3, 0.08),
          NoteEvent('D4', 2.38, 0.08),
          NoteEvent('E4', 2.46, 0.1),
          // Step 2
          NoteEvent('E4', 2.6, 0.08),
          NoteEvent('F4', 2.68, 0.08),
          NoteEvent('G4', 2.76, 0.1),
          // Step 3
          NoteEvent('G4', 2.9, 0.08),
          NoteEvent('A4', 2.98, 0.08),
          NoteEvent('B4', 3.06, 0.1),
          // Step 4
          NoteEvent('C5', 3.2, 0.08),
          NoteEvent('D5', 3.28, 0.08),
          NoteEvent('E5', 3.36, 0.1),
          // Step 5 - higher peak!
          NoteEvent('E5', 3.5, 0.08),
          NoteEvent('G5', 3.58, 0.08),
          NoteEvent('C6', 3.66, 0.2),
          // Drop down - dramatic
          NoteEvent('G5', 3.95, 0.1),
          NoteEvent('E5', 4.08, 0.1),
          NoteEvent('C5', 4.2, 0.1),
          NoteEvent('G4', 4.35, 0.12),

          // === LOOP 3: Full glee - fastest, highest ===
          // Rapid ascending run
          NoteEvent('C4', 4.6, 0.06),
          NoteEvent('E4', 4.66, 0.06),
          NoteEvent('G4', 4.72, 0.06),
          NoteEvent('C5', 4.78, 0.06),
          NoteEvent('E5', 4.84, 0.06),
          NoteEvent('G5', 4.9, 0.08),
          // Second rapid run - even higher
          NoteEvent('D5', 5.05, 0.06),
          NoteEvent('F5', 5.11, 0.06),
          NoteEvent('A5', 5.17, 0.06),
          NoteEvent('D6', 5.23, 0.06),
          // Triumphant peak sequence
          NoteEvent('E6', 5.35, 0.12),
          NoteEvent('D6', 5.5, 0.08),
          NoteEvent('E6', 5.6, 0.12),

          // === EXTENDED FANFARE FINALE ===
          // Wave 1 - triumphant toot
          NoteEvent('C6', 5.85, 0.18),
          NoteEvent('G5', 6.05, 0.08),
          NoteEvent('C6', 6.15, 0.08),
          NoteEvent('E6', 6.25, 0.22),
          // Wave 2 - echo response
          NoteEvent('G5', 6.55, 0.12),
          NoteEvent('C6', 6.7, 0.12),
          NoteEvent('E6', 6.85, 0.25),
          // Wave 3 - bigger fanfare
          NoteEvent('C5', 7.2, 0.08),
          NoteEvent('E5', 7.3, 0.08),
          NoteEvent('G5', 7.4, 0.08),
          NoteEvent('C6', 7.5, 0.15),
          NoteEvent('E6', 7.7, 0.25),
          // Wave 4 - building intensity
          NoteEvent('G5', 8.05, 0.1),
          NoteEvent('C6', 8.18, 0.1),
          NoteEvent('E6', 8.3, 0.1),
          NoteEvent('G5', 8.45, 0.1),
          NoteEvent('C6', 8.58, 0.1),
          NoteEvent('E6', 8.7, 0.12),
          // Wave 5 - THE BIG HIT - ascending to the heavens
          NoteEvent('G5', 8.9, 0.08),
          NoteEvent('C6', 9.0, 0.08),
          NoteEvent('E6', 9.1, 0.08),
          NoteEvent('G5', 9.2, 0.08),
          NoteEvent('C6', 9.3, 0.08),
          NoteEvent('E6', 9.4, 0.08),
          NoteEvent('G5', 9.5, 0.06),
          NoteEvent('C6', 9.58, 0.06),
          NoteEvent('E6', 9.66, 0.06),
          NoteEvent('G5', 9.74, 0.06),
          NoteEvent('C6', 9.82, 0.06),
          NoteEvent('E6', 9.9, 0.1),
          // PEAK - highest we go
          NoteEvent('G5', 10.05, 0.12),
          NoteEvent('C6', 10.2, 0.12),
          NoteEvent('E6', 10.35, 0.15),
          // Final triumphant sustain
          NoteEvent('C6', 10.6, 0.25),
          NoteEvent('E6', 10.9, 0.25),
          NoteEvent('C6', 11.2, 1.0),
        ],
      ),
      // Harmony voice - supporting thirds, enters more in later loops
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.5,
        volume: 0.22,
        notes: [
          // Loop 1 - light support
          NoteEvent('E4', 0.2, 0.12),
          NoteEvent('G4', 0.6, 0.12),
          NoteEvent('B4', 1.0, 0.12),
          NoteEvent('E5', 1.4, 0.18),
          // Loop 2 - more present
          NoteEvent('E4', 2.46, 0.08),
          NoteEvent('G4', 2.76, 0.08),
          NoteEvent('B4', 3.06, 0.08),
          NoteEvent('E5', 3.36, 0.08),
          NoteEvent('G5', 3.66, 0.18),
          // Loop 3 - full harmony
          NoteEvent('E5', 4.78, 0.06),
          NoteEvent('G5', 4.9, 0.08),
          NoteEvent('A5', 5.17, 0.06),
          NoteEvent('G5', 5.35, 0.1),
          NoteEvent('G5', 5.6, 0.1),
          // Fanfare harmony
          NoteEvent('E5', 5.85, 0.15),
          NoteEvent('G5', 6.25, 0.2),
          NoteEvent('E5', 6.55, 0.1),
          NoteEvent('G5', 6.85, 0.22),
          NoteEvent('E5', 7.5, 0.12),
          NoteEvent('G5', 7.7, 0.22),
          NoteEvent('E5', 8.05, 0.08),
          NoteEvent('G5', 8.3, 0.08),
          NoteEvent('E5', 8.45, 0.08),
          NoteEvent('G5', 8.7, 0.1),
          // Big hit harmony - driving with the lead
          NoteEvent('E5', 8.9, 0.06),
          NoteEvent('G5', 9.0, 0.06),
          NoteEvent('E5', 9.1, 0.06),
          NoteEvent('G5', 9.2, 0.06),
          NoteEvent('E5', 9.3, 0.06),
          NoteEvent('G5', 9.4, 0.06),
          NoteEvent('E5', 9.5, 0.05),
          NoteEvent('G5', 9.58, 0.05),
          NoteEvent('E5', 9.66, 0.05),
          NoteEvent('G5', 9.74, 0.05),
          NoteEvent('E5', 9.82, 0.05),
          NoteEvent('G5', 9.9, 0.08),
          // Peak harmony
          NoteEvent('E5', 10.05, 0.1),
          NoteEvent('G5', 10.2, 0.1),
          NoteEvent('G5', 10.35, 0.12),
          // Final sustain
          NoteEvent('E5', 10.6, 0.22),
          NoteEvent('G5', 10.9, 0.22),
          NoteEvent('E5', 11.2, 0.95),
        ],
      ),
      // Bass - driving foundation that builds
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.35,
        notes: [
          // Loop 1 - steady
          NoteEvent('C2', 0.0, 0.35),
          NoteEvent('E2', 0.4, 0.35),
          NoteEvent('G2', 0.8, 0.35),
          NoteEvent('C3', 1.2, 0.35),
          NoteEvent('G2', 1.7, 0.25),
          NoteEvent('C2', 2.0, 0.25),
          // Loop 2 - more active
          NoteEvent('C2', 2.3, 0.25),
          NoteEvent('C3', 2.6, 0.25),
          NoteEvent('G2', 2.9, 0.25),
          NoteEvent('C3', 3.2, 0.25),
          NoteEvent('E3', 3.5, 0.15),
          NoteEvent('G3', 3.66, 0.25),
          NoteEvent('G2', 3.95, 0.2),
          NoteEvent('C2', 4.2, 0.35),
          // Loop 3 - pumping
          NoteEvent('C2', 4.6, 0.15),
          NoteEvent('C3', 4.78, 0.12),
          NoteEvent('G2', 4.9, 0.12),
          NoteEvent('D3', 5.05, 0.12),
          NoteEvent('D2', 5.23, 0.1),
          NoteEvent('C3', 5.35, 0.15),
          NoteEvent('G2', 5.6, 0.12),
          // Fanfare bass - majestic
          NoteEvent('C2', 5.85, 0.35),
          NoteEvent('G2', 6.25, 0.25),
          NoteEvent('C3', 6.55, 0.25),
          NoteEvent('G2', 6.85, 0.3),
          NoteEvent('C2', 7.2, 0.25),
          NoteEvent('G2', 7.5, 0.15),
          NoteEvent('C3', 7.7, 0.3),
          NoteEvent('G2', 8.05, 0.2),
          NoteEvent('C3', 8.3, 0.12),
          NoteEvent('G2', 8.45, 0.2),
          NoteEvent('C3', 8.7, 0.15),
          // Big hit bass - PUMPING
          NoteEvent('C2', 8.9, 0.08),
          NoteEvent('C3', 9.0, 0.08),
          NoteEvent('C2', 9.1, 0.08),
          NoteEvent('C3', 9.2, 0.08),
          NoteEvent('C2', 9.3, 0.08),
          NoteEvent('C3', 9.4, 0.08),
          NoteEvent('G2', 9.5, 0.06),
          NoteEvent('C3', 9.58, 0.06),
          NoteEvent('G2', 9.66, 0.06),
          NoteEvent('C3', 9.74, 0.06),
          NoteEvent('G2', 9.82, 0.06),
          NoteEvent('C3', 9.9, 0.1),
          // Peak bass
          NoteEvent('C2', 10.05, 0.12),
          NoteEvent('G2', 10.2, 0.12),
          NoteEvent('C3', 10.35, 0.2),
          // Final sustain
          NoteEvent('G2', 10.6, 0.25),
          NoteEvent('C3', 10.9, 0.25),
          NoteEvent('C2', 11.2, 1.0),
        ],
      ),
      // Sparkle layer - builds excitement
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.18,
        attack: 0.003,
        notes: [
          // Loop 1 - subtle
          NoteEvent('E6', 1.4, 0.1),
          // Loop 2 - more present
          NoteEvent('C6', 3.36, 0.08),
          NoteEvent('E6', 3.66, 0.12),
          // Loop 3 - full sparkle
          NoteEvent('G5', 4.9, 0.06),
          NoteEvent('D6', 5.23, 0.06),
          NoteEvent('E6', 5.35, 0.1),
          NoteEvent('E6', 5.6, 0.1),
          // Fanfare sparkle - celebratory shimmer
          NoteEvent('G5', 6.05, 0.06),
          NoteEvent('C6', 6.15, 0.06),
          NoteEvent('E6', 6.25, 0.15),
          NoteEvent('G5', 6.7, 0.08),
          NoteEvent('E6', 6.85, 0.18),
          NoteEvent('C6', 7.4, 0.06),
          NoteEvent('E6', 7.5, 0.1),
          NoteEvent('G5', 7.7, 0.18),
          NoteEvent('C6', 8.18, 0.08),
          NoteEvent('E6', 8.3, 0.08),
          NoteEvent('C6', 8.58, 0.08),
          NoteEvent('E6', 8.7, 0.08),
          // Big hit sparkle - rapid fire shimmer
          NoteEvent('G5', 8.9, 0.05),
          NoteEvent('C6', 9.0, 0.05),
          NoteEvent('E6', 9.1, 0.05),
          NoteEvent('G5', 9.2, 0.05),
          NoteEvent('C6', 9.3, 0.05),
          NoteEvent('E6', 9.4, 0.05),
          NoteEvent('G5', 9.5, 0.04),
          NoteEvent('C6', 9.58, 0.04),
          NoteEvent('E6', 9.66, 0.04),
          NoteEvent('G5', 9.74, 0.04),
          NoteEvent('C6', 9.82, 0.04),
          NoteEvent('E6', 9.9, 0.08),
          // Peak sparkle
          NoteEvent('G5', 10.05, 0.08),
          NoteEvent('C6', 10.2, 0.08),
          NoteEvent('E6', 10.35, 0.12),
          // Final shimmer
          NoteEvent('G5', 10.6, 0.2),
          NoteEvent('C6', 10.9, 0.2),
          NoteEvent('G5', 11.2, 0.9),
        ],
      ),
    ];
  }

  /// 7-day streak pattern: Slow, warm, jubilatory serenade
  /// Acknowledges consistent effort with respectful, building celebration
  static List<Voice> _streak7Pattern() {
    return [
      // Lead melody - warm, sincere, slowly building
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.4, // Warmer, rounder tone
        volume: 0.35,
        attack: 0.015, // Softer attack
        decay: 0.06,
        sustain: 0.6,
        release: 0.12,
        notes: [
          // === OPENING: Soft acknowledgment ===
          NoteEvent('G3', 0.0, 0.28),
          NoteEvent('A3', 0.35, 0.21),
          NoteEvent('B3', 0.63, 0.25),
          NoteEvent('D4', 0.95, 0.35),

          // === VERSE 1: The journey theme ===
          NoteEvent('G4', 1.4, 0.25),
          NoteEvent('A4', 1.68, 0.18),
          NoteEvent('B4', 1.89, 0.25),
          NoteEvent('A4', 2.17, 0.18),
          NoteEvent('G4', 2.38, 0.35),
          // Second phrase
          NoteEvent('D4', 2.8, 0.21),
          NoteEvent('E4', 3.05, 0.18),
          NoteEvent('G4', 3.26, 0.25),
          NoteEvent('A4', 3.54, 0.35),

          // === VERSE 2: Theme repeats, fuller ===
          NoteEvent('G4', 4.0, 0.21),
          NoteEvent('A4', 4.24, 0.15),
          NoteEvent('B4', 4.42, 0.21),
          NoteEvent('D5', 4.7, 0.25),
          NoteEvent('E5', 4.97, 0.18),
          NoteEvent('D5', 5.18, 0.25),
          // Rising answer
          NoteEvent('B4', 5.5, 0.18),
          NoteEvent('D5', 5.71, 0.18),
          NoteEvent('E5', 5.92, 0.21),
          NoteEvent('G5', 6.16, 0.35),

          // === CELEBRATION: Earned jubilation ===
          NoteEvent('G4', 6.62, 0.14),
          NoteEvent('B4', 6.79, 0.14),
          NoteEvent('D5', 6.97, 0.18),
          NoteEvent('G5', 7.18, 0.28),
          // Answering phrase
          NoteEvent('E5', 7.53, 0.14),
          NoteEvent('G5', 7.7, 0.14),
          NoteEvent('A5', 7.88, 0.25),
          // Final warm flourish - ending high
          NoteEvent('G5', 8.19, 0.14),
          NoteEvent('B5', 8.37, 0.14),
          NoteEvent('G5', 8.54, 0.18),
          NoteEvent('B5', 8.75, 0.14),
          NoteEvent('G5', 8.93, 0.7),
        ],
      ),
      // Harmony - warm thirds and fifths, enters gradually
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.5,
        volume: 0.2,
        attack: 0.018,
        decay: 0.07,
        sustain: 0.5,
        release: 0.14,
        notes: [
          // Light support in verse 1
          NoteEvent('D4', 1.4, 0.21),
          NoteEvent('D4', 1.89, 0.21),
          NoteEvent('B3', 2.38, 0.32),
          NoteEvent('B3', 3.26, 0.21),
          NoteEvent('D4', 3.54, 0.32),
          // Fuller in verse 2
          NoteEvent('D4', 4.0, 0.18),
          NoteEvent('D4', 4.42, 0.18),
          NoteEvent('G4', 4.7, 0.21),
          NoteEvent('B4', 4.97, 0.15),
          NoteEvent('G4', 5.18, 0.21),
          NoteEvent('G4', 5.71, 0.15),
          NoteEvent('B4', 5.92, 0.18),
          NoteEvent('D5', 6.16, 0.32),
          // Full harmony in celebration
          NoteEvent('D5', 6.97, 0.15),
          NoteEvent('D5', 7.18, 0.25),
          NoteEvent('B4', 7.53, 0.13),
          NoteEvent('D5', 7.7, 0.13),
          NoteEvent('E5', 7.88, 0.21),
          NoteEvent('D5', 8.19, 0.13),
          NoteEvent('G5', 8.37, 0.13),
          NoteEvent('D5', 8.54, 0.15),
          NoteEvent('G5', 8.75, 0.13),
          NoteEvent('D5', 8.93, 0.65),
        ],
      ),
      // Bass - warm, steady foundation
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.38,
        attack: 0.02,
        release: 0.14,
        notes: [
          // Opening - sparse, respectful
          NoteEvent('G2', 0.0, 0.56),
          NoteEvent('D2', 0.95, 0.39),
          // Verse 1 - gentle pulse
          NoteEvent('G2', 1.4, 0.49),
          NoteEvent('D2', 1.89, 0.46),
          NoteEvent('G2', 2.38, 0.39),
          NoteEvent('G2', 2.8, 0.42),
          NoteEvent('D2', 3.26, 0.25),
          NoteEvent('D3', 3.54, 0.39),
          // Verse 2 - more present
          NoteEvent('G2', 4.0, 0.39),
          NoteEvent('G2', 4.42, 0.25),
          NoteEvent('G2', 4.7, 0.25),
          NoteEvent('E2', 4.97, 0.18),
          NoteEvent('D2', 5.18, 0.28),
          NoteEvent('G2', 5.5, 0.18),
          NoteEvent('D2', 5.71, 0.18),
          NoteEvent('E2', 5.92, 0.21),
          NoteEvent('G2', 6.16, 0.39),
          // Celebration - warm, full
          NoteEvent('G2', 6.62, 0.32),
          NoteEvent('G2', 6.97, 0.18),
          NoteEvent('G3', 7.18, 0.32),
          NoteEvent('E2', 7.53, 0.28),
          NoteEvent('D2', 7.88, 0.28),
          NoteEvent('G2', 8.19, 0.25),
          NoteEvent('G2', 8.54, 0.18),
          NoteEvent('G3', 8.75, 0.14),
          NoteEvent('G2', 8.93, 0.7),
        ],
      ),
      // Shimmer layer - gentle sparkle, more present in celebration
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.12,
        attack: 0.007,
        decay: 0.035,
        sustain: 0.4,
        notes: [
          // Subtle touches in verses
          NoteEvent('D5', 0.95, 0.11),
          NoteEvent('G5', 2.38, 0.11),
          NoteEvent('D5', 3.54, 0.11),
          NoteEvent('G5', 4.7, 0.08),
          NoteEvent('D6', 6.16, 0.14),
          // Fuller sparkle in celebration
          NoteEvent('D5', 6.97, 0.08),
          NoteEvent('G5', 7.18, 0.14),
          NoteEvent('D5', 7.53, 0.07),
          NoteEvent('G5', 7.7, 0.07),
          NoteEvent('A5', 7.88, 0.13),
          NoteEvent('B5', 8.19, 0.07),
          NoteEvent('D6', 8.37, 0.07),
          NoteEvent('G5', 8.54, 0.08),
          NoteEvent('D6', 8.75, 0.08),
          NoteEvent('G5', 8.93, 0.6),
        ],
      ),
    ];
  }

  /// 14-day streak pattern: Fuller arrangement with countermelody
  /// Builds on 7-day theme but with more voices and longer celebration
  static List<Voice> _streak14Pattern() {
    return [
      // Lead melody - same warm character, extended phrases
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.4,
        volume: 0.35,
        attack: 0.015,
        decay: 0.06,
        sustain: 0.6,
        release: 0.12,
        notes: [
          // === OPENING: Warm acknowledgment ===
          NoteEvent('G3', 0.0, 0.28),
          NoteEvent('A3', 0.35, 0.21),
          NoteEvent('B3', 0.63, 0.25),
          NoteEvent('D4', 0.95, 0.35),

          // === VERSE 1: Journey theme ===
          NoteEvent('G4', 1.4, 0.25),
          NoteEvent('A4', 1.68, 0.18),
          NoteEvent('B4', 1.89, 0.25),
          NoteEvent('A4', 2.17, 0.18),
          NoteEvent('G4', 2.38, 0.35),
          NoteEvent('D4', 2.8, 0.21),
          NoteEvent('E4', 3.05, 0.18),
          NoteEvent('G4', 3.26, 0.25),
          NoteEvent('A4', 3.54, 0.35),

          // === VERSE 2: Theme repeats, fuller ===
          NoteEvent('G4', 4.0, 0.21),
          NoteEvent('A4', 4.24, 0.15),
          NoteEvent('B4', 4.42, 0.21),
          NoteEvent('D5', 4.7, 0.25),
          NoteEvent('E5', 4.97, 0.18),
          NoteEvent('D5', 5.18, 0.25),
          NoteEvent('B4', 5.5, 0.18),
          NoteEvent('D5', 5.71, 0.18),
          NoteEvent('E5', 5.92, 0.21),
          NoteEvent('G5', 6.16, 0.35),

          // === BRIDGE: New ascending phrase ===
          NoteEvent('G4', 6.65, 0.18),
          NoteEvent('A4', 6.86, 0.18),
          NoteEvent('B4', 7.07, 0.18),
          NoteEvent('D5', 7.28, 0.21),
          NoteEvent('E5', 7.52, 0.18),
          NoteEvent('G5', 7.73, 0.25),
          NoteEvent('A5', 8.01, 0.35),

          // === CELEBRATION: Earned jubilation ===
          NoteEvent('G4', 8.5, 0.14),
          NoteEvent('B4', 8.67, 0.14),
          NoteEvent('D5', 8.85, 0.18),
          NoteEvent('G5', 9.06, 0.28),
          NoteEvent('E5', 9.41, 0.14),
          NoteEvent('G5', 9.58, 0.14),
          NoteEvent('A5', 9.76, 0.25),

          // === EXTENDED FINALE ===
          NoteEvent('G5', 10.1, 0.14),
          NoteEvent('B5', 10.28, 0.14),
          NoteEvent('A5', 10.45, 0.18),
          NoteEvent('G5', 10.66, 0.14),
          NoteEvent('E5', 10.84, 0.14),
          NoteEvent('G5', 11.02, 0.21),
          NoteEvent('B5', 11.28, 0.14),
          NoteEvent('A5', 11.45, 0.14),
          NoteEvent('G5', 11.63, 0.8),
        ],
      ),
      // Countermelody - enters in verse 2, weaves with lead
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.35,
        volume: 0.22,
        attack: 0.018,
        decay: 0.06,
        sustain: 0.5,
        release: 0.14,
        notes: [
          // Enters at verse 2
          NoteEvent('D4', 4.42, 0.18),
          NoteEvent('E4', 4.7, 0.21),
          NoteEvent('G4', 4.97, 0.15),
          NoteEvent('A4', 5.18, 0.21),
          NoteEvent('G4', 5.5, 0.15),
          NoteEvent('A4', 5.71, 0.15),
          NoteEvent('B4', 5.92, 0.18),
          NoteEvent('D5', 6.16, 0.32),
          // Bridge counterpoint
          NoteEvent('D4', 6.65, 0.15),
          NoteEvent('E4', 6.86, 0.15),
          NoteEvent('G4', 7.07, 0.15),
          NoteEvent('A4', 7.28, 0.18),
          NoteEvent('B4', 7.52, 0.15),
          NoteEvent('D5', 7.73, 0.21),
          NoteEvent('E5', 8.01, 0.32),
          // Celebration harmony
          NoteEvent('D5', 8.85, 0.15),
          NoteEvent('D5', 9.06, 0.25),
          NoteEvent('B4', 9.41, 0.13),
          NoteEvent('D5', 9.58, 0.13),
          NoteEvent('E5', 9.76, 0.21),
          // Finale harmony
          NoteEvent('D5', 10.1, 0.13),
          NoteEvent('G5', 10.28, 0.13),
          NoteEvent('E5', 10.45, 0.15),
          NoteEvent('D5', 10.66, 0.13),
          NoteEvent('B4', 10.84, 0.13),
          NoteEvent('D5', 11.02, 0.18),
          NoteEvent('G5', 11.28, 0.13),
          NoteEvent('E5', 11.45, 0.13),
          NoteEvent('D5', 11.63, 0.75),
        ],
      ),
      // Harmony - warm thirds and fifths
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.5,
        volume: 0.18,
        attack: 0.018,
        decay: 0.07,
        sustain: 0.5,
        release: 0.14,
        notes: [
          NoteEvent('D4', 1.4, 0.21),
          NoteEvent('D4', 1.89, 0.21),
          NoteEvent('B3', 2.38, 0.32),
          NoteEvent('B3', 3.26, 0.21),
          NoteEvent('D4', 3.54, 0.32),
          NoteEvent('D4', 4.0, 0.18),
          NoteEvent('G4', 4.7, 0.21),
          NoteEvent('G4', 5.71, 0.15),
          NoteEvent('B4', 5.92, 0.18),
          NoteEvent('D5', 6.16, 0.32),
          NoteEvent('D5', 8.85, 0.15),
          NoteEvent('D5', 9.06, 0.25),
          NoteEvent('E5', 9.76, 0.21),
          NoteEvent('D5', 11.63, 0.75),
        ],
      ),
      // Bass - warm, steady foundation
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.38,
        attack: 0.02,
        release: 0.14,
        notes: [
          NoteEvent('G2', 0.0, 0.56),
          NoteEvent('D2', 0.95, 0.39),
          NoteEvent('G2', 1.4, 0.49),
          NoteEvent('D2', 1.89, 0.46),
          NoteEvent('G2', 2.38, 0.39),
          NoteEvent('G2', 2.8, 0.42),
          NoteEvent('D2', 3.26, 0.25),
          NoteEvent('D3', 3.54, 0.39),
          NoteEvent('G2', 4.0, 0.39),
          NoteEvent('G2', 4.42, 0.25),
          NoteEvent('G2', 4.7, 0.25),
          NoteEvent('E2', 4.97, 0.18),
          NoteEvent('D2', 5.18, 0.28),
          NoteEvent('G2', 5.5, 0.18),
          NoteEvent('D2', 5.71, 0.18),
          NoteEvent('E2', 5.92, 0.21),
          NoteEvent('G2', 6.16, 0.42),
          // Bridge bass
          NoteEvent('G2', 6.65, 0.39),
          NoteEvent('D2', 7.07, 0.18),
          NoteEvent('G2', 7.28, 0.21),
          NoteEvent('D2', 7.52, 0.18),
          NoteEvent('E2', 7.73, 0.25),
          NoteEvent('A2', 8.01, 0.42),
          // Celebration bass
          NoteEvent('G2', 8.5, 0.32),
          NoteEvent('G2', 8.85, 0.18),
          NoteEvent('G3', 9.06, 0.32),
          NoteEvent('E2', 9.41, 0.28),
          NoteEvent('D2', 9.76, 0.28),
          // Finale bass
          NoteEvent('G2', 10.1, 0.25),
          NoteEvent('G2', 10.45, 0.18),
          NoteEvent('E2', 10.66, 0.15),
          NoteEvent('D2', 10.84, 0.15),
          NoteEvent('G2', 11.02, 0.23),
          NoteEvent('D2', 11.28, 0.32),
          NoteEvent('G2', 11.63, 0.8),
        ],
      ),
      // Shimmer - sparkle accents
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.12,
        attack: 0.007,
        decay: 0.035,
        sustain: 0.4,
        notes: [
          NoteEvent('D5', 0.95, 0.11),
          NoteEvent('G5', 2.38, 0.11),
          NoteEvent('D5', 3.54, 0.11),
          NoteEvent('G5', 4.7, 0.08),
          NoteEvent('D6', 6.16, 0.14),
          NoteEvent('A5', 8.01, 0.14),
          NoteEvent('G5', 9.06, 0.14),
          NoteEvent('A5', 9.76, 0.13),
          NoteEvent('B5', 10.28, 0.08),
          NoteEvent('G5', 11.02, 0.12),
          NoteEvent('B5', 11.28, 0.08),
          NoteEvent('G5', 11.63, 0.7),
        ],
      ),
    ];
  }

  /// 30-day streak pattern: Grand, triumphant celebration
  /// Multiple sections with key change, full orchestration, majestic finale
  static List<Voice> _streak30Pattern() {
    return [
      // Lead melody - majestic theme with key modulation
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.4,
        volume: 0.38,
        attack: 0.012,
        decay: 0.05,
        sustain: 0.65,
        release: 0.12,
        notes: [
          // === FANFARE INTRO (G major) ===
          NoteEvent('G3', 0.0, 0.14),
          NoteEvent('D4', 0.14, 0.14),
          NoteEvent('G4', 0.28, 0.14),
          NoteEvent('B4', 0.42, 0.21),
          NoteEvent('D5', 0.7, 0.35),

          // === VERSE 1: The journey (G major) ===
          NoteEvent('G4', 1.2, 0.25),
          NoteEvent('A4', 1.48, 0.18),
          NoteEvent('B4', 1.69, 0.25),
          NoteEvent('D5', 1.97, 0.32),
          NoteEvent('E5', 2.32, 0.18),
          NoteEvent('D5', 2.53, 0.18),
          NoteEvent('B4', 2.74, 0.25),
          NoteEvent('A4', 3.02, 0.18),
          NoteEvent('G4', 3.23, 0.35),

          // === VERSE 2: Building (G major) ===
          NoteEvent('B4', 3.7, 0.21),
          NoteEvent('D5', 3.94, 0.18),
          NoteEvent('E5', 4.15, 0.25),
          NoteEvent('G5', 4.43, 0.32),
          NoteEvent('A5', 4.78, 0.21),
          NoteEvent('G5', 5.02, 0.18),
          NoteEvent('E5', 5.23, 0.18),
          NoteEvent('D5', 5.44, 0.25),
          NoteEvent('B4', 5.72, 0.18),
          NoteEvent('D5', 5.93, 0.35),

          // === BRIDGE: Key change to A major (lift!) ===
          NoteEvent('A4', 6.4, 0.21),
          NoteEvent('B4', 6.64, 0.18),
          NoteEvent('C5', 6.85, 0.21), // C# in A major
          NoteEvent('E5', 7.09, 0.25),
          NoteEvent('A5', 7.4, 0.32),
          NoteEvent('B5', 7.75, 0.18),
          NoteEvent('A5', 7.96, 0.18),
          NoteEvent('E5', 8.17, 0.21),
          NoteEvent('C5', 8.41, 0.18),
          NoteEvent('A4', 8.62, 0.35),

          // === VERSE 3: Peak theme (back to G major, higher) ===
          NoteEvent('G4', 9.1, 0.14),
          NoteEvent('B4', 9.27, 0.14),
          NoteEvent('D5', 9.44, 0.18),
          NoteEvent('G5', 9.65, 0.28),
          NoteEvent('A5', 9.96, 0.18),
          NoteEvent('B5', 10.17, 0.25),
          NoteEvent('A5', 10.45, 0.18),
          NoteEvent('G5', 10.66, 0.32),

          // === GRAND CELEBRATION ===
          NoteEvent('G5', 11.1, 0.14),
          NoteEvent('A5', 11.27, 0.14),
          NoteEvent('B5', 11.44, 0.18),
          NoteEvent('D6', 11.65, 0.28),
          NoteEvent('B5', 12.0, 0.14),
          NoteEvent('D6', 12.17, 0.14),
          NoteEvent('E6', 12.34, 0.25),

          // === TRIUMPHANT FANFARE FINALE ===
          NoteEvent('G5', 12.7, 0.12),
          NoteEvent('B5', 12.85, 0.12),
          NoteEvent('D6', 13.0, 0.14),
          NoteEvent('G5', 13.17, 0.12),
          NoteEvent('B5', 13.32, 0.12),
          NoteEvent('D6', 13.47, 0.14),
          NoteEvent('E6', 13.64, 0.18),
          // Final ascent
          NoteEvent('D6', 13.9, 0.12),
          NoteEvent('E6', 14.05, 0.12),
          NoteEvent('G5', 14.2, 0.12),
          NoteEvent('B5', 14.35, 0.12),
          NoteEvent('D6', 14.5, 0.14),
          NoteEvent('E6', 14.67, 0.14),
          // Crown
          NoteEvent('D6', 14.9, 0.25),
          NoteEvent('G5', 15.2, 0.2),
          NoteEvent('B5', 15.45, 0.2),
          NoteEvent('D6', 15.7, 1.0),
        ],
      ),
      // Countermelody - weaves throughout
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.35,
        volume: 0.24,
        attack: 0.015,
        decay: 0.05,
        sustain: 0.55,
        release: 0.12,
        notes: [
          // Intro answer
          NoteEvent('D4', 0.42, 0.18),
          NoteEvent('G4', 0.7, 0.32),
          // Verse 1 counterpoint
          NoteEvent('D4', 1.2, 0.21),
          NoteEvent('D4', 1.69, 0.21),
          NoteEvent('G4', 1.97, 0.28),
          NoteEvent('B4', 2.32, 0.15),
          NoteEvent('G4', 2.53, 0.15),
          NoteEvent('D4', 2.74, 0.21),
          NoteEvent('E4', 3.02, 0.15),
          NoteEvent('D4', 3.23, 0.32),
          // Verse 2 counterpoint
          NoteEvent('G4', 3.7, 0.18),
          NoteEvent('A4', 3.94, 0.15),
          NoteEvent('B4', 4.15, 0.21),
          NoteEvent('D5', 4.43, 0.28),
          NoteEvent('E5', 4.78, 0.18),
          NoteEvent('D5', 5.02, 0.15),
          NoteEvent('B4', 5.23, 0.15),
          NoteEvent('A4', 5.44, 0.21),
          NoteEvent('G4', 5.72, 0.15),
          NoteEvent('A4', 5.93, 0.32),
          // Bridge counterpoint (A major)
          NoteEvent('E4', 6.4, 0.18),
          NoteEvent('E4', 6.64, 0.15),
          NoteEvent('A4', 6.85, 0.18),
          NoteEvent('C5', 7.09, 0.21),
          NoteEvent('E5', 7.4, 0.28),
          NoteEvent('E5', 7.75, 0.15),
          NoteEvent('C5', 7.96, 0.15),
          NoteEvent('A4', 8.17, 0.18),
          NoteEvent('E4', 8.41, 0.15),
          NoteEvent('E4', 8.62, 0.32),
          // Verse 3 counterpoint
          NoteEvent('D4', 9.1, 0.12),
          NoteEvent('G4', 9.27, 0.12),
          NoteEvent('A4', 9.44, 0.15),
          NoteEvent('D5', 9.65, 0.25),
          NoteEvent('E5', 9.96, 0.15),
          NoteEvent('G5', 10.17, 0.21),
          NoteEvent('E5', 10.45, 0.15),
          NoteEvent('D5', 10.66, 0.28),
          // Celebration counterpoint
          NoteEvent('D5', 11.1, 0.12),
          NoteEvent('E5', 11.27, 0.12),
          NoteEvent('G5', 11.44, 0.15),
          NoteEvent('A5', 11.65, 0.25),
          NoteEvent('G5', 12.0, 0.12),
          NoteEvent('A5', 12.17, 0.12),
          NoteEvent('B5', 12.34, 0.21),
          // Fanfare harmony
          NoteEvent('D5', 12.7, 0.1),
          NoteEvent('G5', 12.85, 0.1),
          NoteEvent('A5', 13.0, 0.12),
          NoteEvent('D5', 13.17, 0.1),
          NoteEvent('G5', 13.32, 0.1),
          NoteEvent('A5', 13.47, 0.12),
          NoteEvent('B5', 13.64, 0.15),
          // Final ascent harmony
          NoteEvent('A5', 13.9, 0.1),
          NoteEvent('B5', 14.05, 0.1),
          NoteEvent('D5', 14.2, 0.1),
          NoteEvent('G5', 14.35, 0.1),
          NoteEvent('A5', 14.5, 0.12),
          NoteEvent('B5', 14.67, 0.12),
          // Crown harmony
          NoteEvent('A5', 14.9, 0.22),
          NoteEvent('D5', 15.2, 0.18),
          NoteEvent('G5', 15.45, 0.18),
          NoteEvent('A5', 15.7, 0.95),
        ],
      ),
      // Harmony - thirds and fifths
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.5,
        volume: 0.16,
        attack: 0.018,
        decay: 0.06,
        sustain: 0.5,
        release: 0.14,
        notes: [
          NoteEvent('B3', 0.7, 0.32),
          NoteEvent('B4', 1.97, 0.28),
          NoteEvent('D4', 3.23, 0.32),
          NoteEvent('D5', 4.43, 0.28),
          NoteEvent('A4', 5.93, 0.32),
          NoteEvent('C5', 7.4, 0.28),
          NoteEvent('E4', 8.62, 0.32),
          NoteEvent('D5', 9.65, 0.25),
          NoteEvent('D5', 10.66, 0.28),
          NoteEvent('G5', 11.65, 0.25),
          NoteEvent('G5', 12.34, 0.21),
          NoteEvent('G5', 13.64, 0.15),
          NoteEvent('G5', 14.67, 0.12),
          NoteEvent('G5', 15.7, 0.9),
        ],
      ),
      // Bass - majestic foundation
      Voice(
        waveform: WaveformType.triangle,
        volume: 0.4,
        attack: 0.018,
        release: 0.14,
        notes: [
          // Fanfare intro
          NoteEvent('G2', 0.0, 0.39),
          NoteEvent('G2', 0.42, 0.25),
          NoteEvent('G3', 0.7, 0.42),
          // Verse 1
          NoteEvent('G2', 1.2, 0.46),
          NoteEvent('D2', 1.69, 0.25),
          NoteEvent('G2', 1.97, 0.32),
          NoteEvent('E2', 2.32, 0.18),
          NoteEvent('D2', 2.53, 0.18),
          NoteEvent('G2', 2.74, 0.25),
          NoteEvent('D2', 3.02, 0.18),
          NoteEvent('G2', 3.23, 0.42),
          // Verse 2
          NoteEvent('G2', 3.7, 0.21),
          NoteEvent('D2', 3.94, 0.18),
          NoteEvent('E2', 4.15, 0.25),
          NoteEvent('G2', 4.43, 0.32),
          NoteEvent('D2', 4.78, 0.21),
          NoteEvent('E2', 5.02, 0.18),
          NoteEvent('G2', 5.23, 0.18),
          NoteEvent('D2', 5.44, 0.25),
          NoteEvent('G2', 5.72, 0.18),
          NoteEvent('D2', 5.93, 0.42),
          // Bridge (A major)
          NoteEvent('A2', 6.4, 0.21),
          NoteEvent('E2', 6.64, 0.18),
          NoteEvent('A2', 6.85, 0.21),
          NoteEvent('A2', 7.09, 0.28),
          NoteEvent('A3', 7.4, 0.32),
          NoteEvent('E2', 7.75, 0.18),
          NoteEvent('A2', 7.96, 0.18),
          NoteEvent('E2', 8.17, 0.21),
          NoteEvent('A2', 8.41, 0.18),
          NoteEvent('A2', 8.62, 0.42),
          // Verse 3
          NoteEvent('G2', 9.1, 0.14),
          NoteEvent('G2', 9.27, 0.14),
          NoteEvent('D2', 9.44, 0.18),
          NoteEvent('G2', 9.65, 0.28),
          NoteEvent('D2', 9.96, 0.18),
          NoteEvent('G2', 10.17, 0.25),
          NoteEvent('D2', 10.45, 0.18),
          NoteEvent('G2', 10.66, 0.39),
          // Grand celebration
          NoteEvent('G2', 11.1, 0.14),
          NoteEvent('D2', 11.27, 0.14),
          NoteEvent('G2', 11.44, 0.18),
          NoteEvent('G3', 11.65, 0.32),
          NoteEvent('D2', 12.0, 0.14),
          NoteEvent('G2', 12.17, 0.14),
          NoteEvent('E2', 12.34, 0.32),
          // Fanfare finale
          NoteEvent('G2', 12.7, 0.12),
          NoteEvent('G2', 12.85, 0.12),
          NoteEvent('D2', 13.0, 0.14),
          NoteEvent('G2', 13.17, 0.12),
          NoteEvent('G2', 13.32, 0.12),
          NoteEvent('D2', 13.47, 0.14),
          NoteEvent('G2', 13.64, 0.21),
          // Final ascent
          NoteEvent('D2', 13.9, 0.12),
          NoteEvent('E2', 14.05, 0.12),
          NoteEvent('G2', 14.2, 0.12),
          NoteEvent('D2', 14.35, 0.12),
          NoteEvent('G2', 14.5, 0.14),
          NoteEvent('D2', 14.67, 0.14),
          // Crown
          NoteEvent('G2', 14.9, 0.25),
          NoteEvent('D2', 15.2, 0.2),
          NoteEvent('G2', 15.45, 0.2),
          NoteEvent('G2', 15.7, 1.0),
        ],
      ),
      // Sparkle layer - celebratory shimmer
      Voice(
        waveform: WaveformType.square,
        dutyCycle: 0.125,
        volume: 0.14,
        attack: 0.006,
        decay: 0.03,
        sustain: 0.45,
        notes: [
          NoteEvent('D5', 0.7, 0.12),
          NoteEvent('D5', 1.97, 0.1),
          NoteEvent('G5', 3.23, 0.1),
          NoteEvent('G5', 4.43, 0.1),
          NoteEvent('D5', 5.93, 0.1),
          NoteEvent('A5', 7.4, 0.12),
          NoteEvent('E5', 8.62, 0.1),
          NoteEvent('G5', 9.65, 0.12),
          NoteEvent('G5', 10.66, 0.1),
          NoteEvent('D6', 11.65, 0.12),
          NoteEvent('E6', 12.34, 0.1),
          // Fanfare sparkle
          NoteEvent('D6', 12.7, 0.08),
          NoteEvent('D6', 13.0, 0.08),
          NoteEvent('D6', 13.47, 0.08),
          NoteEvent('E6', 13.64, 0.12),
          NoteEvent('D6', 14.5, 0.08),
          NoteEvent('E6', 14.67, 0.08),
          // Crown sparkle
          NoteEvent('D6', 14.9, 0.18),
          NoteEvent('G5', 15.2, 0.14),
          NoteEvent('B5', 15.45, 0.14),
          NoteEvent('G5', 15.7, 0.9),
        ],
      ),
      // Fanfare brass layer - only in finale
      Voice(
        waveform: WaveformType.sawtooth,
        volume: 0.12,
        attack: 0.01,
        decay: 0.04,
        sustain: 0.6,
        release: 0.1,
        notes: [
          // Grand celebration brass
          NoteEvent('G4', 11.65, 0.25),
          NoteEvent('G4', 12.34, 0.21),
          // Fanfare finale brass
          NoteEvent('G4', 12.7, 0.1),
          NoteEvent('G4', 13.0, 0.12),
          NoteEvent('G4', 13.47, 0.12),
          NoteEvent('G4', 13.64, 0.15),
          NoteEvent('G4', 14.5, 0.12),
          NoteEvent('G4', 14.67, 0.12),
          // Crown brass
          NoteEvent('G4', 14.9, 0.22),
          NoteEvent('D4', 15.2, 0.18),
          NoteEvent('G4', 15.45, 0.18),
          NoteEvent('G4', 15.7, 0.95),
        ],
      ),
    ];
  }

  // ==========================================================================
  // RENDERING HELPERS
  // ==========================================================================

  /// Render a complete pattern (multiple voices) to samples.
  static List<double> _renderPattern(List<Voice> voices) {
    // Find total duration
    double maxTime = 0;
    for (final voice in voices) {
      for (final note in voice.notes) {
        final endTime = note.startTime + note.duration;
        if (endTime > maxTime) maxTime = endTime;
      }
    }

    // Add a little tail for release
    maxTime += 0.3;

    final totalSamples = (maxTime * sampleRate).round();
    final mixed = List<double>.filled(totalSamples, 0.0);

    // Render each voice
    for (final voice in voices) {
      for (final note in voice.notes) {
        final noteSamples = renderNote(
          note: note.note,
          duration: note.duration,
          waveform: voice.waveform,
          volume: voice.volume,
          dutyCycle: voice.dutyCycle,
          attack: voice.attack,
          decay: voice.decay,
          sustain: voice.sustain,
          release: voice.release,
        );

        // Mix into output at correct position
        final startSample = (note.startTime * sampleRate).round();
        for (int i = 0; i < noteSamples.length; i++) {
          final idx = startSample + i;
          if (idx < mixed.length) {
            mixed[idx] += noteSamples[i];
          }
        }
      }
    }

    return mixed;
  }

  /// Normalize and convert to final output range.
  static List<double> _mixDown(List<double> samples) {
    // Find peak
    double peak = 0;
    for (final s in samples) {
      if (s.abs() > peak) peak = s.abs();
    }

    // Normalize to 0.8 to leave headroom
    if (peak > 0) {
      final scale = 0.8 / peak;
      for (int i = 0; i < samples.length; i++) {
        samples[i] *= scale;
      }
    }

    return samples;
  }

  /// Convert samples to WAV file bytes.
  static Uint8List _samplesToWav(List<double> samples) {
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = samples.length * 2;
    final int fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // space
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
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Audio samples
    for (final sample in samples) {
      final intSample = (sample * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}

// ==========================================================================
// DATA CLASSES
// ==========================================================================

enum WaveformType { square, triangle, sawtooth, noise }

/// A single note event in a pattern.
class NoteEvent {
  final String note;
  final double startTime;
  final double duration;

  const NoteEvent(this.note, this.startTime, this.duration);
}

/// A voice (instrument) in a pattern.
class Voice {
  final WaveformType waveform;
  final double volume;
  final double dutyCycle;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final List<NoteEvent> notes;

  const Voice({
    required this.waveform,
    required this.notes,
    this.volume = 0.5,
    this.dutyCycle = 0.5,
    this.attack = 0.01,
    this.decay = 0.05,
    this.sustain = 0.7,
    this.release = 0.1,
  });
}
