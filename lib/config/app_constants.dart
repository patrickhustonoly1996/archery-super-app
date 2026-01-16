/// App-wide constants extracted from codebase.
///
/// Each constant is documented with its purpose and original location.
/// This prevents magic numbers and makes tuning easier.
library;

/// Arrow plotting constants
class PlottingConstants {
  PlottingConstants._();

  /// Vertical offset to position arrow above finger touch point.
  /// This compensates for the fact that users typically touch below
  /// where they want the arrow placed.
  /// Original location: target_face.dart
  static const double fingerTouchOffset = 60.0;

  /// Threshold for "linecutter" arrow detection (normalized coordinates).
  /// If an arrow is within this distance of a ring boundary, it's marked
  /// as potentially on the line (pending human judgment).
  /// Value: 4% of target radius
  /// Original location: target_face.dart
  static const double linecutterThreshold = 0.04;

  /// Minimum tap area for interactive target plotting.
  /// Prevents accidental taps and ensures accessibility.
  /// Original location: arrow_plotting_widget.dart
  static const double minimumTapArea = 44.0;
}

/// Scorecard display constants
class ScorecardConstants {
  ScorecardConstants._();

  /// Width of the end number column in scorecards
  /// Original location: scorecard_widget.dart
  static const double endColumnWidth = 32.0;

  /// Width of each arrow score column
  /// Original location: scorecard_widget.dart
  static const double arrowColumnWidth = 28.0;

  /// Width of the end total column
  /// Original location: scorecard_widget.dart
  static const double totalColumnWidth = 36.0;

  /// Width of the running total column
  /// Original location: scorecard_widget.dart
  static const double runningTotalWidth = 44.0;

  /// Height of each row in the scorecard
  /// Original location: scorecard_widget.dart
  static const double rowHeight = 32.0;

  /// Spacing between ends in the scorecard
  /// Original location: scorecard_widget.dart
  static const double endSpacing = 2.0;
}

/// Touch and accessibility constants
class TouchConstants {
  TouchConstants._();

  /// Minimum touch target size for accessibility (Material Design guideline).
  /// Buttons, tappable icons, etc. should be at least this size.
  /// Based on 48dp Material Design recommendation.
  static const double minimumTargetSize = 48.0;

  /// Recommended touch target size for comfortable interaction.
  /// Slightly larger than minimum for better UX.
  static const double recommendedTargetSize = 56.0;

  /// Minimum padding around interactive elements.
  /// Prevents accidental taps on adjacent elements.
  static const double minimumTargetPadding = 8.0;
}

/// Animation and timing constants
class AnimationConstants {
  AnimationConstants._();

  /// Duration for quick micro-interactions (button press, toggle)
  static const Duration microDuration = Duration(milliseconds: 100);

  /// Duration for standard transitions (page, dialog)
  static const Duration standardDuration = Duration(milliseconds: 200);

  /// Duration for slower, more dramatic animations
  static const Duration slowDuration = Duration(milliseconds: 400);

  /// Undo action window duration
  static const Duration undoWindowDuration = Duration(seconds: 5);
}

/// Target face constants
class TargetConstants {
  TargetConstants._();

  /// Standard outdoor target face diameter in mm (122cm)
  static const double outdoorTargetDiameterMm = 1220.0;

  /// Standard indoor target face diameter in mm (40cm)
  static const double indoorTargetDiameterMm = 400.0;

  /// Compound indoor target face diameter in mm (60cm)
  static const double compoundIndoorTargetDiameterMm = 600.0;

  /// Number of rings on a standard target face
  static const int standardRingCount = 10;

  /// Number of rings on a compound target face (inner 6)
  static const int compoundRingCount = 6;
}

/// Import/export constants
class ImportConstants {
  ImportConstants._();

  /// Maximum number of rows to show in import preview
  static const int maxPreviewRows = 10;

  /// Batch size for importing large datasets
  /// Prevents UI freeze and allows progress updates
  static const int importBatchSize = 50;

  /// Maximum number of skipped row reasons to store
  /// (prevents memory issues with very bad data)
  static const int maxSkippedReasons = 5;
}
