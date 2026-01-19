import 'package:flutter/material.dart';
import '../services/chiptune_service.dart';
import '../theme/app_theme.dart';

/// Temporary test screen for previewing chiptune jingles.
/// Delete this after you're happy with the sounds.
class ChiptuneTestScreen extends StatefulWidget {
  const ChiptuneTestScreen({super.key});

  @override
  State<ChiptuneTestScreen> createState() => _ChiptuneTestScreenState();
}

class _ChiptuneTestScreenState extends State<ChiptuneTestScreen> {
  final _chiptune = ChiptuneService();
  bool _initializing = true;
  String _status = 'Generating sounds...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _chiptune.initialize();
    setState(() {
      _initializing = false;
      _status = 'Ready - ${_chiptune.soundCounts}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CHIPTUNE TEST', style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20)),
        backgroundColor: AppColors.surfaceDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              style: TextStyle(fontFamily: AppFonts.body, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_initializing)
              const Center(child: CircularProgressIndicator(color: AppColors.gold))
            else ...[
              _SoundButton(
                label: 'LEVEL UP',
                subtitle: '3 variations, ~2-3 sec',
                color: AppColors.gold,
                onPressed: () => _chiptune.playLevelUp(),
              ),
              const SizedBox(height: 16),
              _SoundButton(
                label: 'MILESTONE',
                subtitle: '2 variations, ~5-6 sec',
                color: Colors.purple,
                onPressed: () => _chiptune.playMilestone(),
              ),
              const SizedBox(height: 16),
              _SoundButton(
                label: 'ACHIEVEMENT',
                subtitle: '2 variations, ~1 sec',
                color: Colors.cyan,
                onPressed: () => _chiptune.playAchievement(),
              ),
              const SizedBox(height: 48),
              Text(
                'Tap multiple times to cycle through variations',
                style: TextStyle(fontFamily: AppFonts.body, color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoundButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _SoundButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(51),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: 2),
        ),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 24, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontFamily: AppFonts.body, fontSize: 12, color: color.withAlpha(179))),
        ],
      ),
    );
  }
}
