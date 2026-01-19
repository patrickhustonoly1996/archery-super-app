import 'package:audioplayers/audioplayers.dart';
import 'chiptune_generator.dart';

/// Service for playing procedurally generated chiptune jingles.
/// All sounds are pre-generated at initialization for instant playback.
///
/// Features:
/// - Level-up jingles (3 variations, ~2-3 seconds each)
/// - Milestone jingles (2 variations, ~5-6 seconds each)
/// - Achievement jingles (2 variations, ~1 second each)
///
/// Sounds are generated using C64 SID-style waveforms:
/// square wave leads, triangle bass, sawtooth harmony.
class ChiptuneService {
  static final ChiptuneService _instance = ChiptuneService._internal();
  factory ChiptuneService() => _instance;
  ChiptuneService._internal();

  AudioPlayer? _player;
  bool _initialized = false;
  bool _enabled = true;
  double _volume = 0.5;

  // Pre-generated sounds (cached at init)
  final List<BytesSource> _levelUpSounds = [];
  final List<BytesSource> _milestoneSounds = [];
  final List<BytesSource> _achievementSounds = [];
  BytesSource? _personalBestSound;
  BytesSource? _streak7Sound;
  BytesSource? _streak14Sound;
  BytesSource? _streak30Sound;

  // Track which variation to play next (cycles through)
  int _levelUpIndex = 0;
  int _milestoneIndex = 0;
  int _achievementIndex = 0;

  /// Initialize the chiptune service.
  /// Pre-generates all jingle variations (runs once, caches forever).
  Future<void> initialize() async {
    if (_initialized) return;

    _player = AudioPlayer();
    await _player!.setVolume(_volume);

    // Pre-generate all jingles
    await _generateAllSounds();

    _initialized = true;
  }

  /// Generate all sound variations and cache them.
  Future<void> _generateAllSounds() async {
    // Generate level-up variations (3 patterns)
    for (int i = 0; i < 3; i++) {
      final wav = ChiptuneGenerator.generateLevelUpJingle(variation: i);
      _levelUpSounds.add(BytesSource(wav));
    }

    // Generate milestone variations (2 patterns)
    for (int i = 0; i < 2; i++) {
      final wav = ChiptuneGenerator.generateMilestoneJingle(variation: i);
      _milestoneSounds.add(BytesSource(wav));
    }

    // Generate achievement variations (2 patterns)
    for (int i = 0; i < 2; i++) {
      final wav = ChiptuneGenerator.generateAchievementJingle(variation: i);
      _achievementSounds.add(BytesSource(wav));
    }

    // Generate personal best jingle (single, extended version)
    final pbWav = ChiptuneGenerator.generatePersonalBestJingle();
    _personalBestSound = BytesSource(pbWav);

    // Generate streak jingles
    final streak7Wav = ChiptuneGenerator.generateStreak7Jingle();
    _streak7Sound = BytesSource(streak7Wav);

    final streak14Wav = ChiptuneGenerator.generateStreak14Jingle();
    _streak14Sound = BytesSource(streak14Wav);

    final streak30Wav = ChiptuneGenerator.generateStreak30Jingle();
    _streak30Sound = BytesSource(streak30Wav);
  }

  /// Play a level-up jingle.
  /// Cycles through variations for variety.
  Future<void> playLevelUp() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_levelUpSounds.isEmpty) return;

    final sound = _levelUpSounds[_levelUpIndex];
    _levelUpIndex = (_levelUpIndex + 1) % _levelUpSounds.length;

    await _playSound(sound);
  }

  /// Play a milestone jingle.
  /// For milestone levels (10, 25, 50, 75, 92, 99).
  Future<void> playMilestone() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_milestoneSounds.isEmpty) return;

    final sound = _milestoneSounds[_milestoneIndex];
    _milestoneIndex = (_milestoneIndex + 1) % _milestoneSounds.length;

    await _playSound(sound);
  }

  /// Play an achievement jingle.
  /// Short reward sting for general achievements.
  Future<void> playAchievement() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_achievementSounds.isEmpty) return;

    final sound = _achievementSounds[_achievementIndex];
    _achievementIndex = (_achievementIndex + 1) % _achievementSounds.length;

    await _playSound(sound);
  }

  /// Play the Personal Best jingle.
  /// Extended celebration for beating your PB score.
  Future<void> playPersonalBest() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_personalBestSound == null) return;

    await _playSound(_personalBestSound!);
  }

  /// Play the 7-day streak jingle.
  /// Warm, respectful celebration for a week of training.
  Future<void> playStreak7() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_streak7Sound == null) return;

    await _playSound(_streak7Sound!);
  }

  /// Play the 14-day streak jingle.
  /// Fuller arrangement - "This is becoming a habit."
  Future<void> playStreak14() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_streak14Sound == null) return;

    await _playSound(_streak14Sound!);
  }

  /// Play the 30-day streak jingle.
  /// Grand, triumphant celebration - "You're committed."
  Future<void> playStreak30() async {
    if (!_enabled) return;
    if (!_initialized) await initialize();
    if (_streak30Sound == null) return;

    await _playSound(_streak30Sound!);
  }

  /// Play a sound.
  Future<void> _playSound(BytesSource source) async {
    try {
      await _player!.stop();
      await _player!.play(source);
    } catch (e) {
      // Silently fail - sounds are non-critical UX enhancement
    }
  }

  /// Enable or disable chiptune sounds.
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if chiptune sounds are enabled.
  bool get isEnabled => _enabled;

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_player != null) {
      await _player!.setVolume(_volume);
    }
  }

  /// Get current volume.
  double get volume => _volume;

  /// Check if initialized and ready.
  bool get isReady => _initialized;

  /// Get count of available sounds by type.
  Map<String, int> get soundCounts => {
        'levelUp': _levelUpSounds.length,
        'milestone': _milestoneSounds.length,
        'achievement': _achievementSounds.length,
      };

  /// Dispose of resources.
  void dispose() {
    _player?.dispose();
    _player = null;
    _initialized = false;
    _levelUpSounds.clear();
    _milestoneSounds.clear();
    _achievementSounds.clear();
    _personalBestSound = null;
    _streak7Sound = null;
    _streak14Sound = null;
    _streak30Sound = null;
  }
}
