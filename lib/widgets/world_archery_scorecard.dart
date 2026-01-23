import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../models/distance_leg.dart';

/// World Archery official format scorecard.
/// Matches the format used at international competitions like World Championships.
///
/// Features:
/// - Header with event/round info, archer details, target assignment
/// - Score grid with arrows, end sums, running totals, 10+X, X columns
/// - Distance subtotals for multi-distance rounds
/// - Grand total row
/// - Integrated signature boxes for archer and witness
class WorldArcheryScorecardWidget extends StatelessWidget {
  // Session and round data
  final Session? session;
  final RoundType? roundType;
  final List<End> ends;
  final List<List<Arrow>> endArrows;

  // Live scoring data (for active sessions)
  final List<Arrow> currentEndArrows;
  final int currentEndNumber;

  // Archer profile
  final String? archerName;
  final String? archerCountry;
  final String? division;
  final String? bowClass;
  final String? targetAssignment;

  // Event info
  final String? eventName;
  final String? eventLocation;
  final DateTime? eventDate;

  // Signatures
  final Uint8List? archerSignature;
  final Uint8List? witnessSignature;
  final ValueChanged<Uint8List?>? onArcherSignatureChanged;
  final ValueChanged<Uint8List?>? onWitnessSignatureChanged;

  // Display options
  final bool showSignatures;
  final bool isCompact;
  final bool isLive;

  const WorldArcheryScorecardWidget({
    super.key,
    this.session,
    this.roundType,
    required this.ends,
    required this.endArrows,
    this.currentEndArrows = const [],
    this.currentEndNumber = 1,
    this.archerName,
    this.archerCountry,
    this.division,
    this.bowClass,
    this.targetAssignment,
    this.eventName,
    this.eventLocation,
    this.eventDate,
    this.archerSignature,
    this.witnessSignature,
    this.onArcherSignatureChanged,
    this.onWitnessSignatureChanged,
    this.showSignatures = true,
    this.isCompact = false,
    this.isLive = false,
  });

  int get arrowsPerEnd => roundType?.arrowsPerEnd ?? 3;
  int get totalEnds => roundType?.totalEnds ?? 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          _buildHeader(),

          // Score table
          _buildScoreTable(),

          // Grand total
          _buildGrandTotalRow(),

