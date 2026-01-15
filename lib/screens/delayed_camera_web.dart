import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../theme/app_theme.dart';
import 'delayed_camera_screen.dart';

/// Entry point for platform-specific implementation
Widget buildDelayedCameraScreen(BuildContext context) {
  return const _WebCameraScreen();
}

/// Web camera implementation using getUserMedia
class _WebCameraScreen extends StatefulWidget {
  const _WebCameraScreen();

  @override
  State<_WebCameraScreen> createState() => _WebCameraScreenState();
}

class _WebCameraScreenState extends State<_WebCameraScreen> {
  static int _viewIdCounter = 0;
  late final String _viewId;

  web.HTMLVideoElement? _videoElement;
  web.HTMLCanvasElement? _canvasElement;
  web.MediaStream? _mediaStream;

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
  final Queue<TimestampedFrame> _frameBuffer = Queue();
  Uint8List? _displayFrame;

  // Capture timer
  Timer? _captureTimer;
  static const int _captureIntervalMs = 200;

  @override
  void initState() {
    super.initState();
    _viewId = 'delayed-camera-video-${_viewIdCounter++}';
    _loadPreferences();
    _initializeCamera();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _stopCamera();
    super.dispose();
  }

  void _stopCamera() {
    if (_mediaStream != null) {
      final tracks = _mediaStream!.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
      _mediaStream = null;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _delaySeconds = prefs.getDouble(DelayedCameraPrefs.keyDelay) ?? 7.0;
      _selectedColor = Color(
        prefs.getInt(DelayedCameraPrefs.keyColor) ?? LineColors.available[0].value,
      );

      final linesJson = prefs.getString(DelayedCameraPrefs.keyLines);
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
    await prefs.setDouble(DelayedCameraPrefs.keyDelay, _delaySeconds);
    await prefs.setInt(DelayedCameraPrefs.keyColor, _selectedColor.value);
    await prefs.setString(
      DelayedCameraPrefs.keyLines,
      jsonEncode(_referenceLines.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Create video element
      _videoElement = web.document.createElement('video') as web.HTMLVideoElement;
      _videoElement!.autoplay = true;
      _videoElement!.playsInline = true;
      _videoElement!.muted = true;
      _videoElement!.style.width = '100%';
      _videoElement!.style.height = '100%';
      _videoElement!.style.objectFit = 'cover';
      _videoElement!.style.transform = 'scaleX(-1)'; // Mirror for selfie view
      _videoElement!.setAttribute('playsinline', 'true'); // iOS requires this

      // Create canvas for frame capture
      _canvasElement = web.document.createElement('canvas') as web.HTMLCanvasElement;

      // Request camera access with preference for back camera (environment)
      final constraints = web.MediaStreamConstraints(
        video: _createVideoConstraints(),
        audio: false.toJS,
      );

      final navigator = web.window.navigator;
      final mediaDevices = navigator.mediaDevices;

      _mediaStream = await mediaDevices.getUserMedia(constraints).toDart;
      _videoElement!.srcObject = _mediaStream;

      // Wait for video to be ready
      await _videoElement!.play().toDart;

      // Register the video element view factory
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Start capture loop after video metadata loads
      _videoElement!.onLoadedMetadata.listen((_) {
        _startCaptureLoop();
      });

      // Also start immediately in case metadata already loaded
      if (_videoElement!.readyState >= 1) {
        _startCaptureLoop();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  JSObject _createVideoConstraints() {
    // Try to use back camera (environment facing)
    // On mobile, this is preferred for form review
    final jsObject = <String, dynamic>{
      'facingMode': {'ideal': 'environment'},
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
    }.jsify();
    return jsObject as JSObject;
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('notallowed') || errorStr.contains('permission')) {
      return 'Camera permission denied. Please allow camera access in your browser settings and reload.';
    } else if (errorStr.contains('notfound') || errorStr.contains('no device')) {
      return 'No camera found on this device.';
    } else if (errorStr.contains('notreadable') || errorStr.contains('in use')) {
      return 'Camera is in use by another app. Please close other apps using the camera.';
    } else if (errorStr.contains('overconstrained')) {
      return 'Camera does not support requested settings.';
    }
    return 'Failed to access camera: $error';
  }

  void _startCaptureLoop() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(
      const Duration(milliseconds: _captureIntervalMs),
      (_) => _captureFrame(),
    );
  }

  Future<void> _captureFrame() async {
    if (_videoElement == null ||
        _canvasElement == null ||
        _videoElement!.videoWidth == 0) {
      return;
    }

    try {
      final videoWidth = _videoElement!.videoWidth;
      final videoHeight = _videoElement!.videoHeight;

      _canvasElement!.width = videoWidth;
      _canvasElement!.height = videoHeight;

      final ctx = _canvasElement!.getContext('2d') as web.CanvasRenderingContext2D;

      // Mirror the image horizontally to match video display
      ctx.translate(videoWidth.toDouble(), 0);
      ctx.scale(-1, 1);
      ctx.drawImage(_videoElement!, 0, 0);
      ctx.resetTransform(); // Reset transform

      // Get image data as JPEG
      final dataUrl = _canvasElement!.toDataURL('image/jpeg', 0.8.toJS);
      final base64 = dataUrl.split(',').last;
      final bytes = base64Decode(base64);
      final now = DateTime.now().millisecondsSinceEpoch;

      _frameBuffer.add(TimestampedFrame(bytes: Uint8List.fromList(bytes), timestamp: now));

      final cutoff = now - ((_delaySeconds + 2) * 1000).toInt();
      while (_frameBuffer.isNotEmpty && _frameBuffer.first.timestamp < cutoff) {
        _frameBuffer.removeFirst();
      }

      final targetTime = now - (_delaySeconds * 1000).toInt();
      TimestampedFrame? frameToDisplay;

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

  Future<void> _downloadImage() async {
    if (_displayFrame == null) {
      _showSnackBar('No frame to save');
      return;
    }

    try {
      // Create blob and download link
      final blob = web.Blob(
        [_displayFrame!.toJS].toJS,
        web.BlobPropertyBag(type: 'image/jpeg'),
      );
      final url = web.URL.createObjectURL(blob);

      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = 'archery_shot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      anchor.click();

      web.URL.revokeObjectURL(url);

      _showSnackBar('Image downloaded');
    } catch (e) {
      _showSnackBar('Error saving: $e');
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
                child: const Text('Try Again'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tip: Make sure you allow camera access when prompted',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
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
              'Starting camera...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Allow camera access when prompted',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                        painter: ReferenceLinesPainter(
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
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontFamily: AppFonts.main,
                            fontWeight: FontWeight.bold,
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
            onPressed: _displayFrame == null ? null : _downloadImage,
            icon: const Icon(Icons.download),
            label: const Text('That was epic - Download it'),
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
      painter: GridPainter(),
      size: Size.infinite,
    );
  }
}
