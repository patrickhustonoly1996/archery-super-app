import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

// Conditional imports for camera (only used on native)
// These packages gracefully handle web by not initializing
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

/// A custom reference line drawn by the user
class ReferenceLine {
  final Offset startNormalized; // 0.0-1.0 relative to view size
  final Offset endNormalized;
  final Color color;

  ReferenceLine({
    required this.startNormalized,
    required this.endNormalized,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'sx': startNormalized.dx,
        'sy': startNormalized.dy,
        'ex': endNormalized.dx,
        'ey': endNormalized.dy,
        'color': color.value,
      };

  factory ReferenceLine.fromJson(Map<String, dynamic> json) => ReferenceLine(
        startNormalized: Offset(json['sx'] as double, json['sy'] as double),
        endNormalized: Offset(json['ex'] as double, json['ey'] as double),
        color: Color(json['color'] as int),
      );
}

/// Highly visible colors for reference lines
class LineColors {
  static const List<Color> available = [
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Lime green
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF00FF), // Magenta
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF6600), // Orange
    Color(0xFF00FF99), // Spring green
    Color(0xFFFFFFFF), // White
  ];
}

class DelayedCameraScreen extends StatefulWidget {
  const DelayedCameraScreen({super.key});

  @override
  State<DelayedCameraScreen> createState() => _DelayedCameraScreenState();
}

class _DelayedCameraScreenState extends State<DelayedCameraScreen> {
  @override
  Widget build(BuildContext context) {
    // Web doesn't support camera - show message
    if (kIsWeb) {
      return const _WebNotSupportedScreen();
    }

    // Native platforms get the full camera experience
    return const _NativeCameraScreen();
  }
}

