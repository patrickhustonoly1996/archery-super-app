import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/angle_sight_mark_calculator.dart';

/// Display mode for angle table values
enum AngleTableDisplayMode {
  /// Show actual sight mark values (e.g., 4.15)
  degrees,

  /// Show as percentage of flat mark (e.g., 97.2%)
  percentage,
}

/// Widget displaying an angle correction table for sight marks.
///
/// Shows uphill and downhill adjustments in either degrees (sight mark values)
/// or percentage mode (percentage of flat mark).
///
/// Example displays:
///
/// DEGREES VIEW:
/// ```
/// 50 YARDS - 230 fps
/// ────────────────────────────────
///   UPHILL     FLAT    DOWNHILL
/// ────────────────────────────────
///    -25deg   |        |   +25deg
///    4.00   |        |   3.85
/// ...
/// ```
///
/// PERCENTAGE VIEW:
/// ```
/// 50 YARDS - 230 fps
/// ────────────────────────────────
///   UPHILL     FLAT    DOWNHILL
/// ────────────────────────────────
///    -25deg   |        |   +25deg
///    96.4%  |        |   92.8%
/// ...
/// ```
class AngleTable extends StatelessWidget {
  /// The flat ground sight mark
  final double flatSightMark;

  /// Arrow speed in fps
  final double arrowSpeedFps;

  /// Distance for display (optional)
  final double? distance;

  /// Distance unit for display (optional)
  final String? distanceUnit;

  /// Display mode (degrees or percentage)
  final AngleTableDisplayMode displayMode;

  /// Custom angles to display (defaults to standard 5, 10, 15, 20, 25)
  final List<double>? customAngles;

  /// Whether to show a compact 3-row version
  final bool compact;

  /// Callback when an angle is tapped
  final void Function(double angle, double sightMark)? onAngleTap;

  const AngleTable({
    super.key,
    required this.flatSightMark,
    required this.arrowSpeedFps,
    this.distance,
    this.distanceUnit,
    this.displayMode = AngleTableDisplayMode.degrees,
    this.customAngles,
    this.compact = false,
    this.onAngleTap,
  });

