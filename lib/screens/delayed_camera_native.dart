import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';
import '../utils/camera_stream_converter.dart';
import 'delayed_camera_screen.dart';

/// Entry point for platform-specific implementation
Widget buildDelayedCameraScreen(BuildContext context) {
  return const _NativeCameraScreen();
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
  final Queue<TimestampedFrame> _frameBuffer = Queue();
  Uint8List? _displayFrame;

  // Stream-based capture for smooth video (30fps target)
  bool _isStreaming = false;
  int _lastFrameTime = 0;
  static const int _captureIntervalMs = 33; // ~30fps for smooth playback
  bool _isProcessingFrame = false; // Prevent frame pile-up

  // Saving state
  bool _isSaving = false;
  bool _showSavedMessage = false;

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
    _stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _startImageStream();
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

      // Prefer front (selfie) camera
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
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

      _startImageStream();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _startImageStream() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isStreaming) {
      return;
    }

    try {
      await _cameraController!.startImageStream(_onImageAvailable);
      _isStreaming = true;
    } catch (e) {
      // Fall back to timer-based capture if streaming not supported
      debugPrint('Image stream not available, falling back to timer: $e');
      _startFallbackCapture();
    }
  }

  void _stopImageStream() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        _isStreaming) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }
  }

  void _onImageAvailable(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Throttle to target frame rate and prevent pile-up
    if (now - _lastFrameTime < _captureIntervalMs || _isProcessingFrame) {
      return;
    }
    _lastFrameTime = now;
    _isProcessingFrame = true;

    try {
      // Convert to JPEG in isolate (non-blocking)
      final bytes = await CameraStreamConverter.toJpeg(image);

      if (!mounted) {
        _isProcessingFrame = false;
        return;
      }

      _frameBuffer.add(TimestampedFrame(bytes: bytes, timestamp: now));

      // Keep 22 seconds of frames for 20s video export
      const videoBufferSeconds = 22.0;
      final bufferSeconds = videoBufferSeconds > (_delaySeconds + 2)
          ? videoBufferSeconds
          : (_delaySeconds + 2);
      final cutoff = now - (bufferSeconds * 1000).toInt();
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
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // Fallback for devices that don't support image streaming
  void _startFallbackCapture() {
    Timer.periodic(
      const Duration(milliseconds: 100), // 10fps fallback
      (_) => _captureFallbackFrame(),
    );
  }

  Future<void> _captureFallbackFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final now = DateTime.now().millisecondsSinceEpoch;

      _frameBuffer.add(TimestampedFrame(bytes: bytes, timestamp: now));

      const videoBufferSeconds = 22.0;
      final bufferSeconds = videoBufferSeconds > (_delaySeconds + 2)
          ? videoBufferSeconds
          : (_delaySeconds + 2);
      final cutoff = now - (bufferSeconds * 1000).toInt();
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

  Future<void> _saveEpicShot() async {
    // Get frames from the last 20 seconds (delayed by current delay setting)
    final now = DateTime.now().millisecondsSinceEpoch;
    final delayMs = (_delaySeconds * 1000).toInt();
    const videoDurationMs = 20000; // 20 seconds of video

    // We want frames from (now - delay - 20s) to (now - delay)
    final endTime = now - delayMs;
    final startTime = endTime - videoDurationMs;

    final framesToEncode = _frameBuffer
        .where((f) => f.timestamp >= startTime && f.timestamp <= endTime)
        .toList();

    if (framesToEncode.length < 10) {
      _showSnackBar('Not enough footage yet - keep recording');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final framesDir = Directory('${tempDir.path}/frames_$timestamp');
      await framesDir.create(recursive: true);

      // Write frames to temp files
      for (int i = 0; i < framesToEncode.length; i++) {
        final frameFile = File('${framesDir.path}/frame_${i.toString().padLeft(5, '0')}.jpg');
        await frameFile.writeAsBytes(framesToEncode[i].bytes);
      }

      // Calculate actual FPS from captured frames
      final actualDurationMs =
          framesToEncode.last.timestamp - framesToEncode.first.timestamp;
      final fps = actualDurationMs > 0
          ? (framesToEncode.length * 1000 / actualDurationMs).clamp(5.0, 30.0)
          : 10.0;

      final outputPath = '${tempDir.path}/archery_shot_$timestamp.mp4';

      // Encode frames to video using FFmpeg
      final ffmpegCommand =
          '-framerate $fps -i ${framesDir.path}/frame_%05d.jpg -c:v mpeg4 -q:v 5 -pix_fmt yuv420p $outputPath';

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Save video to gallery
        final result = await ImageGallerySaverPlus.saveFile(outputPath);

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
          _showSnackBar('Failed to save to Photos');
        }
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('FFmpeg failed: $logs');
        _showSnackBar('Video encoding failed');
      }

      // Cleanup temp files
      try {
        await framesDir.delete(recursive: true);
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      } catch (_) {}
    } catch (e) {
      _showSnackBar('Error saving video: $e');
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
                            color: _selectedColor.withValues(alpha: 0.8),
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
                            color: AppColors.success.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Video Saved to Photos',
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
                  overlayColor: AppColors.gold.withValues(alpha: 0.2),
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
                : const Icon(Icons.videocam),
            label: const Text('Save last 20s to Photos'),
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
                                    color: color.withValues(alpha: 0.5),
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
