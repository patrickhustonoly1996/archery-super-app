import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/classification.dart';

/// A badge widget for displaying AGB classifications
class ClassificationBadge extends StatelessWidget {
  final String classificationCode;
  final ClassificationScope scope;
  final bool isCompact;
  final bool showScope;

  const ClassificationBadge({
    super.key,
    required this.classificationCode,
    required this.scope,
    this.isCompact = false,
    this.showScope = true,
  });

  /// Create from an OutdoorClassification enum
  factory ClassificationBadge.outdoor(
    OutdoorClassification classification, {
    bool isCompact = false,
    bool showScope = true,
  }) {
    return ClassificationBadge(
      classificationCode: classification.code,
      scope: ClassificationScope.outdoor,
      isCompact: isCompact,
      showScope: showScope,
    );
  }

  /// Create from an IndoorClassification enum
  factory ClassificationBadge.indoor(
    IndoorClassification classification, {
    bool isCompact = false,
    bool showScope = true,
  }) {
    return ClassificationBadge(
      classificationCode: classification.code,
      scope: ClassificationScope.indoor,
      isCompact: isCompact,
      showScope: showScope,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final textColor = _getTextColor();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          classificationCode,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        border: Border.all(color: badgeColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            classificationCode,
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 24,
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getFullName(),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              color: badgeColor,
            ),
          ),
          if (showScope) ...[
            const SizedBox(height: 4),
            Text(
              scope.displayName.toUpperCase(),
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                color: badgeColor.withValues(alpha: 0.7),
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    // Gold/higher tiers for top classifications
    switch (classificationCode) {
      case 'GMB':
        return const Color(0xFFFFD700); // Gold
      case 'MB':
        return const Color(0xFFC0C0C0); // Silver
      case 'B1':
        return const Color(0xFFCD7F32); // Bronze
      case 'B2':
      case 'B3':
        return const Color(0xFF4A90D9); // Blue
      case 'A1':
      case 'A2':
      case 'A3':
        return const Color(0xFF6B8E23); // Olive/Green
      default:
        return AppColors.textMuted;
    }
  }

  Color _getTextColor() {
    // For compact badges with solid background
    switch (classificationCode) {
      case 'GMB':
        return AppColors.background;
      case 'MB':
        return AppColors.background;
      default:
        return Colors.white;
    }
  }

  String _getFullName() {
    if (scope == ClassificationScope.outdoor) {
      return OutdoorClassification.fromString(classificationCode).displayName;
    } else {
      return IndoorClassification.fromString(classificationCode).displayName;
    }
  }
}

/// A row of classification badges for displaying both outdoor and indoor
class ClassificationBadgeRow extends StatelessWidget {
  final String? outdoorCode;
  final String? indoorCode;
  final bool isCompact;

  const ClassificationBadgeRow({
    super.key,
    this.outdoorCode,
    this.indoorCode,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outdoorCode == null && indoorCode == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (outdoorCode != null)
          ClassificationBadge(
            classificationCode: outdoorCode!,
            scope: ClassificationScope.outdoor,
            isCompact: isCompact,
          ),
        if (outdoorCode != null && indoorCode != null)
          const SizedBox(width: 8),
        if (indoorCode != null)
          ClassificationBadge(
            classificationCode: indoorCode!,
            scope: ClassificationScope.indoor,
            isCompact: isCompact,
          ),
      ],
    );
  }
}

/// A card showing classification progress
class ClassificationProgressCard extends StatelessWidget {
  final String classificationCode;
  final ClassificationScope scope;
  final bool hasFirstScore;
  final bool hasSecondScore;
  final bool isClaimed;

  const ClassificationProgressCard({
    super.key,
    required this.classificationCode,
    required this.scope,
    required this.hasFirstScore,
    required this.hasSecondScore,
    this.isClaimed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(
          color: isClaimed ? AppColors.gold : AppColors.surfaceBright,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          ClassificationBadge(
            classificationCode: classificationCode,
            scope: scope,
            isCompact: true,
            showScope: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFullName(),
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildProgressIndicator(),
              ],
            ),
          ),
          if (isClaimed)
            Icon(
              Icons.check_circle,
              color: AppColors.gold,
              size: 20,
            )
          else if (hasFirstScore && hasSecondScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CLAIM',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 10,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildDot(hasFirstScore),
        Container(
          width: 16,
          height: 2,
          color: hasFirstScore ? AppColors.gold : AppColors.surfaceBright,
        ),
        _buildDot(hasSecondScore),
        const SizedBox(width: 8),
        Text(
          hasSecondScore
              ? 'Complete'
              : hasFirstScore
                  ? '1/2 scores'
                  : '0/2 scores',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            color: hasSecondScore ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool filled) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.gold : AppColors.surfaceLight,
        border: Border.all(
          color: filled ? AppColors.gold : AppColors.surfaceBright,
          width: 2,
        ),
      ),
    );
  }

  String _getFullName() {
    if (scope == ClassificationScope.outdoor) {
      return OutdoorClassification.fromString(classificationCode).displayName;
    } else {
      return IndoorClassification.fromString(classificationCode).displayName;
    }
  }
}
