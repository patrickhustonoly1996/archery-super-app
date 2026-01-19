// Run: dart run tool/generate_jingles.dart
// Outputs WAV files to tool/output/ for preview

import 'dart:io';
import '../lib/services/chiptune_generator.dart';

void main() async {
  final outputDir = Directory('tool/output');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('Generating chiptune jingles...\n');

  // Generate level-up variations
  for (int i = 0; i < 3; i++) {
    final wav = ChiptuneGenerator.generateLevelUpJingle(variation: i);
    final file = File('tool/output/level_up_${i + 1}.wav');
    await file.writeAsBytes(wav);
    print('Created: ${file.path} (${wav.length} bytes)');
  }

  // Generate milestone variations
  for (int i = 0; i < 2; i++) {
    final wav = ChiptuneGenerator.generateMilestoneJingle(variation: i);
    final file = File('tool/output/milestone_${i + 1}.wav');
    await file.writeAsBytes(wav);
    print('Created: ${file.path} (${wav.length} bytes)');
  }

  // Generate achievement variations
  for (int i = 0; i < 2; i++) {
    final wav = ChiptuneGenerator.generateAchievementJingle(variation: i);
    final file = File('tool/output/achievement_${i + 1}.wav');
    await file.writeAsBytes(wav);
    print('Created: ${file.path} (${wav.length} bytes)');
  }

  // Generate personal best jingle
  final pbWav = ChiptuneGenerator.generatePersonalBestJingle();
  final pbFile = File('tool/output/personal_best.wav');
  await pbFile.writeAsBytes(pbWav);
  print('Created: ${pbFile.path} (${pbWav.length} bytes)');

  // Generate streak jingles
  final streak7Wav = ChiptuneGenerator.generateStreak7Jingle();
  final streak7File = File('tool/output/streak_7day.wav');
  await streak7File.writeAsBytes(streak7Wav);
  print('Created: ${streak7File.path} (${streak7Wav.length} bytes)');

  final streak14Wav = ChiptuneGenerator.generateStreak14Jingle();
  final streak14File = File('tool/output/streak_14day.wav');
  await streak14File.writeAsBytes(streak14Wav);
  print('Created: ${streak14File.path} (${streak14Wav.length} bytes)');

  final streak30Wav = ChiptuneGenerator.generateStreak30Jingle();
  final streak30File = File('tool/output/streak_30day.wav');
  await streak30File.writeAsBytes(streak30Wav);
  print('Created: ${streak30File.path} (${streak30Wav.length} bytes)');

  print('\nDone! Open tool/output/ to preview the sounds.');
}
