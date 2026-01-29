import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/field_peg_state.dart';

/// Bottom sheet for recording actual sight marks after completing a target.
///
/// For walk-down targets: shows per-peg recording fields (4 fields, pre-filled with recommended marks)
/// For single-peg targets: shows a single field
class FieldSightmarkRecordSheet extends StatefulWidget {
  /// Peg states from the completed target (contains recommended marks)
  final List<FieldPegState> pegs;

  /// Whether this is a walk-down target
  final bool isWalkDown;

  /// Callback with map of pegIndex -> recorded mark
  final ValueChanged<Map<int, String>> onSave;

  /// Visit count for this target (for messaging)
  final int visitCount;

  const FieldSightmarkRecordSheet({
    super.key,
    required this.pegs,
    required this.isWalkDown,
    required this.onSave,
    this.visitCount = 0,
  });

  @override
  State<FieldSightmarkRecordSheet> createState() =>
      _FieldSightmarkRecordSheetState();
}

class _FieldSightmarkRecordSheetState
    extends State<FieldSightmarkRecordSheet> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.pegs.map((peg) {
      // Pre-fill with the recommended mark if available
      final prefill = peg.sightMarkUsed ??
          (peg.sightMarkRecommended?.toStringAsFixed(2));
      return TextEditingController(text: prefill ?? '');
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'RECORD SIGHT MARKS',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle / motivation
          Text(
            widget.visitCount == 0
                ? 'Recording your actual marks helps the app learn this course'
                : 'Visit ${widget.visitCount + 1} — your marks improve recommendations',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Per-peg fields
          if (widget.isWalkDown)
            ..._buildWalkDownFields()
          else
            ..._buildSinglePegField(),

          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  child: Text(
                    'SKIP',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  child: Text(
                    'SAVE MARKS',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildWalkDownFields() {
    return List.generate(widget.pegs.length, (i) {
      final peg = widget.pegs[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            // Peg label
            SizedBox(
              width: 80,
              child: Text(
                'PEG ${i + 1}',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            // Distance
            SizedBox(
              width: 56,
              child: Text(
                peg.distanceDisplay,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            // Input field
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _controllers[i],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      borderSide: const BorderSide(color: AppColors.surfaceLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      borderSide: const BorderSide(color: AppColors.surfaceLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildSinglePegField() {
    return [
      Row(
        children: [
          Text(
            'MARK USED:',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _controllers.first,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _onSave() {
    final marks = <int, String>{};
    for (int i = 0; i < _controllers.length; i++) {
      final text = _controllers[i].text.trim();
      if (text.isNotEmpty) {
        marks[i] = text;
      }
    }

    widget.onSave(marks);
    Navigator.pop(context);
  }
}