          // Signature boxes
          if (showSignatures) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSignatureSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final date = eventDate ?? session?.startedAt ?? DateTime.now();
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.sm - 1),
          topRight: Radius.circular(AppSpacing.sm - 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event name row
          if (eventName != null || roundType != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    eventName ?? roundType?.name ?? 'Score Sheet',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: isCompact ? 12 : 14,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Target assignment badge
                if (targetAssignment != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      targetAssignment!,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 4),

          // Archer info and round details row
          Row(
            children: [
              // Archer name and country
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (archerName != null && archerName!.isNotEmpty)
                      Text(
                        archerName!,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: isCompact ? 11 : 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (archerCountry != null && archerCountry!.isNotEmpty)
                      Text(
                        archerCountry!,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: isCompact ? 9 : 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              // Division/Class badge
              if (division != null || bowClass != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _formatDivisionClass(),
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // Date
              Text(
                dateStr,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: isCompact ? 9 : 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          // Round name if different from event
          if (eventName != null && roundType != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                roundType!.name,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDivisionClass() {
    final parts = <String>[];
    if (bowClass != null) parts.add(_abbreviateBowClass(bowClass!));
    if (division != null) parts.add(_abbreviateDivision(division!));
    return parts.join(' ');
  }

  String _abbreviateBowClass(String bowClass) {
    // Standard World Archery abbreviations
    switch (bowClass.toLowerCase()) {
      case 'recurve': return 'R';
      case 'compound': return 'C';
      case 'barebow': return 'B';
      case 'longbow': return 'L';
      default: return bowClass.substring(0, 1).toUpperCase();
    }
  }

  String _abbreviateDivision(String division) {
    switch (division.toLowerCase()) {
      case 'men': return 'M';
      case 'women': return 'W';
      case 'junior men': return 'JM';
      case 'junior women': return 'JW';
      case 'cadet men': return 'CM';
      case 'cadet women': return 'CW';
      default: return division.substring(0, 1).toUpperCase();
    }
  }

  Widget _buildScoreTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: [
          // Table header
          _buildTableHeader(),
          Container(height: 1, color: AppColors.surfaceLight),

          // End rows
          ...List.generate(totalEnds, (index) {
            final endNumber = index + 1;
            final isCompleted = index < ends.length;
            final isCurrent = endNumber == currentEndNumber && isLive;

            List<Arrow> arrows;
            if (isCompleted && index < endArrows.length) {
              arrows = endArrows[index];
            } else if (isCurrent) {
              arrows = currentEndArrows;
            } else {
              arrows = [];
            }

            final endData = isCompleted ? ends[index] : null;

            return _buildEndRow(
              endNumber: endNumber,
              arrows: arrows,
              endScore: endData?.endScore ?? _sumArrows(arrows),
              runningTotal: _calculateRunningTotal(endNumber),
              cumulative10s: _calculateCumulative10s(endNumber),
              cumulativeXs: _calculateCumulativeXs(endNumber),
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isDistanceBoundary: _isDistanceBoundary(endNumber),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final fontSize = isCompact ? 8.0 : 9.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      color: AppColors.surfaceLight.withValues(alpha: 0.2),
      child: Row(
        children: [
          // Distance/End column
          _headerCell('', width: 20, fontSize: fontSize),

          // Arrow columns
          ...List.generate(
            arrowsPerEnd,
            (i) => _headerCell('${i + 1}', width: 22, fontSize: fontSize, muted: true),
          ),

          // Sum column
          _headerCell('Sum', width: 28, fontSize: fontSize),

          // Running total
          _headerCell('Tot.', width: 34, fontSize: fontSize, isGold: true),

          // 10+X column
          _headerCell('10+X', width: 28, fontSize: fontSize, muted: true),

          // X column
          _headerCell('X', width: 22, fontSize: fontSize, muted: true),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {
    required double width,
    required double fontSize,
    bool muted = false,
    bool isGold = false,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: fontSize,
            color: isGold
                ? AppColors.gold
                : (muted ? AppColors.textMuted : AppColors.textSecondary),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEndRow({
    required int endNumber,
    required List<Arrow> arrows,
    required int endScore,
    required int runningTotal,
    required int cumulative10s,
    required int cumulativeXs,
    required bool isCompleted,
    required bool isCurrent,
    required bool isDistanceBoundary,
  }) {
    final fontSize = isCompact ? 9.0 : 10.0;
    final hasArrows = arrows.isNotEmpty;

    // Sort arrows by score descending (World Archery format: X > 10 > 9 > ...)
    final sortedArrows = List<Arrow>.from(arrows)
      ..sort((a, b) {
        // X counts as higher than 10
        final aScore = a.isX ? 11 : a.score;
        final bScore = b.isX ? 11 : b.score;
        return bScore.compareTo(aScore);
      });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.gold.withValues(alpha: 0.1)
            : (isCompleted ? Colors.transparent : AppColors.surfaceLight.withValues(alpha: 0.05)),
        border: Border(
          bottom: BorderSide(
            color: isDistanceBoundary
                ? AppColors.gold.withValues(alpha: 0.6)
                : AppColors.surfaceLight.withValues(alpha: 0.3),
            width: isDistanceBoundary ? 2 : 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // End number
          SizedBox(
            width: 20,
            child: Center(
              child: Text(
                '$endNumber',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: fontSize,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Arrow scores with X display - sorted descending (World Archery format)
          ...List.generate(arrowsPerEnd, (i) {
            final hasArrow = i < sortedArrows.length;
            final arrow = hasArrow ? sortedArrows[i] : null;

            return _buildArrowCell(
              arrow: arrow,
              hasArrow: hasArrow,
              isCompleted: isCompleted || isCurrent,
              fontSize: fontSize,
            );
          }),

          // Sum (end total)
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                hasArrows ? endScore.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: fontSize,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Running total (gold)
          SizedBox(
            width: 34,
            child: Center(
              child: Text(
                hasArrows ? runningTotal.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: fontSize,
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 10+X count
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                hasArrows && cumulative10s > 0 ? cumulative10s.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: fontSize - 1,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // X count
          SizedBox(
            width: 22,
            child: Center(
              child: Text(
                hasArrows && cumulativeXs > 0 ? cumulativeXs.toString() : '',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: fontSize - 1,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowCell({
    required Arrow? arrow,
    required bool hasArrow,
    required bool isCompleted,
    required double fontSize,
  }) {
    if (!hasArrow) {
      return SizedBox(
        width: 22,
        height: 18,
        child: Center(
          child: isCompleted
              ? Text(
                  '-',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: fontSize,
                    color: AppColors.textMuted,
                  ),
                )
              : null,
        ),
      );
    }

    final score = arrow!.score;
    final isX = arrow.isX;

    // World Archery format: X shown as "X" with gold color, 10 shown as "10"
    // M (miss) shown as "M"
    String displayText;
    if (isX) {
      displayText = 'X';
    } else if (score == 0) {
      displayText = 'M';
    } else {
      displayText = score.toString();
    }

    return SizedBox(
      width: 22,
      height: 18,
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: fontSize,
            color: _getScoreColor(score, isX),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGrandTotalRow() {
    final totalScore = _calculateTotalScore();
    final total10s = _calculateCumulative10s(totalEnds);
    final totalXs = _calculateCumulativeXs(totalEnds);
    final maxScore = roundType?.maxScore;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.sm - 1),
          bottomRight: Radius.circular(AppSpacing.sm - 1),
        ),
      ),
      child: Row(
        children: [
          // Total label
          Text(
            'Total',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: isCompact ? 11 : 12,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Score with optional max
          Text(
            maxScore != null ? '$totalScore/$maxScore' : totalScore.toString(),
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: isCompact ? 14 : 16,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // 10+X count
          _totalStatBadge('10+X', total10s),

          const SizedBox(width: AppSpacing.sm),

          // X count
          _totalStatBadge('X', totalXs),
        ],
      ),
    );
  }

  Widget _totalStatBadge(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIGNATURES',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Archer signature
              Expanded(
                child: _SignatureBox(
                  label: 'Archer',
                  signature: archerSignature,
                  onSignatureChanged: onArcherSignatureChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Witness signature
              Expanded(
                child: _SignatureBox(
                  label: 'Witness / Scorer',
                  signature: witnessSignature,
                  onSignatureChanged: onWitnessSignatureChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Calculation helpers
  int _sumArrows(List<Arrow> arrows) {
    return arrows.fold(0, (sum, a) => sum + a.score);
  }

  int _calculateRunningTotal(int throughEndNumber) {
    int total = 0;

    // Sum completed ends
    for (int i = 0; i < throughEndNumber && i < ends.length; i++) {
      total += ends[i].endScore;
    }

    // Add current end if applicable
    if (isLive && throughEndNumber == currentEndNumber && currentEndArrows.isNotEmpty) {
      total += _sumArrows(currentEndArrows);
    }

    return total;
  }

  int _calculateTotalScore() {
    int total = ends.fold(0, (sum, end) => sum + end.endScore);
    if (isLive && currentEndArrows.isNotEmpty) {
      total += _sumArrows(currentEndArrows);
    }
    return total;
  }

  int _calculateCumulative10s(int throughEndNumber) {
    int count = 0;

    for (int i = 0; i < throughEndNumber && i < endArrows.length; i++) {
      count += endArrows[i].where((a) => a.score >= 10).length;
    }

    // Add current end if applicable
    if (isLive && throughEndNumber >= currentEndNumber && currentEndArrows.isNotEmpty) {
      count += currentEndArrows.where((a) => a.score >= 10).length;
    }

    return count;
  }

  int _calculateCumulativeXs(int throughEndNumber) {
    int count = 0;

    for (int i = 0; i < throughEndNumber && i < ends.length; i++) {
      count += ends[i].endXs;
    }

    // Add current end if applicable
    if (isLive && throughEndNumber >= currentEndNumber && currentEndArrows.isNotEmpty) {
      count += currentEndArrows.where((a) => a.isX).length;
    }

    return count;
  }

  bool _isDistanceBoundary(int endNumber) {
    // Use actual distance legs from round type if available
    if (roundType != null) {
      final legs = roundType!.distanceLegs.parseDistanceLegs();
      if (legs != null && legs.length > 1) {
        final tracker = DistanceLegTracker(legs: legs, arrowsPerEnd: arrowsPerEnd);
        // Check if this end is a leg boundary (but not the last end of the round)
        return tracker.isLegBoundary(endNumber) && endNumber != totalEnds;
      }
    }

    // Fallback: Standard WA rounds (6 ends per distance)
    if (totalEnds == 12) {
      return endNumber == 6; // Half way mark
    }
    if (totalEnds == 24) {
      return endNumber == 6 || endNumber == 12 || endNumber == 18;
    }
    return false;
  }

  Color _getScoreColor(int score, bool isX) {
    if (isX) return AppColors.gold;
    if (score == 10) return AppColors.gold;
    if (score >= 9) return AppColors.gold.withValues(alpha: 0.8);
    if (score >= 7) return const Color(0xFFFF5555); // Red
    if (score >= 5) return const Color(0xFF5599FF); // Blue
    if (score == 0) return AppColors.textMuted; // Miss
    return AppColors.textMuted;
  }
}

/// Signature box with display and optional edit capability
class _SignatureBox extends StatelessWidget {
  final String label;
  final Uint8List? signature;
  final ValueChanged<Uint8List?>? onSignatureChanged;

  const _SignatureBox({
    required this.label,
    this.signature,
    this.onSignatureChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSignature = signature != null && signature!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasSignature
                  ? AppColors.gold.withValues(alpha: 0.3)
                  : AppColors.surfaceLight,
            ),
          ),
          child: hasSignature
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.memory(
                    signature!,
                    fit: BoxFit.contain,
                  ),
                )
              : Center(
                  child: Text(
                    'Tap to sign',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
