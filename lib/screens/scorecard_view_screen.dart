import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../widgets/world_archery_scorecard.dart';
import '../widgets/target_face.dart';
import '../services/signature_service.dart';
import '../services/scorecard_export_service.dart';

/// Full screen scorecard view with signatures and export functionality.
/// Can be used for live sessions or reviewing completed sessions.
class ScorecardViewScreen extends StatefulWidget {
  final String sessionId;
  final bool isLive;

  const ScorecardViewScreen({
    super.key,
    required this.sessionId,
    this.isLive = false,
  });

  @override
  State<ScorecardViewScreen> createState() => _ScorecardViewScreenState();
}

class _ScorecardViewScreenState extends State<ScorecardViewScreen> {
  late SignatureService _signatureService;
  Session? _session;
  RoundType? _roundType;
  List<End> _ends = [];
  List<List<Arrow>> _endArrows = [];
  bool _isLoading = true;

  // Archer profile
  String _archerName = '';
  String? _archerDob;
  String? _archerDivision;
  String? _archerBowClass;
  Uint8List? _archerSignature;
  Uint8List? _witnessSignature;

  // Editing state
  bool _isEditingName = false;
  final _nameController = TextEditingController();

  // Plot view state
  PlotViewMode _plotViewMode = PlotViewMode.full;
  int _selectedEndIndex = 0; // For per-end view
  bool _triSpotCombined = true; // Combined vs separate for triple spot

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    _signatureService = SignatureService(db);