  @override
  Widget build(BuildContext context) {
    final table = AngleSightMarkCalculator.generateCompactTable(
      flatSightMark: flatSightMark,
      arrowSpeedFps: arrowSpeedFps,
      angles: customAngles,
    );

    // In compact mode, show only 3 rows: 25deg, 15deg, 5deg
    final displayAngles = compact ? [25.0, 15.0, 5.0] : (customAngles ?? [5.0, 10.0, 15.0, 20.0, 25.0]);

    // Filter entries to match display angles
    final uphillEntries = table.uphill.where((e) => displayAngles.contains(e.angle.abs())).toList();
    final downhillEntries = table.downhill.where((e) => displayAngles.contains(e.angle)).toList();

    // Sort for display (largest angle first for compact, smallest first otherwise)
    if (compact) {
      uphillEntries.sort((a, b) => a.angle.compareTo(b.angle)); // Most negative first
      downhillEntries.sort((a, b) => b.angle.compareTo(a.angle)); // Most positive first
    } else {
      uphillEntries.sort((a, b) => b.angle.compareTo(a.angle)); // Least negative first (closest to flat)
      downhillEntries.sort((a, b) => a.angle.compareTo(b.angle)); // Least positive first (closest to flat)
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with distance and speed
          if (distance != null) ...[
            _buildHeader(context),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.surfaceBright, height: 1),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Column headers
          _buildColumnHeaders(context),
          const SizedBox(height: AppSpacing.xs),

          // Table rows
          ...List.generate(displayAngles.length, (index) {
            final angle = compact
                ? displayAngles[index]
                : displayAngles.reversed.toList()[index]; // Reverse for non-compact

            final uphillEntry = uphillEntries.where((e) => e.angle.abs() == angle).firstOrNull;
            final downhillEntry = downhillEntries.where((e) => e.angle == angle).firstOrNull;

            if (uphillEntry == null || downhillEntry == null) return const SizedBox();

            return _buildTableRow(
              context,
              uphill: uphillEntry,
              downhill: downhillEntry,
              flat: index == (compact ? displayAngles.length - 1 : 0) ? table.flat : null,
              isLastRow: index == displayAngles.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final speedDesc = AngleSightMarkCalculator.getSpeedDescription(arrowSpeedFps);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${distance?.toStringAsFixed(0) ?? '--'} ${distanceUnit ?? ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceBright,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${arrowSpeedFps.toStringAsFixed(0)} fps ($speedDesc)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeaders(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'UPHILL',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            'FLAT',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Text(
            'DOWNHILL',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(
    BuildContext context, {
    required AngleTableEntry uphill,
    required AngleTableEntry downhill,
    AngleTableEntry? flat,
    required bool isLastRow,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Uphill column
          Expanded(
            child: _buildAngleCell(context, uphill, isUphill: true),
          ),
          // Flat column (only shown in one row)
          SizedBox(
            width: 60,
            child: flat != null
                ? _buildFlatCell(context, flat)
                : const SizedBox(),
          ),
          // Downhill column
          Expanded(
            child: _buildAngleCell(context, downhill, isUphill: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleCell(
    BuildContext context,
    AngleTableEntry entry, {
    required bool isUphill,
  }) {
    final angleText = isUphill
        ? '-${entry.angle.abs().toStringAsFixed(0)}'
        : '+${entry.angle.toStringAsFixed(0)}';

    final valueText = displayMode == AngleTableDisplayMode.degrees
        ? entry.sightMark.toStringAsFixed(2)
        : '${entry.percentage.toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: onAngleTap != null
          ? () => onAngleTap!(entry.angle, entry.sightMark)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: onAngleTap != null
              ? AppColors.surfaceBright.withValues(alpha: 0.3)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              angleText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
            ),
            Text(
              valueText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatCell(BuildContext context, AngleTableEntry entry) {
    final valueText = displayMode == AngleTableDisplayMode.degrees
        ? entry.sightMark.toStringAsFixed(2)
        : '100%';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontSize: 9,
                ),
          ),
          Text(
            valueText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact angle calculator widget for embedding in other screens.
///
/// Shows a quick angle calculation with minimal UI.
class CompactAngleCalculator extends StatefulWidget {
  /// Flat sight mark value
  final double flatSightMark;

  /// Arrow speed in fps
  final double arrowSpeedFps;

  /// Distance for display
  final double distance;

  /// Distance unit
  final String distanceUnit;

  /// Callback to open full calculator
  final VoidCallback? onExpandTap;

  const CompactAngleCalculator({
    super.key,
    required this.flatSightMark,
    required this.arrowSpeedFps,
    required this.distance,
    required this.distanceUnit,
    this.onExpandTap,
  });

  @override
  State<CompactAngleCalculator> createState() => _CompactAngleCalculatorState();
}

class _CompactAngleCalculatorState extends State<CompactAngleCalculator> {
  double _selectedAngle = 15.0;
  bool _isUphill = true;
  AngleTableDisplayMode _displayMode = AngleTableDisplayMode.degrees;

  @override
  Widget build(BuildContext context) {
    final effectiveAngle = _isUphill ? -_selectedAngle : _selectedAngle;
    final sightMark = AngleSightMarkCalculator.getSightMarkForAngle(
      flatSightMark: widget.flatSightMark,
      angleDegrees: effectiveAngle,
      arrowSpeedFps: widget.arrowSpeedFps,
    );
    final percentage = AngleSightMarkCalculator.getSightMarkAsPercentage(
      flatSightMark: widget.flatSightMark,
      angleDegrees: effectiveAngle,
      arrowSpeedFps: widget.arrowSpeedFps,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.terrain, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Angle Calculator',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              if (widget.onExpandTap != null)
                GestureDetector(
                  onTap: widget.onExpandTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Full Table',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gold,
                                fontSize: 10,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 12, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Direction toggle
          Row(
            children: [
              _buildDirectionButton(context, 'Uphill', true),
              const SizedBox(width: AppSpacing.sm),
              _buildDirectionButton(context, 'Downhill', false),
              const Spacer(),
              // Display mode toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _displayMode = _displayMode == AngleTableDisplayMode.degrees
                        ? AngleTableDisplayMode.percentage
                        : AngleTableDisplayMode.degrees;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _displayMode == AngleTableDisplayMode.degrees ? 'DEG' : '%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Angle selector
          Wrap(
            spacing: AppSpacing.xs,
            children: [5.0, 10.0, 15.0, 20.0, 25.0].map((angle) {
              final isSelected = _selectedAngle == angle;
              return GestureDetector(
                onTap: () => setState(() => _selectedAngle = angle),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected ? Border.all(color: AppColors.gold) : null,
                  ),
                  child: Text(
                    '${angle.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppColors.gold : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Result
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${widget.distance.toStringAsFixed(0)} ${widget.distanceUnit} at ${effectiveAngle > 0 ? '+' : ''}${effectiveAngle.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayMode == AngleTableDisplayMode.degrees
                        ? sightMark.toStringAsFixed(2)
                        : '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_displayMode == AngleTableDisplayMode.degrees)
                    Text(
                      '(${percentage.toStringAsFixed(1)}% of flat)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(BuildContext context, String label, bool isUphill) {
    final isSelected = _isUphill == isUphill;
    final color = isUphill ? const Color(0xFF4CAF50) : AppColors.gold;

    return GestureDetector(
      onTap: () => setState(() => _isUphill = isUphill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: color) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUphill ? Icons.north_east : Icons.south_east,
              size: 14,
              color: isSelected ? color : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? color : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
