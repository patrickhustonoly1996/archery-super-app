# Chiptune System

Procedural C64 SID-style chip music generator for celebratory jingles.

## Overview

The app generates authentic 8-bit chiptune sounds at runtime using waveform synthesis. No audio files needed - everything is computed mathematically, producing WAV audio data that plays instantly.

## Architecture

```
lib/services/
├── chiptune_generator.dart  # Pure synthesis engine (no Flutter deps)
└── chiptune_service.dart    # Flutter wrapper with AudioPlayer

tool/
└── generate_jingles.dart    # CLI tool to preview sounds as .wav files
```

## How It Works

### Waveforms (The Building Blocks)

The SID chip in a Commodore 64 produced sounds using simple waveforms:

| Waveform | Sound | Use |
|----------|-------|-----|
| **Square** | Bright, punchy | Lead melodies |
| **Triangle** | Smooth, flute-like | Bass lines |
| **Sawtooth** | Buzzy, rich | Harmony layers |
| **Noise** | Static/hiss | Percussion |

Each waveform is generated sample-by-sample at 44.1kHz:

```dart
// Square wave: on for part of cycle, off for rest
static double squareWave(double phase, {double dutyCycle = 0.5}) {
  return phase % 1.0 < dutyCycle ? 1.0 : -1.0;
}
```

**Duty cycle** controls the "brightness" - 0.5 is classic, 0.25 is more nasal.

### ADSR Envelope

Raw waveforms sound like constant tones. ADSR shapes the volume over time:

```
Volume
  │   /\
  │  /  \___________
  │ /               \
  └──────────────────→ Time
    A  D    S       R

A = Attack (ramp up, ~10ms)
D = Decay (drop to sustain, ~50ms)
S = Sustain (hold level, ~70%)
R = Release (fade out, ~100ms)
```

This makes notes feel "played" rather than synthesized.

### Voices (Instruments)

Each jingle uses multiple simultaneous voices:

```dart
Voice(
  waveform: WaveformType.square,
  dutyCycle: 0.25,        // Bright lead
  volume: 0.4,
  attack: 0.005,
  notes: [
    NoteEvent('C5', 0.0, 0.15),   // Note, start time, duration
    NoteEvent('E5', 0.15, 0.15),
    NoteEvent('G5', 0.30, 0.20),
  ],
)
```

Typical jingle structure:
- **Lead** - Main melody (square wave, narrow duty cycle)
- **Harmony** - Supporting thirds/fifths (square wave, 50% duty)
- **Bass** - Root notes (triangle wave)
- **Sparkle** - High accents (square wave, very narrow duty)

### Pattern Composition

Jingles are composed as musical patterns - collections of voices that play together. The renderer:

1. Calculates total duration from all note events
2. Creates a sample buffer for the full length
3. Renders each voice's notes with their envelopes
4. Mixes voices together additively
5. Normalizes to prevent clipping
6. Encodes as WAV (16-bit PCM, 44.1kHz, mono)

## Available Jingles

| Jingle | Duration | Trigger |
|--------|----------|---------|
| Level Up (×3) | ~3 sec | Gaining a skill level |
| Milestone (×2) | ~5-6 sec | Major levels (10, 25, 50, 75, 92, 99) |
| Achievement (×2) | ~2 sec | Unlocking achievements |
| Personal Best | ~12 sec | New PB score |
| 7-Day Streak | ~10 sec | Training 7 consecutive days |
| 14-Day Streak | ~14 sec | Training 14 consecutive days |
| 30-Day Streak | ~18 sec | Training 30 consecutive days |

## Musical Design Philosophy

### Level Up
Euphoric ascending arpeggios. Three loops building upward, each higher than the last. Feels like climbing stairs to victory.

### Personal Best
Extended version of level-up with a dramatic fanfare finale. Multiple waves of ascending phrases that build in intensity.

### Streak Jingles
Slower, warmer, more respectful. Acknowledges consistent effort rather than a single achievement. Uses G major with walking melodies that feel earned.

- **7-day**: Gentle celebration. "You showed up."
- **14-day**: Fuller arrangement, added countermelody. "This is becoming a habit."
- **30-day**: Grand, triumphant. Multiple voices, key changes. "You're committed."

## Generating Preview Files

```bash
dart run tool/generate_jingles.dart
```

Creates WAV files in `tool/output/` for previewing in any audio player.

## Adding New Jingles

1. Create a pattern method in `ChiptuneGenerator`:
   ```dart
   static List<Voice> _myNewPattern() {
     return [
       Voice(waveform: ..., notes: [...]),
       Voice(waveform: ..., notes: [...]),
     ];
   }
   ```

2. Add a generator method:
   ```dart
   static Uint8List generateMyNewJingle() {
     final samples = <double>[];
     samples.addAll(_renderPattern(_myNewPattern()));
     return _samplesToWav(_mixDown(samples));
   }
   ```

3. Add playback to `ChiptuneService`

4. Update `generate_jingles.dart` for preview

## Notes Reference

All frequencies in Hz, octaves 2-6:

```
C2=65   C3=131  C4=262  C5=523  C6=1047
D2=73   D3=147  D4=294  D5=587  D6=1175
E2=82   E3=165  E4=330  E5=659  E6=1319
...
```

## Performance

- Jingles are generated once at app startup
- Cached as `BytesSource` for instant playback
- Generation is CPU-bound but fast (~50ms per jingle)
- Total memory: ~2MB for all cached sounds