    // Load session data
    final session = await db.getSession(widget.sessionId);
    if (session == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final roundType = await db.getRoundType(session.roundTypeId);
    final ends = await db.getEndsForSession(session.id);
    final endArrows = <List<Arrow>>[];

    for (final end in ends) {
      final arrows = await db.getArrowsForEnd(end.id);
      endArrows.add(arrows);
    }

    // Load archer profile
    final profile = await _signatureService.getArcherProfile();
    final witnessSignature = await _signatureService.getWitnessSignature(session.id);

    if (mounted) {
      setState(() {
        _session = session;
        _roundType = roundType;
        _ends = ends;
        _endArrows = endArrows;
        _archerName = profile.name ?? '';
        _archerDob = profile.dob;
        _archerDivision = profile.division;
        _archerBowClass = profile.bowClass;
        _archerSignature = profile.signature;
        _witnessSignature = witnessSignature;
        _nameController.text = _archerName;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveArcherName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await _signatureService.saveArcherName(name);
      setState(() {
        _archerName = name;
        _isEditingName = false;
      });
    }
  }

  Future<void> _onArcherSignatureChanged(Uint8List? signature) async {
    await _signatureService.saveArcherSignature(signature);
    setState(() => _archerSignature = signature);
  }

  Future<void> _onWitnessSignatureChanged(Uint8List? signature) async {
    if (_session != null) {
      await _signatureService.saveWitnessSignature(_session!.id, signature);
      setState(() => _witnessSignature = signature);
    }
  }

  /// Prompt user to add missing signatures before export
  Future<bool> _showSignaturePrompt() async {
    final missingArcher = _archerSignature == null;
    final missingWitness = _witnessSignature == null;

    String message;
    if (missingArcher && missingWitness) {
      message = 'Archer and witness signatures are missing.';
    } else if (missingArcher) {
      message = 'Archer signature is missing.';
    } else {
      message = 'Witness signature is missing.';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Missing Signatures',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            color: AppColors.gold,
          ),
        ),
        content: Text(
          '$message\n\nWould you like to add signatures now, or export without them?',
          style: TextStyle(
            fontFamily: AppFonts.body,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Export Without'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              // Scroll to signature section
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please add signatures below'),
                  backgroundColor: AppColors.surfaceLight,
                ),
              );
            },
            child: const Text('Add Signatures'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _exportPdf() async {
    if (_session == null || _roundType == null) return;

    // Check if signatures are present, prompt if missing
    if (_archerSignature == null || _witnessSignature == null) {
      final proceed = await _showSignaturePrompt();
      if (!proceed) return;
    }

    // Show export options dialog
    final options = await _showExportOptionsDialog();
    if (options == null) return;

    try {
      // Collect all arrows for plot generation
      final allArrows = <Arrow>[];
      for (final arrows in _endArrows) {
        allArrows.addAll(arrows);
      }

      // Generate plot images based on selected options (multi-select)
      List<Uint8List>? plotImages;
      List<String>? plotLabels;

      if (options.includePlot) {
        plotImages = [];
        plotLabels = [];

        final isTriSpot = (_roundType?.faceCount ?? 1) == 3;
        final scoringType = _roundType?.scoringType ?? '10-zone';

        // Process each selected style
        for (final style in options.selectedStyles) {
          if (style == PlotStyle.full || style == PlotStyle.triSpotCombined) {
            // Full session plot (all arrows on one face)
            final fullPlot = await _generatePlotImage(
              allArrows,
              showAsTriSpot: isTriSpot,
              scoringType: scoringType,
            );
            if (fullPlot != null) {
              plotImages.add(fullPlot);
              plotLabels.add('All Arrows');
            }
          } else if (style == PlotStyle.triSpotSeparate) {
            // Triple spot: arrows on their respective faces (1, 2, 3)
            for (int faceIndex = 0; faceIndex < 3; faceIndex++) {
              final faceArrows = allArrows.where((a) => a.faceIndex == faceIndex).toList();
              if (faceArrows.isNotEmpty) {
                final facePlot = await _generatePlotImage(
                  faceArrows,
                  showAsTriSpot: true,
                  scoringType: scoringType,
                );
                if (facePlot != null) {
                  plotImages.add(facePlot);
                  plotLabels.add('Face ${faceIndex + 1}');
                }
              }
            }
          } else if (style == PlotStyle.halves) {
            // First half and second half
            final halfEndCount = _ends.length ~/ 2;
            final firstHalfArrows = <Arrow>[];
            final secondHalfArrows = <Arrow>[];

            for (int i = 0; i < _ends.length; i++) {
              if (i < _endArrows.length) {
                if (i < halfEndCount) {
                  firstHalfArrows.addAll(_endArrows[i]);
                } else {
                  secondHalfArrows.addAll(_endArrows[i]);
                }
              }
            }

            final firstHalf = await _generatePlotImage(
              firstHalfArrows,
              showAsTriSpot: isTriSpot,
              scoringType: scoringType,
            );
            final secondHalf = await _generatePlotImage(
              secondHalfArrows,
              showAsTriSpot: isTriSpot,
              scoringType: scoringType,
            );
            if (firstHalf != null) {
              plotImages.add(firstHalf);
              plotLabels.add('First Half');
            }
            if (secondHalf != null) {
              plotImages.add(secondHalf);
              plotLabels.add('Second Half');
            }
          } else if (style == PlotStyle.perEnd) {
            // Per-end plots
            for (int i = 0; i < _endArrows.length; i++) {
              final endPlot = await _generatePlotImage(
                _endArrows[i],
                showAsTriSpot: isTriSpot,
                scoringType: scoringType,
              );
              if (endPlot != null) {
                plotImages.add(endPlot);
                plotLabels.add('End ${i + 1}');
              }
            }
          }
        }
      }

      final pdfBytes = await ScorecardExportService.generatePdf(
        session: _session!,
        roundType: _roundType!,
        ends: _ends,
        endArrows: _endArrows,
        archerName: _archerName.isNotEmpty ? _archerName : 'Unknown',
        archerDob: _archerDob,
        division: _archerDivision,
        bowClass: _archerBowClass,
        eventName: null,
        location: _session!.location,
        archerSignature: _archerSignature,
        witnessSignature: _witnessSignature,
        plotImages: plotImages,
        plotLabels: plotLabels,
      );

      final date = _session!.completedAt ?? _session!.startedAt;
      final filename = '${_roundType!.name}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.pdf';

      await ScorecardExportService.sharePdf(pdfBytes, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show export options dialog
  Future<ExportOptions?> _showExportOptionsDialog() async {
    final isTripleSpot = (_roundType?.faceCount ?? 1) == 3;
    return showDialog<ExportOptions>(
      context: context,
      builder: (ctx) => _ExportOptionsDialog(isTripleSpot: isTripleSpot),
    );
  }

  /// Generate a plot image for given arrows - using accurate target colors
  /// [showAsTriSpot] - if true, renders as tri-spot (rings 6-10 only, 2x scale)
  /// [scoringType] - '10-zone' (default), '5-zone' (IFAA), or 'worcester'
  Future<Uint8List?> _generatePlotImage(
    List<Arrow> arrows, {
    bool showAsTriSpot = false,
    String scoringType = '10-zone',
  }) async {
    if (arrows.isEmpty) return null;

    final isTriSpot = showAsTriSpot;
    final isWorcester = scoringType == 'worcester';

    // Much larger image size for better quality in export
    const int imageSize = 800;
    const double imageSizeDouble = 800.0;
    const double center = imageSizeDouble / 2;
    const double radius = imageSizeDouble / 2 - 20; // Small margin

    // Use canvas-based rendering for plot generation
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw white background for PDF export
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, imageSizeDouble, imageSizeDouble),
      Paint()..color = Colors.white,
    );

    if (isWorcester) {
      // Worcester target: 5 equal rings, white center (5), black outer (4,3,2,1)
      _drawWorcesterTarget(canvas, center, radius);
    } else {
      // Standard WA/IFAA target (same colors, different scoring)
      _drawStandardTarget(canvas, center, radius, isTriSpot);
    }

    // Draw arrows - larger markers for visibility
    const arrowMarkerSize = 12.0;
    for (final arrow in arrows) {
      // For tri-spot, arrow coordinates need scaling to match ring scaling
      final arrowScale = isTriSpot ? 2.0 : 1.0;
      final x = center + (arrow.x * arrowScale * radius);
      final y = center + (arrow.y * arrowScale * radius);

      // Determine marker color based on ring (for contrast)
      final (markerColor, borderColor) = _getArrowMarkerColors(
        arrow.score,
        isWorcester: isWorcester,
      );

      // Arrow marker - filled circle with border
      canvas.drawCircle(
        Offset(x, y),
        arrowMarkerSize,
        Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        arrowMarkerSize,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(imageSize, imageSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  /// Draw standard WA/IFAA target (10-zone or 5-zone use same colors)
  void _drawStandardTarget(Canvas canvas, double center, double radius, bool isTriSpot) {
    // Accurate World Archery target colors
    const goldColor = Color(0xFFFFD700);    // Gold/Yellow (9, 10, X)
    const redColor = Color(0xFFE30613);     // Red (7, 8)
    const blueColor = Color(0xFF009FE3);    // Blue (5, 6)
    const blackColor = Color(0xFF1D1D1B);   // Black (3, 4)
    const whiteColor = Color(0xFFFFFEFD);   // White (1, 2)

    // Ring boundary positions (normalized: 0 = center, 1 = edge)
    final ringData = isTriSpot
        ? [
            // Tri-spot: only rings 6-10 visible, scaled to fill face
            (1.0, blueColor),    // Ring 6 (outermost)
            (0.8, redColor),     // Ring 7
            (0.6, redColor),     // Ring 8
            (0.4, goldColor),    // Ring 9
            (0.2, goldColor),    // Ring 10
            (0.1, goldColor),    // X ring
          ]
        : [
            // Full target: all rings
            (1.0, whiteColor),   // Ring 1 (outermost)
            (0.9, whiteColor),   // Ring 2
            (0.8, blackColor),   // Ring 3
            (0.7, blackColor),   // Ring 4
            (0.6, blueColor),    // Ring 5
            (0.5, blueColor),    // Ring 6
            (0.4, redColor),     // Ring 7
            (0.3, redColor),     // Ring 8
            (0.2, goldColor),    // Ring 9
            (0.1, goldColor),    // Ring 10
            (0.05, goldColor),   // X ring
          ];

    // Draw rings from outside in
    for (final (ringFraction, color) in ringData) {
      final ringRadius = radius * ringFraction;
      canvas.drawCircle(
        Offset(center, center),
        ringRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    // Draw ring lines
    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final (ringFraction, _) in ringData) {
      final ringRadius = radius * ringFraction;
      canvas.drawCircle(Offset(center, center), ringRadius, linePaint);
    }

    // Draw center cross
    final crossSize = radius * 0.03;
    final crossPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center, center - crossSize),
      Offset(center, center + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center - crossSize, center),
      Offset(center + crossSize, center),
      crossPaint,
    );
  }

  /// Draw Worcester target: 5 equal rings, white center (5), black outer (4,3,2,1)
  void _drawWorcesterTarget(Canvas canvas, double center, double radius) {
    const blackColor = Color(0xFF1D1D1B);
    const whiteColor = Color(0xFFFFFEFD);

    // Worcester has 5 equal-width rings (each 20% of radius)
    // Ring 5 (center): white - scores 5
    // Rings 4, 3, 2, 1 (outer): black - scores 4, 3, 2, 1
    final ringData = [
      (1.0, blackColor),   // Ring 1 (outermost) - black
      (0.8, blackColor),   // Ring 2 - black
      (0.6, blackColor),   // Ring 3 - black
      (0.4, blackColor),   // Ring 4 - black
      (0.2, whiteColor),   // Ring 5 (center) - white
    ];

    // Draw rings from outside in
    for (final (ringFraction, color) in ringData) {
      final ringRadius = radius * ringFraction;
      canvas.drawCircle(
        Offset(center, center),
        ringRadius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    // Draw ring lines - white on black rings, black on white center
    for (int i = 0; i < ringData.length; i++) {
      final ringFraction = ringData[i].$1;
      final ringRadius = radius * ringFraction;
      // Use black line for innermost ring (white center), white for outer (black)
      final isWhiteRing = i == ringData.length - 1;
      final linePaint = Paint()
        ..color = isWhiteRing ? Colors.black : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(center, center), ringRadius, linePaint);
    }

    // Draw center cross
    final crossSize = radius * 0.06;
    final crossPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center, center - crossSize),
      Offset(center, center + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center - crossSize, center),
      Offset(center + crossSize, center),
      crossPaint,
    );
  }

  /// Get arrow marker colors based on score and target type
  /// Uses high-contrast combinations for visibility on all ring colors
  (Color markerColor, Color borderColor) _getArrowMarkerColors(
    int score, {
    bool isWorcester = false,
  }) {
    const goldColor = Color(0xFFFFD700);
    const redColor = Color(0xFFE30613);

    if (isWorcester) {
      // Worcester: score 5 is white center, 1-4 are black
      if (score == 5) {
        return (Colors.black, goldColor); // Black marker, gold border on white
      } else {
        return (Colors.white, goldColor); // White marker, gold border on black
      }
    }

    // Standard WA/IFAA target - ensure high contrast on all ring colors
    if (score >= 9) {
      return (Colors.black, Colors.white); // Black/white on gold
    } else if (score >= 7) {
      return (Colors.white, Colors.black); // White/black on red
    } else if (score >= 5) {
      return (Colors.white, Colors.black); // White/black on blue
    } else if (score >= 3) {
      return (Colors.white, goldColor); // White/gold on black - high visibility
    } else {
      // White rings (1-2): use black marker with red border for visibility
      return (Colors.black, redColor); // Black/red on white - stands out
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scorecard')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_session == null || _roundType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scorecard')),
        body: const Center(child: Text('Session not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_roundType!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // World Archery format scorecard with integrated signatures
            WorldArcheryScorecardWidget(
              session: _session,
              roundType: _roundType,
              ends: _ends,
              endArrows: _endArrows,
              currentEndArrows: const [],
              currentEndNumber: _ends.length + 1,
              archerName: _archerName.isNotEmpty ? _archerName : null,
              division: _archerDivision,
              bowClass: _archerBowClass,
              eventName: _session!.sessionType == 'competition' ? _session!.location : null,
              eventLocation: _session!.location,
              eventDate: _session!.completedAt ?? _session!.startedAt,
              archerSignature: _archerSignature,
              witnessSignature: _witnessSignature,
              onArcherSignatureChanged: _onArcherSignatureChanged,
              onWitnessSignatureChanged: _onWitnessSignatureChanged,
              showSignatures: true,
              isLive: widget.isLive,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Arrow plot preview section
            _buildArrowPlotSection(),

            const SizedBox(height: AppSpacing.lg),

            // Archer name edit section (tap to edit)
            _buildArcherNameEdit(),

            const SizedBox(height: AppSpacing.lg),

            // Signature capture section (full-size pads for signing)
            _buildSignatureCapture(),

            const SizedBox(height: AppSpacing.xl),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Build the arrow plot preview section with view mode selector
  Widget _buildArrowPlotSection() {
    final isTripleSpot = (_roundType?.faceCount ?? 1) == 3;
    final allArrows = _endArrows.expand((e) => e).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'ARROW PLOTS',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Triple spot toggle (only for triple spot rounds)
              if (isTripleSpot) ...[
                Text(
                  'View:',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildToggleChip(
                  label: 'Combined',
                  selected: _triSpotCombined,
                  onTap: () => setState(() => _triSpotCombined = true),
                ),
                const SizedBox(width: 4),
                _buildToggleChip(
                  label: 'Separate',
                  selected: !_triSpotCombined,
                  onTap: () => setState(() => _triSpotCombined = false),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // View mode selector
          _buildViewModeSelector(),
          const SizedBox(height: AppSpacing.md),

          // End selector (only for per-end view)
          if (_plotViewMode == PlotViewMode.perEnd) ...[
            _buildEndSelector(),
            const SizedBox(height: AppSpacing.md),
          ],

          // Arrow plot(s)
          _buildPlotDisplay(allArrows, isTripleSpot),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 10,
            color: selected ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildViewModeButton(PlotViewMode.full, 'Full Round'),
          const SizedBox(width: 8),
          _buildViewModeButton(PlotViewMode.firstHalf, 'First Half'),
          const SizedBox(width: 8),
          _buildViewModeButton(PlotViewMode.secondHalf, 'Second Half'),
          const SizedBox(width: 8),
          _buildViewModeButton(PlotViewMode.perEnd, 'Per End'),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(PlotViewMode mode, String label) {
    final isSelected = _plotViewMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _plotViewMode = mode;
        if (mode == PlotViewMode.perEnd) {
          _selectedEndIndex = 0;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: isSelected ? AppColors.backgroundDark : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEndSelector() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _ends.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedEndIndex == index;
          final end = _ends[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedEndIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'End ${index + 1}',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        color: isSelected ? AppColors.gold : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${end.endScore})',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: isSelected ? AppColors.gold.withValues(alpha: 0.7) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlotDisplay(List<Arrow> allArrows, bool isTripleSpot) {
    // Get arrows based on view mode
    final List<Arrow> displayArrows;
    String label;

    switch (_plotViewMode) {
      case PlotViewMode.full:
        displayArrows = allArrows;
        label = 'Full Round (${allArrows.length} arrows)';
        break;
      case PlotViewMode.firstHalf:
        final halfEndCount = _ends.length ~/ 2;
        displayArrows = [];
        for (int i = 0; i < halfEndCount && i < _endArrows.length; i++) {
          displayArrows.addAll(_endArrows[i]);
        }
        label = 'First Half - Ends 1-$halfEndCount (${displayArrows.length} arrows)';
        break;
      case PlotViewMode.secondHalf:
        final halfEndCount = _ends.length ~/ 2;
        displayArrows = [];
        for (int i = halfEndCount; i < _endArrows.length; i++) {
          displayArrows.addAll(_endArrows[i]);
        }
        label = 'Second Half - Ends ${halfEndCount + 1}-${_ends.length} (${displayArrows.length} arrows)';
        break;
      case PlotViewMode.perEnd:
        if (_selectedEndIndex < _endArrows.length) {
          displayArrows = _endArrows[_selectedEndIndex];
        } else {
          displayArrows = [];
        }
        final endScore = _selectedEndIndex < _ends.length ? _ends[_selectedEndIndex].endScore : 0;
        label = 'End ${_selectedEndIndex + 1} - Score: $endScore (${displayArrows.length} arrows)';
        break;
    }

    // Show label
    final labelWidget = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          color: AppColors.textMuted,
        ),
      ),
    );

    if (displayArrows.isEmpty) {
      return Column(
        children: [
          labelWidget,
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              'No arrows',
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    // Triple spot with separate view - show 3 faces
    if (isTripleSpot && !_triSpotCombined) {
      return Column(
        children: [
          labelWidget,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (faceIndex) {
              final faceArrows = displayArrows.where((a) => a.faceIndex == faceIndex).toList();
              final faceScore = faceArrows.fold(0, (sum, a) => sum + a.score);
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TargetFace(
                      arrows: faceArrows,
                      size: 100,
                      triSpot: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Face ${faceIndex + 1}',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$faceScore (${faceArrows.length})',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      );
    }

    // Single face or combined triple spot - show one face
    return Column(
      children: [
        labelWidget,
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TargetFace(
              arrows: displayArrows,
              size: 250,
              triSpot: isTripleSpot,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Stats row
        _buildPlotStats(displayArrows),
      ],
    );
  }

  Widget _buildPlotStats(List<Arrow> arrows) {
    final totalScore = arrows.fold(0, (sum, a) => sum + a.score);
    final xCount = arrows.where((a) => a.isX).length;
    final tenCount = arrows.where((a) => a.score == 10).length;
    final avgScore = arrows.isNotEmpty ? (totalScore / arrows.length) : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatChip('Score', totalScore.toString()),
        const SizedBox(width: 12),
        _buildStatChip('Avg', avgScore.toStringAsFixed(1)),
        const SizedBox(width: 12),
        _buildStatChip('10s', tenCount.toString()),
        const SizedBox(width: 12),
        _buildStatChip('Xs', xCount.toString()),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArcherNameEdit() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARCHER PROFILE',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Name field
          Row(
            children: [
              Expanded(
                child: _isEditingName
                    ? TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: AppColors.textMuted),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.surfaceLight),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.gold),
                          ),
                        ),
                        onSubmitted: (_) => _saveArcherName(),
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _isEditingName = true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Name',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _archerName.isNotEmpty ? _archerName : 'Tap to enter',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                color: _archerName.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_isEditingName)
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.gold),
                  onPressed: _saveArcherName,
                )
              else
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                  onPressed: () => setState(() => _isEditingName = true),
                ),
            ],
          ),

          // Note about auto-fill
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your name will auto-fill on future scorecards.',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCapture() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIGNATURES',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Archer signature - horizontal layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Archer',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _archerSignature != null
                          ? AppColors.gold.withValues(alpha: 0.5)
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: _archerSignature != null
                      ? Stack(
                          children: [
                            Center(
                              child: Image.memory(
                                _archerSignature!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => _onArcherSignatureChanged(null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => _showArcherSignatureDialog(),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.draw_outlined,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap to sign',
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 11,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_archerSignature == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Set your signature in Profile to auto-fill on all scorecards',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Witness signature - horizontal layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Witness',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _witnessSignature != null
                          ? AppColors.gold.withValues(alpha: 0.5)
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: _witnessSignature != null
                      ? Stack(
                          children: [
                            Center(
                              child: Image.memory(
                                _witnessSignature!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => _onWitnessSignatureChanged(null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => _showWitnessSignatureDialog(),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.draw_outlined,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap to sign',
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showArcherSignatureDialog() async {
    final result = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _HorizontalSignatureDialog(
        label: 'Archer Signature',
        existingSignature: _archerSignature,
      ),
    );
    if (result != null) {
      _onArcherSignatureChanged(result);
    }
  }

  Future<void> _showWitnessSignatureDialog() async {
    final result = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _HorizontalSignatureDialog(
        label: 'Witness Signature',
        existingSignature: _witnessSignature,
      ),
    );
    if (result != null) {
      _onWitnessSignatureChanged(result);
    }
  }
}

/// In-app plot view mode options
enum PlotViewMode {
  full,
  firstHalf,
  secondHalf,
  perEnd,
}

/// Plot export style options
enum PlotStyle {
  full,
  halves,
  perEnd,
  /// Triple spot: all arrows combined on one face
  triSpotCombined,
  /// Triple spot: arrows shown on their respective faces (1, 2, 3)
  triSpotSeparate,
}

/// Export options configuration - now supports multiple plot styles
class ExportOptions {
  final Set<PlotStyle> selectedStyles;

  const ExportOptions({
    required this.selectedStyles,
  });

  bool get includePlot => selectedStyles.isNotEmpty;
}

/// Export options dialog - multi-select for plot styles
class _ExportOptionsDialog extends StatefulWidget {
  final bool isTripleSpot;

  const _ExportOptionsDialog({this.isTripleSpot = false});

  @override
  State<_ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  final Set<PlotStyle> _selectedStyles = {};

  @override
  void initState() {
    super.initState();
    // Default to full/combined view selected
    _selectedStyles.add(
      widget.isTripleSpot ? PlotStyle.triSpotCombined : PlotStyle.full,
    );
  }

  void _toggleStyle(PlotStyle style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        'Include Plots',
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          color: AppColors.gold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select which plots to include:',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Triple spot specific options
          if (widget.isTripleSpot) ...[
            _buildCheckboxOption(
              style: PlotStyle.triSpotCombined,
              title: 'Full session (combined)',
              subtitle: 'All arrows on single target',
            ),
            _buildCheckboxOption(
              style: PlotStyle.triSpotSeparate,
              title: 'Three faces',
              subtitle: 'Arrows on faces 1, 2, 3 as shot',
            ),
          ] else ...[
            _buildCheckboxOption(
              style: PlotStyle.full,
              title: 'Full session',
              subtitle: 'All arrows on one target',
            ),
          ],

          // Common options for both
          _buildCheckboxOption(
            style: PlotStyle.halves,
            title: 'By halves',
            subtitle: 'First half & second half separately',
          ),
          _buildCheckboxOption(
            style: PlotStyle.perEnd,
            title: 'Per end',
            subtitle: 'Individual plot for each end',
          ),

          if (_selectedStyles.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No plots selected - scorecard will export without plots',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            ExportOptions(selectedStyles: _selectedStyles),
          ),
          child: const Text('Export PDF'),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption({
    required PlotStyle style,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedStyles.contains(style);
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textMuted,
          fontSize: 10,
        ),
      ),
      value: isSelected,
      onChanged: (_) => _toggleStyle(style),
      activeColor: AppColors.gold,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

/// Horizontal signature dialog for landscape signing
class _HorizontalSignatureDialog extends StatefulWidget {
  final String label;
  final Uint8List? existingSignature;

  const _HorizontalSignatureDialog({
    required this.label,
    this.existingSignature,
  });

  @override
  State<_HorizontalSignatureDialog> createState() => _HorizontalSignatureDialogState();
}

class _HorizontalSignatureDialogState extends State<_HorizontalSignatureDialog> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.textPrimary,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isNotEmpty) {
      final signature = await _controller.toPngBytes();
      if (mounted) {
        Navigator.pop(context, signature);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 16,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _controller.clear(),
                  child: Text(
                    'Clear',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Signature area - wider than tall for horizontal signature
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.gold, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm - 2),
                child: Stack(
                  children: [
                    Signature(
                      controller: _controller,
                      backgroundColor: AppColors.surfaceDark,
                    ),
                    // Signature line at bottom
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: Container(
                        height: 1,
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    // Hint text
                    Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          if (_controller.isNotEmpty) return const SizedBox.shrink();
                          return Text(
                            'Sign here',
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 18,
                              color: AppColors.textMuted.withValues(alpha: 0.2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
