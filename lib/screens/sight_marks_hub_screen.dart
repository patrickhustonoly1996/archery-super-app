import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import 'sight_marks_screen.dart';
import 'equipment_screen.dart';

/// Hub screen for accessing sight marks.
/// Shows bow selection if multiple bows, or goes directly to marks if only one.
class SightMarksHubScreen extends StatelessWidget {
  const SightMarksHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentProvider>(
      builder: (context, equipmentProvider, _) {
        final bows = equipmentProvider.bows;

        // No bows - prompt to add one
        if (bows.isEmpty) {
          return _NoBowsView();
        }

        // Single bow - go directly to sight marks
        if (bows.length == 1) {
          return SightMarksScreen(
            bowId: bows.first.id,
            bowName: bows.first.name,
          );
        }

        // Multiple bows - show selection
        return _BowSelectionView(bows: bows);
      },
    );
  }
}

class _NoBowsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SIGHT MARKS',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_martial_arts,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 24),
              Text(
                'NO BOWS FOUND',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 18,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add a bow to your gear to start tracking sight marks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const EquipmentScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Text(
                    'ADD BOW',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 14,
                      color: AppColors.gold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BowSelectionView extends StatelessWidget {
  final List<Bow> bows;

  const _BowSelectionView({required this.bows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SIGHT MARKS',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'SELECT BOW',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: bows.length,
              itemBuilder: (context, index) {
                final bow = bows[index];
                return _BowTile(bow: bow);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BowTile extends StatelessWidget {
  final Bow bow;

  const _BowTile({required this.bow});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SightMarksScreen(
              bowId: bow.id,
              bowName: bow.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Bow type indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  _getBowTypeAbbreviation(bow.bowType),
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 12,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bow.name,
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bow.bowType.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '>',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBowTypeAbbreviation(String bowType) {
    switch (bowType.toLowerCase()) {
      case 'recurve':
        return 'REC';
      case 'compound':
        return 'CMP';
      case 'barebow':
        return 'BB';
      case 'longbow':
        return 'LB';
      case 'traditional':
        return 'TRD';
      default:
        return bowType.substring(0, 3).toUpperCase();
    }
  }
}