/// Shown on web - camera not supported
class _WebNotSupportedScreen extends StatelessWidget {
  const _WebNotSupportedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delayed View',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: const Icon(
                  Icons.videocam_off,
                  size: 40,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'CAMERA NOT AVAILABLE',
                style: TextStyle(
                  fontFamily: 'VT323',
                  fontSize: 24,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'The delayed video feature requires the mobile app.\n\nDownload on iOS or Android to use your camera for form review.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Show a preview of what the feature does
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: const Column(
                  children: [
                    Text(
                      'FEATURE PREVIEW',
                      style: TextStyle(
                        fontFamily: 'VT323',
                        fontSize: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FeatureItem(icon: Icons.timer, label: '7s delay'),
                        SizedBox(width: AppSpacing.lg),
                        _FeatureItem(icon: Icons.grid_on, label: 'Grid overlay'),
                        SizedBox(width: AppSpacing.lg),
                        _FeatureItem(icon: Icons.edit, label: 'Draw lines'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Timestamped frame for the delay buffer
class _TimestampedFrame {
  final Uint8List bytes;
  final int timestamp;

  _TimestampedFrame({
    required this.bytes,
    required this.timestamp,
  });
}

/// Native camera implementation
class _NativeCameraScreen extends StatefulWidget {
  const _NativeCameraScreen();

  @override
  State<_NativeCameraScreen> createState() => _NativeCameraScreenState();
}

class _NativeCameraScreenState extends State<_NativeCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Delay settings
  double _delaySeconds = 7.0;
  static const double _minDelay = 1.0;
  static const double _maxDelay = 15.0;

  // Grid overlay (rule of thirds)
  bool _showGrid = false;

  // Custom reference lines
  List<ReferenceLine> _referenceLines = [];
  bool _isDrawMode = false;
  Offset? _drawStart;
  Offset? _drawCurrent;
  Color _selectedColor = LineColors.available[0];

  // Frame buffer for delayed playback
  final Queue<_TimestampedFrame> _frameBuffer = Queue();
  Uint8List? _displayFrame;

  // Capture timer
  Timer? _captureTimer;
  static const int _captureIntervalMs = 200;

  // Saving state
  bool _isSaving = false;
  bool _showSavedMessage = false;

  // Preferences key
  static const String _prefsKeyDelay = 'delayed_camera_delay';
  static const String _prefsKeyLines = 'delayed_camera_lines';
  static const String _prefsKeyColor = 'delayed_camera_color';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _captureTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startCaptureLoop();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _delaySeconds = prefs.getDouble(_prefsKeyDelay) ?? 7.0;
      _selectedColor = Color(
        prefs.getInt(_prefsKeyColor) ?? LineColors.available[0].value,
      );

      final linesJson = prefs.getString(_prefsKeyLines);
      if (linesJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(linesJson);
          _referenceLines = decoded
              .map((e) => ReferenceLine.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          _referenceLines = [];
        }
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKeyDelay, _delaySeconds);
    await prefs.setInt(_prefsKeyColor, _selectedColor.value);
    await prefs.setString(
      _prefsKeyLines,
      jsonEncode(_referenceLines.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Camera permission required';
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available';
        });
        return;
      }

      // Prefer back camera
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _startCaptureLoop();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _startCaptureLoop() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(
      const Duration(milliseconds: _captureIntervalMs),
      (_) => _captureFrame(),
    );
  }

  Future<void> _captureFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Temp file cleanup handled by OS

      _frameBuffer.add(_TimestampedFrame(bytes: bytes, timestamp: now));

      final cutoff = now - ((_delaySeconds + 2) * 1000).toInt();
      while (_frameBuffer.isNotEmpty && _frameBuffer.first.timestamp < cutoff) {
        _frameBuffer.removeFirst();
      }

      final targetTime = now - (_delaySeconds * 1000).toInt();
      _TimestampedFrame? frameToDisplay;

      for (final f in _frameBuffer) {
        if (f.timestamp <= targetTime) {
          frameToDisplay = f;
        } else {
          break;
        }
      }

      if (frameToDisplay != null && mounted) {
        setState(() {
          _displayFrame = frameToDisplay!.bytes;
        });
      }
    } catch (e) {
      // Skip frame on error
    }
  }

  Future<void> _saveEpicShot() async {
    if (_displayFrame == null) {
      _showSnackBar('No frame to save');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ImageGallerySaverPlus.saveImage(
        _displayFrame!,
        quality: 95,
        name: 'archery_shot_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        setState(() {
          _showSavedMessage = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showSavedMessage = false;
            });
          }
        });
      } else {
        _showSnackBar('Failed to save');
      }
    } catch (e) {
      _showSnackBar('Error saving: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  void _onDrawStart(Offset localPosition, Size size) {
    if (!_isDrawMode) return;
    setState(() {
      _drawStart = Offset(
        localPosition.dx / size.width,
        localPosition.dy / size.height,
      );
      _drawCurrent = _drawStart;
    });
  }

  void _onDrawUpdate(Offset localPosition, Size size) {
    if (!_isDrawMode || _drawStart == null) return;
    setState(() {
      _drawCurrent = Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0),
        (localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  void _onDrawEnd(Size size) {
    if (!_isDrawMode || _drawStart == null || _drawCurrent == null) return;

    final dx = (_drawCurrent!.dx - _drawStart!.dx).abs();
    final dy = (_drawCurrent!.dy - _drawStart!.dy).abs();
    if (dx > 0.02 || dy > 0.02) {
      setState(() {
        _referenceLines.add(ReferenceLine(
          startNormalized: _drawStart!,
          endNormalized: _drawCurrent!,
          color: _selectedColor,
        ));
      });
      _savePreferences();
    }

    setState(() {
      _drawStart = null;
      _drawCurrent = null;
    });
  }

  void _clearAllLines() {
    setState(() {
      _referenceLines.clear();
    });
    _savePreferences();
  }

  void _undoLastLine() {
    if (_referenceLines.isNotEmpty) {
      setState(() {
        _referenceLines.removeLast();
      });
      _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isDrawMode ? 'Draw Lines' : 'Delayed View',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_on : Icons.grid_off,
              color: _showGrid ? AppColors.gold : AppColors.textMuted,
            ),
            onPressed: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
            tooltip: 'Toggle grid',
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: _isDrawMode ? AppColors.gold : AppColors.textMuted,
            ),
            onPressed: () {
              setState(() {
                _isDrawMode = !_isDrawMode;
              });
            },
            tooltip: 'Draw lines',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: AppSpacing.md),
            Text(
              'Initializing camera...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (details) =>
                    _onDrawStart(details.localPosition, size),
                onPanUpdate: (details) =>
                    _onDrawUpdate(details.localPosition, size),
                onPanEnd: (_) => _onDrawEnd(size),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildDelayedPreview(),
                    if (_showGrid) _buildGridOverlay(),
                    if (_referenceLines.isNotEmpty || _drawStart != null)
                      CustomPaint(
                        painter: _ReferenceLinesPainter(
                          lines: _referenceLines,
                          currentStart: _drawStart,
                          currentEnd: _drawCurrent,
                          currentColor: _selectedColor,
                          viewSize: size,
                        ),
                        size: Size.infinite,
                      ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                        ),
                        child: Text(
                          '${_delaySeconds.toStringAsFixed(1)}s delay',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontFamily: 'VT323',
                          ),
                        ),
                      ),
                    ),
                    if (_isDrawMode)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: const Text(
                            'DRAW MODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (_displayFrame == null)
                      Positioned(
                        bottom: AppSpacing.md,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: Text(
                              'Building ${_delaySeconds.toStringAsFixed(0)}s buffer...',
                              style:
                                  const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    if (_showSavedMessage)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Saved to Photos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          color: AppColors.surfaceDark,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SafeArea(
            top: false,
            child: _isDrawMode ? _buildDrawControls() : _buildMainControls(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.timer, color: AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${_minDelay.toInt()}s',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.gold,
                  inactiveTrackColor: AppColors.surfaceLight,
                  thumbColor: AppColors.gold,
                  overlayColor: AppColors.gold.withOpacity(0.2),
                ),
                child: Slider(
                  value: _delaySeconds,
                  min: _minDelay,
                  max: _maxDelay,
                  divisions: ((_maxDelay - _minDelay) * 2).toInt(),
                  onChanged: (value) {
                    setState(() {
                      _delaySeconds = value;
                    });
                  },
                  onChangeEnd: (_) => _savePreferences(),
                ),
              ),
            ),
            Text(
              '${_maxDelay.toInt()}s',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                _isSaving || _displayFrame == null ? null : _saveEpicShot,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.backgroundDark,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_alt),
            label: const Text('That was epic - Save it'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawControls() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Color:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: LineColors.available.map((color) {
                    final isSelected = color.value == _selectedColor.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                        _savePreferences();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Drag to draw lines',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _referenceLines.isEmpty ? null : _undoLastLine,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Undo'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: _referenceLines.isEmpty ? null : _clearAllLines,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isDrawMode = false;
              });
            },
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildDelayedPreview() {
    if (_displayFrame == null) {
      return Container(color: Colors.black);
    }

    return Image.memory(
      _displayFrame!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withOpacity(0.4)
      ..strokeWidth = 1;

    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;

    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );

    // Center crosshairs
    final centerPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.6)
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const crossSize = 20.0;

    canvas.drawLine(
      Offset(cx - crossSize, cy),
      Offset(cx + crossSize, cy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - crossSize),
      Offset(cx, cy + crossSize),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReferenceLinesPainter extends CustomPainter {
  final List<ReferenceLine> lines;
  final Offset? currentStart;
  final Offset? currentEnd;
  final Color currentColor;
  final Size viewSize;

  _ReferenceLinesPainter({
    required this.lines,
    required this.currentStart,
    required this.currentEnd,
    required this.currentColor,
    required this.viewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved lines
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          line.startNormalized.dx * size.width,
          line.startNormalized.dy * size.height,
        ),
        Offset(
          line.endNormalized.dx * size.width,
          line.endNormalized.dy * size.height,
        ),
        paint,
      );
    }

    // Draw current line being drawn
    if (currentStart != null && currentEnd != null) {
      final paint = Paint()
        ..color = currentColor.withOpacity(0.7)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          currentStart!.dx * size.width,
          currentStart!.dy * size.height,
        ),
        Offset(
          currentEnd!.dx * size.width,
          currentEnd!.dy * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceLinesPainter oldDelegate) => true;
}
