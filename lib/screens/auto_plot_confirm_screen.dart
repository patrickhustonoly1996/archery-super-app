import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';
import '../services/vision_api_service.dart';

/// Screen to review and adjust detected arrow positions
class AutoPlotConfirmScreen extends StatefulWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotConfirmScreen({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  State<AutoPlotConfirmScreen> createState() => _AutoPlotConfirmScreenState();
}

class _AutoPlotConfirmScreenState extends State<AutoPlotConfirmScreen> with WidgetsBindingObserver {
  // Multi-select for tournament scenarios (up to 24 arrows, user picks their 6)
  final Set<int> _selectedArrowIndices = {};
  // Track if we're in "select my arrows" mode vs "adjust" mode
  bool _isSelectionMode = true;
  // Auto-accept timer (activates when arrows are auto-selected)
  Timer? _autoAcceptTimer;
  int _autoAcceptSecondsRemaining = 0;
  static const int _autoAcceptDelay = 8; // seconds to wait before auto-accepting
  bool _autoSelectApplied = false;
  // Track if we're currently learning arrows (prevent navigation issues)
  bool _isLearningInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-select arrows marked as "my arrows" after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectMyArrows();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoAcceptTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If user switches away while auto-accept is running, just cancel the timer.
    // Don't auto-confirm - user may have accidentally backgrounded the app.
    // They can manually confirm when they return.
    if (state == AppLifecycleState.paused && _autoAcceptTimer != null) {
      _cancelAutoAccept();
    }
  }

  void _autoSelectMyArrows() {
    if (_autoSelectApplied) return;
    _autoSelectApplied = true;

    final provider = context.read<AutoPlotProvider>();
    final arrows = provider.detectedArrows;

    // Find all arrows marked as "my arrow"
    final myArrowIndices = <int>[];
    for (int i = 0; i < arrows.length; i++) {
      if (arrows[i].isMyArrow) {
        myArrowIndices.add(i);
      }
    }

    if (myArrowIndices.isNotEmpty) {
      setState(() {
        _selectedArrowIndices.addAll(myArrowIndices);
      });
      // Start auto-accept countdown if we auto-selected some arrows
      _startAutoAcceptTimer();
    }
  }

  void _startAutoAcceptTimer() {
    _autoAcceptTimer?.cancel();
    setState(() {
      _autoAcceptSecondsRemaining = _autoAcceptDelay;
    });

    _autoAcceptTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _autoAcceptSecondsRemaining--;
      });
      if (_autoAcceptSecondsRemaining <= 0) {
        timer.cancel();
        _autoAcceptTimer = null;
        // Auto-confirm
        final provider = context.read<AutoPlotProvider>();
        if (_selectedArrowIndices.isNotEmpty) {
          _confirmSelectedArrows(provider);
        }
      }
    });
  }

  void _cancelAutoAccept() {
    _autoAcceptTimer?.cancel();
    _autoAcceptTimer = null;
    setState(() {
      _autoAcceptSecondsRemaining = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'CONFIRM ARROWS',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            context.read<AutoPlotProvider>().retryCapture();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AutoPlotProvider>().retryCapture();
              Navigator.of(context).pop();
            },
            child: Text(
              'RETRY',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AutoPlotProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                color: AppColors.surfaceDark,
                child: Column(
                  children: [
                    Text(
                      _isSelectionMode
                          ? 'TAP YOUR ARROWS TO SELECT THEM'
                          : 'Drag to adjust. Tap empty space to add.',
                      style: TextStyle(
                        fontFamily: _isSelectionMode ? AppFonts.pixel : AppFonts.body,
                        fontSize: _isSelectionMode ? 14 : 12,
                        color: _isSelectionMode ? AppColors.gold : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isSelectionMode && provider.detectedArrows.length > 6) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${provider.detectedArrows.length} arrows detected - select yours',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    // Line cutter hint
                    if (provider.detectedArrows.any((a) => a.needsVerification)) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Orange = line cutter - verify position',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Target visualization with arrows
              Expanded(
                child: _buildTargetView(provider),
              ),
              // Arrow count and controls
              _buildControls(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTargetView(AutoPlotProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final padding = 16.0;
        final targetSize = size - padding * 2;

        return Center(
          child: GestureDetector(
            onTapUp: (details) {
              _handleTap(details.localPosition, targetSize, padding, provider);
            },
            child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(padding),
              child: Stack(
                children: [
                  // Target face
                  _buildTargetFace(targetSize),
                  // Detected arrows
                  ...provider.detectedArrows.asMap().entries.map((entry) {
                    return _buildArrowMarker(
                      entry.key,
                      entry.value,
                      targetSize,
                      provider,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetFace(double size) {
    // Use appropriate target painter based on type
    return CustomPaint(
      size: Size(size, size),
      painter: _TargetPainter(isTripleSpot: widget.isTripleSpot),
    );
  }

  Widget _buildArrowMarker(
    int index,
    DetectedArrow arrow,
    double targetSize,
    AutoPlotProvider provider,
  ) {
    final isSelected = _selectedArrowIndices.contains(index);
    final needsVerification = arrow.needsVerification;

    // Smaller markers for dense scenarios (24 arrows)
    final totalArrows = provider.detectedArrows.length;
    final baseSize = totalArrows > 12 ? 14.0 : 18.0;
    final markerSize = isSelected ? baseSize + 6 : baseSize;

    // Convert normalized coordinates (-1 to 1) to pixel position
    final centerX = targetSize / 2;
    final centerY = targetSize / 2;
    final x = centerX + (arrow.x * targetSize / 2);
    final y = centerY + (arrow.y * targetSize / 2);

    // Color based on state: gold=selected, orange=line cutter, grey=normal
    Color markerColor;
    Color borderColor;
    if (isSelected) {
      markerColor = AppColors.gold;
      borderColor = AppColors.background;
    } else if (needsVerification) {
      markerColor = Colors.orange;
      borderColor = Colors.orange.shade800;
    } else {
      markerColor = AppColors.textSecondary.withOpacity(0.7);
      borderColor = AppColors.textPrimary.withOpacity(0.5);
    }

    return Positioned(
      left: x - markerSize / 2,
      top: y - markerSize / 2,
      child: GestureDetector(
        onTap: () {
          // User interaction cancels auto-accept
          _cancelAutoAccept();
          setState(() {
            if (_isSelectionMode) {
              // Multi-select toggle
              if (_selectedArrowIndices.contains(index)) {
                _selectedArrowIndices.remove(index);
              } else {
                _selectedArrowIndices.add(index);
              }
            } else {
              // Single select for adjustment mode
              if (_selectedArrowIndices.contains(index)) {
                _selectedArrowIndices.remove(index);
              } else {
                _selectedArrowIndices.clear();
                _selectedArrowIndices.add(index);
              }
            }
          });
        },
        onPanUpdate: !_isSelectionMode ? (details) {
          _handleArrowDrag(index, details.delta, targetSize, provider);
        } : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: markerColor,
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ] : needsVerification ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: totalArrows <= 12 ? Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: isSelected ? 10 : 8,
                    color: isSelected ? AppColors.background : AppColors.textPrimary,
                  ),
                ),
              ) : null, // Hide numbers when > 12 arrows for cleaner view
            ),
            // Line cutter indicator (question mark badge)
            if (needsVerification)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade800,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset position, double targetSize, double padding, AutoPlotProvider provider) {
    // User interaction cancels auto-accept
    _cancelAutoAccept();

    // Check if tap is within target bounds
    final adjustedPos = Offset(position.dx - padding, position.dy - padding);
    if (adjustedPos.dx < 0 || adjustedPos.dx > targetSize ||
        adjustedPos.dy < 0 || adjustedPos.dy > targetSize) {
      return;
    }

    // If in adjustment mode, deselect all
    if (!_isSelectionMode && _selectedArrowIndices.isNotEmpty) {
      setState(() {
        _selectedArrowIndices.clear();
      });
      return;
    }

    // In selection mode, taps on empty space do nothing
    if (_isSelectionMode) {
      return;
    }

    // Convert to normalized coordinates
    final centerX = targetSize / 2;
    final centerY = targetSize / 2;
    final normalizedX = (adjustedPos.dx - centerX) / (targetSize / 2);
    final normalizedY = (adjustedPos.dy - centerY) / (targetSize / 2);

    // Add new arrow (adjustment mode only)
    provider.addArrow(normalizedX, normalizedY);
  }

  void _handleArrowDrag(int index, Offset delta, double targetSize, AutoPlotProvider provider) {
    final arrows = provider.detectedArrows;
    if (index >= arrows.length) return;

    final arrow = arrows[index];

    // Convert delta to normalized coordinates
    final normalizedDeltaX = delta.dx / (targetSize / 2);
    final normalizedDeltaY = delta.dy / (targetSize / 2);

    // Clamp new position to target bounds
    final newX = (arrow.x + normalizedDeltaX).clamp(-1.0, 1.0);
    final newY = (arrow.y + normalizedDeltaY).clamp(-1.0, 1.0);

    provider.adjustArrow(index, newX, newY);
  }

  Widget _buildControls(AutoPlotProvider provider) {
    final totalArrows = provider.detectedArrows.length;
    final selectedCount = _selectedArrowIndices.length;
    final isTournamentMode = totalArrows > 6; // More than one archer's arrows

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection info and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalArrows == 0
                          ? 'No arrows detected'
                          : _isSelectionMode
                              ? '$selectedCount of $totalArrows selected'
                              : '$selectedCount ${selectedCount == 1 ? 'arrow' : 'arrows'} selected',
                      style: TextStyle(fontFamily: AppFonts.body, fontSize: 14),
                    ),
                    if (totalArrows == 0)
                      Text(
                        'Switch to adjust mode to add manually',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: AppColors.gold,
                        ),
                      )
                    else if (isTournamentMode && _isSelectionMode)
                      Text(
                        'Tap your arrows to select them',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    // Select All / Deselect All (useful for solo shooting)
                    if (_isSelectionMode && !isTournamentMode)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (selectedCount == totalArrows) {
                              _selectedArrowIndices.clear();
                            } else {
                              _selectedArrowIndices.clear();
                              _selectedArrowIndices.addAll(
                                List.generate(totalArrows, (i) => i),
                              );
                            }
                          });
                        },
                        child: Text(
                          selectedCount == totalArrows ? 'DESELECT ALL' : 'SELECT ALL',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    // Delete selected (in adjustment mode)
                    if (!_isSelectionMode && selectedCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          // Delete in reverse order to maintain indices
                          // After deletion, clear all selections since indices shift
                          final sortedIndices = _selectedArrowIndices.toList()
                            ..sort((a, b) => b.compareTo(a));
                          for (final index in sortedIndices) {
                            provider.removeArrow(index);
                          }
                          setState(() {
                            // Clear ALL selections - indices are now invalid
                            _selectedArrowIndices.clear();
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        label: Text(
                          'DELETE',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Auto-accept countdown banner
            if (_autoAcceptSecondsRemaining > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: AppColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Auto-confirming in $_autoAcceptSecondsRemaining...',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelAutoAccept,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Mode toggle and confirm buttons
            if (_isSelectionMode) ...[
              // In selection mode: show "Continue with selected" button
              // Special case: if no arrows detected, show button to switch to adjust mode
              if (totalArrows == 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ADD ARROWS MANUALLY',
                      style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 16),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedCount > 0
                        ? () {
                            _cancelAutoAccept();
                            if (isTournamentMode) {
                              // In tournament mode, go to adjustment mode with selected arrows
                              setState(() {
                                _isSelectionMode = false;
                              });
                            } else {
                              // Solo mode - confirm immediately
                              _confirmSelectedArrows(provider);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isTournamentMode
                          ? 'CONTINUE WITH $selectedCount ARROWS'
                          : 'CONFIRM & PLOT',
                      style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 16),
                    ),
                  ),
                ),
            ] else ...[
              // In adjustment mode: show adjust tip and confirm button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.surfaceLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'BACK',
                        style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: selectedCount > 0
                          ? () => _confirmSelectedArrows(provider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.background,
                        disabledBackgroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'CONFIRM & PLOT',
                        style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmSelectedArrows(AutoPlotProvider provider) {
    // Get only the selected arrows
    final allArrows = provider.detectedArrows;
    final selectedArrows = _selectedArrowIndices
        .where((i) => i < allArrows.length)
        .map((i) => allArrows[i])
        .toList();

    // If this was a manual selection (no arrows were auto-selected as "mine")
    // and user doesn't have learned appearance, learn from this selection
    // Note: We need to copy the image BEFORE reset since reset clears it
    final wasManualSelection = !allArrows.any((a) => a.isMyArrow);
    final shouldLearn = wasManualSelection && !provider.hasLearnedAppearance && selectedArrows.isNotEmpty;

    // Copy image data before any reset (learning needs it)
    final imageForLearning = shouldLearn ? provider.capturedImage : null;

    if (shouldLearn && imageForLearning != null) {
      // Learn in background - don't block the user
      // Pass copied data so it survives navigation
      _learnArrowsInBackground(provider, List.from(selectedArrows), imageForLearning);
    }

    // Always reset provider before navigating away
    provider.reset();

    Navigator.of(context).pop(selectedArrows);
  }

  Future<void> _learnArrowsInBackground(
    AutoPlotProvider provider,
    List<DetectedArrow> selectedArrows,
    Uint8List imageData,
  ) async {
    _isLearningInProgress = true;

    // Show brief notification - use rootScaffold to survive navigation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Learning your arrows...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceDark,
      ),
    );

    // Use the vision service directly with the copied image data
    // This avoids dependency on provider state which may have been reset
    final visionService = VisionApiService();
    final result = await visionService.learnArrowAppearance(
      image: imageData,
      selectedArrows: selectedArrows,
    );

    _isLearningInProgress = false;

    // Only show success notification if the result was successful
    // Use the captured scaffoldMessenger reference (not context) to be safe
    if (result.isSuccess) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.description != null
                ? 'Learned: ${result.description}'
                : 'Arrows learned - will auto-identify next time',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.gold,
        ),
      );
    }
  }
}

/// Custom painter for the target face
class _TargetPainter extends CustomPainter {
  final bool isTripleSpot;

  _TargetPainter({this.isTripleSpot = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (isTripleSpot) {
      _paintTripleSpot(canvas, size);
    } else {
      _paintSingleTarget(canvas, size);
    }
  }

  void _paintSingleTarget(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Ring colors (from outside to inside)
    final ringColors = [
      Colors.white, // 1-2
      Colors.white,
      Colors.black, // 3-4
      Colors.black,
      const Color(0xFF00AAFF), // 5-6 (blue)
      const Color(0xFF00AAFF),
      const Color(0xFFFF0000), // 7-8 (red)
      const Color(0xFFFF0000),
      const Color(0xFFFFD700), // 9-10 (gold)
      const Color(0xFFFFD700),
    ];

    // Draw rings from outside to inside
    for (int i = 0; i < 10; i++) {
      final ringRadius = maxRadius * (10 - i) / 10;
      final paint = Paint()
        ..color = ringColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);

      // Draw ring outline
      final outlinePaint = Paint()
        ..color = i < 4 ? Colors.grey : Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, ringRadius, outlinePaint);
    }

    // Draw X ring (inner gold)
    final xRingRadius = maxRadius * 0.5 / 10;
    final xRingPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, xRingRadius, xRingPaint);
  }

  void _paintTripleSpot(Canvas canvas, Size size) {
    // Triple spot: 3 smaller targets arranged vertically
    final spotRadius = size.width / 6;
    final spacing = size.height / 3;

    for (int spot = 0; spot < 3; spot++) {
      final centerY = spacing / 2 + spot * spacing;
      final center = Offset(size.width / 2, centerY);

      // Simplified 5-ring spot target (gold center only)
      final spotColors = [
        const Color(0xFF00AAFF), // outer blue
        const Color(0xFFFF0000), // red
        const Color(0xFFFFD700), // gold
      ];

      for (int i = 0; i < 3; i++) {
        final ringRadius = spotRadius * (3 - i) / 3;
        final paint = Paint()
          ..color = spotColors[i]
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, ringRadius, paint);

        final outlinePaint = Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(center, ringRadius, outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TargetPainter oldDelegate) =>
      oldDelegate.isTripleSpot != isTripleSpot;
}
