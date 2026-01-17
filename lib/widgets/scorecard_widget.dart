import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../config/app_constants.dart';

/// Official scorecard display showing ends with E/T and R/T
class ScorecardWidget extends StatelessWidget {
  final List<End> completedEnds;
  final List<List<Arrow>> completedEndArrows; // Arrows for each completed end
  final List<Arrow> currentEndArrows;
  final int currentEndNumber;
  final int arrowsPerEnd;
  final int totalEnds;
  final String roundName;

  const ScorecardWidget({
    super.key,
    required this.completedEnds,
    required this.completedEndArrows,
    required this.currentEndArrows,
    required this.currentEndNumber,
    required this.arrowsPerEnd,
    required this.totalEnds,
    required this.roundName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          _buildHeaderRow(),
          const Divider(height: 1, color: AppColors.surfaceLight),

          // Current end only
          if (currentEndNumber <= totalEnds)
            _buildEndRow(
              endNumber: currentEndNumber,
              arrows: currentEndArrows,
              endTotal: _currentEndTotal(),
              runningTotal: _calculateRunningTotal(currentEndNumber - 1) + _currentEndTotal(),
              cumulativeXs: _calculateCumulativeXs(currentEndNumber - 1) + _currentXs(),
              cumulative10s: _calculateCumulative10s(currentEndNumber - 1) + _current10s(),
              isComplete: false,
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // End # column
          SizedBox(
            width: ScorecardConstants.endColumnWidth,
            child: Text(
              'End',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Arrow score columns
          ...List.generate(arrowsPerEnd, (i) =>
            SizedBox(
              width: ScorecardConstants.arrowColumnWidth,
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ),

          // E/T column
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                'E/T',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // R/T column
          Expanded(
            child: Center(
              child: Text(
                'R/T',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 10+X column
          SizedBox(
            width: ScorecardConstants.tensColumnWidth,
            child: Center(
              child: Text(
                '10+X',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ),

          // X column
          SizedBox(
            width: ScorecardConstants.xColumnWidth,
            child: Center(
              child: Text(
                'X',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndRow({
    required int endNumber,
    required List<Arrow> arrows,
    required int endTotal,
    required int runningTotal,
    required int cumulativeXs,
    required int cumulative10s,
    required bool isComplete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.3),
            width: ScorecardConstants.borderWidth,
          ),
        ),
        color: isComplete ? Colors.transparent : AppColors.surfaceLight.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          // End number
          SizedBox(
            width: 32,
            child: Text(
              '$endNumber',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Arrow scores
          ...List.generate(arrowsPerEnd, (i) {
            final hasArrow = i < arrows.length;
            final arrow = hasArrow ? arrows[i] : null;

            return SizedBox(
              width: ScorecardConstants.arrowColumnWidth,
              child: Center(
                child: hasArrow
                    ? Text(
                        arrow!.isX ? 'X' : arrow.score.toString(),
                        style: TextStyle(
                          color: _getScoreColor(arrow.score),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        isComplete ? '-' : '',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
              ),
            );
          }),

          // End total
          SizedBox(
            width: ScorecardConstants.endColumnWidth,
            child: Center(
              child: Text(
                arrows.isNotEmpty ? endTotal.toString() : '',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Running total
          Expanded(
            child: Center(
              child: Text(
                arrows.isNotEmpty ? runningTotal.toString() : '',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 10+X count
          SizedBox(
            width: ScorecardConstants.tensColumnWidth,
            child: Center(
              child: Text(
                cumulative10s > 0 ? cumulative10s.toString() : '',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          // X count
          SizedBox(
            width: ScorecardConstants.xColumnWidth,
            child: Center(
              child: Text(
                cumulativeXs > 0 ? cumulativeXs.toString() : '',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score == 10) return AppColors.gold;
    if (score >= 9) return AppColors.gold.withValues(alpha: 0.8);
    if (score >= 7) return const Color(0xFFFF5555); // Red
    if (score >= 5) return const Color(0xFF5599FF); // Blue
    if (score >= 3) return AppColors.textMuted;
    return AppColors.textMuted;
  }

  int _calculateRunningTotal(int throughEndNumber) {
    int total = 0;
    for (int i = 0; i < throughEndNumber && i < completedEnds.length; i++) {
      total += completedEnds[i].endScore;
    }
    return total;
  }

  int _calculateCumulativeXs(int throughEndNumber) {
    int xs = 0;
    for (int i = 0; i < throughEndNumber && i < completedEnds.length; i++) {
      xs += completedEnds[i].endXs;
    }
    return xs;
  }

  int _calculateCumulative10s(int throughEndNumber) {
    int tens = 0;
    for (int i = 0; i < throughEndNumber && i < completedEndArrows.length; i++) {
      tens += completedEndArrows[i].where((a) => a.score == 10).length;
    }
    return tens;
  }

  int _currentEndTotal() {
    return currentEndArrows.fold(0, (sum, arrow) => sum + arrow.score);
  }

  int _currentXs() {
    return currentEndArrows.where((a) => a.isX).length;
  }

  int _current10s() {
    return currentEndArrows.where((a) => a.score == 10).length;
  }
}
