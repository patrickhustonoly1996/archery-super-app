import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

/// World Archery format scorecard showing all ends in a scrollable table.
/// Header row stays fixed while content scrolls.
class FullScorecardWidget extends StatelessWidget {
  final List<End> completedEnds;
  final List<List<Arrow>> completedEndArrows;
  final List<Arrow> currentEndArrows;
  final int currentEndNumber;
  final int arrowsPerEnd;
  final int totalEnds;
  final String roundName;
  final int? maxScore;
  final RoundType? roundType;

  const FullScorecardWidget({
    super.key,
    required this.completedEnds,
    required this.completedEndArrows,
    required this.currentEndArrows,
    required this.currentEndNumber,
    required this.arrowsPerEnd,
    required this.totalEnds,
    required this.roundName,
    this.maxScore,
    this.roundType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed header row
          _buildHeaderRow(),
          Container(height: 1, color: AppColors.surfaceLight),

          // Scrollable content with all ends
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Completed ends
                  ...List.generate(completedEnds.length, (index) {
                    final end = completedEnds[index];
                    final arrows = index < completedEndArrows.length
                        ? completedEndArrows[index]
                        : <Arrow>[];
                    return _buildEndRow(
                      endNumber: end.endNumber,
                      arrows: arrows,
                      endTotal: end.endScore,
                      runningTotal: _calculateRunningTotal(end.endNumber),
                      cumulativeXs: _calculateCumulativeXs(end.endNumber),
                      cumulative10s: _calculateCumulative10s(end.endNumber),
                      isComplete: true,
                      isDistanceEnd: _isDistanceEnd(end.endNumber),
                    );
                  }),

                  // Current end (if not complete)
                  if (currentEndNumber <= totalEnds &&
                      currentEndNumber > completedEnds.length)
                    _buildEndRow(
                      endNumber: currentEndNumber,
                      arrows: currentEndArrows,
                      endTotal: _currentEndTotal(),
                      runningTotal: _calculateRunningTotal(currentEndNumber - 1) +
                          _currentEndTotal(),
                      cumulativeXs: _calculateCumulativeXs(currentEndNumber - 1) +
                          _currentXs(),
                      cumulative10s: _calculateCumulative10s(currentEndNumber - 1) +
                          _current10s(),
                      isComplete: false,
                      isDistanceEnd: _isDistanceEnd(currentEndNumber),
                    ),

                  // Distance subtotal row (if applicable)
                  if (_shouldShowDistanceSubtotal())
                    _buildDistanceSubtotalRow(),

                  // Grand total row
                  _buildGrandTotalRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.sm - 1),
          topRight: Radius.circular(AppSpacing.sm - 1),
        ),
      ),
      child: Row(
        children: [
          // End # column
          _headerCell('End', width: 28),

          // Arrow score columns
          ...List.generate(
            arrowsPerEnd,
            (i) => _headerCell('${i + 1}', width: 24, muted: true),
          ),

          // E/T column
          _headerCell('E/T', width: 32),

          // R/T column (gold)
          _headerCell('R/T', width: 40, isGold: true),

          // 10+X column
          _headerCell('10+X', width: 32, muted: true),

          // X column
          _headerCell('X', width: 24, muted: true),
        ],
      ),
    );
  }

  Widget _headerCell(String text,
      {required double width, bool muted = false, bool isGold = false}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.body,
            color: isGold
                ? AppColors.gold
                : (muted ? AppColors.textMuted : AppColors.textSecondary),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    required bool isDistanceEnd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.transparent
            : AppColors.surfaceLight.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: isDistanceEnd
                ? AppColors.gold.withOpacity(0.5)
                : AppColors.surfaceLight.withOpacity(0.3),
            width: isDistanceEnd ? 2 : 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // End number
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$endNumber',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Arrow scores
          ...List.generate(arrowsPerEnd, (i) {
            final hasArrow = i < arrows.length;
            final arrow = hasArrow ? arrows[i] : null;

            return SizedBox(
              width: 24,
              child: Center(
                child: hasArrow
                    ? Text(
                        arrow!.isX ? 'X' : arrow.score.toString(),
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: _getScoreColor(arrow.score, arrow.isX),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        isComplete ? '-' : '',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
              ),
            );
          }),

          // End total
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                arrows.isNotEmpty ? endTotal.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Running total (gold)
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                arrows.isNotEmpty ? runningTotal.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 10+X count
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                cumulative10s > 0 ? cumulative10s.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          // X count
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                cumulativeXs > 0 ? cumulativeXs.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
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

  Widget _buildDistanceSubtotalRow() {
    // Calculate distance subtotal based on round type
    final distanceEnds = _getDistanceEndCount();
    if (distanceEnds == 0 || distanceEnds >= totalEnds) return const SizedBox.shrink();

    final subtotal = _calculateRunningTotal(distanceEnds);
    final xs = _calculateCumulativeXs(distanceEnds);
    final tens = _calculateCumulative10s(distanceEnds);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28 + (arrowsPerEnd * 24).toDouble(),
            child: Text(
              'Distance Total',
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                subtotal.toString(),
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // R/T column spacer
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                tens > 0 ? tens.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                xs > 0 ? xs.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
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

  Widget _buildGrandTotalRow() {
    final total = _calculateRunningTotal(completedEnds.length) + _currentEndTotal();
    final xs = _calculateCumulativeXs(completedEnds.length) + _currentXs();
    final tens = _calculateCumulative10s(completedEnds.length) + _current10s();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.sm - 1),
          bottomRight: Radius.circular(AppSpacing.sm - 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28 + (arrowsPerEnd * 24).toDouble() + 32,
            child: Text(
              'TOTAL',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                total.toString(),
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                tens > 0 ? tens.toString() : '-',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                xs > 0 ? xs.toString() : '-',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score, bool isX) {
    if (isX) return AppColors.gold;
    if (score == 10) return AppColors.gold;
    if (score >= 9) return AppColors.gold.withOpacity(0.8);
    if (score >= 7) return const Color(0xFFFF5555); // Red
    if (score >= 5) return const Color(0xFF5599FF); // Blue
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

  bool _isDistanceEnd(int endNumber) {
    // Check if this end marks the end of a distance
    final distanceEnds = _getDistanceEndCount();
    return distanceEnds > 0 && endNumber == distanceEnds;
  }

  int _getDistanceEndCount() {
    // For multi-distance rounds, return the end number where first distance ends
    // WA 1440: 36 arrows per distance = 6 ends at 6 arrows/end
    // WA 720: 36 arrows = 6 ends per distance for outdoor
    if (roundType == null) return 0;

    final category = roundType!.category;
    if (category == 'wa_outdoor') {
      // WA outdoor typically has 2 distances
      return totalEnds ~/ 2;
    }
    return 0; // Indoor rounds are single distance
  }

  bool _shouldShowDistanceSubtotal() {
    final distanceEnds = _getDistanceEndCount();
    return distanceEnds > 0 && completedEnds.length >= distanceEnds;
  }
}
