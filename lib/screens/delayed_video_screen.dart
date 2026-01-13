import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';

class DelayedVideoScreen extends StatefulWidget {
  const DelayedVideoScreen({super.key});

  @override
  State<DelayedVideoScreen> createState() => _DelayedVideoScreenState();
}

class _DelayedVideoScreenState extends State<DelayedVideoScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Delay settings
  double _delaySeconds = 5.0;
  static const double _minDelay = 1.0;
  static const double _maxDelay = 10.0;

  // Frame buffer for delayed playback
  final Queue<_FrameData> _frameBuffer = Queue();
  Uint8List? _displayFrame;
  Timer? _captureTimer;
  Timer? _displayTimer;
  bool _isStreaming = false;

  // Target ~10 fps for reasonable quality vs memory tradeoff
  static const int _targetFps = 10;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available';
        });
        return;
      }

      // Prefer back camera for form review
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

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startStreaming();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Camera error: $e';
        });
      }
    }
  }

  void _startStreaming() {
    if (_isStreaming || _cameraController == null) return;
    _isStreaming = true;

    // Capture frames at target FPS
    final captureInterval = Duration(milliseconds: 1000 ~/ _targetFps);
    _captureTimer = Timer.periodic(captureInterval, (_) => _captureFrame());

    // Display frames at same rate
    _displayTimer = Timer.periodic(captureInterval, (_) => _displayDelayedFrame());
  }

  void _stopStreaming() {
    _captureTimer?.cancel();
    _displayTimer?.cancel();
    _captureTimer = null;
    _displayTimer = null;
    _isStreaming = false;
  }

  Future<void> _captureFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      final frameData = _FrameData(
        bytes: bytes,
        timestamp: DateTime.now(),
      );

      _frameBuffer.add(frameData);

      // Remove old frames beyond buffer window
      final bufferDuration = Duration(seconds: _maxDelay.toInt() + 1);
      final cutoff = DateTime.now().subtract(bufferDuration);
      while (_frameBuffer.isNotEmpty && _frameBuffer.first.timestamp.isBefore(cutoff)) {
        _frameBuffer.removeFirst();
      }
    } catch (e) {
      // Ignore capture errors (camera busy, etc.)
    }
  }

  void _displayDelayedFrame() {
    if (_frameBuffer.isEmpty) return;

    final targetTime = DateTime.now().subtract(
      Duration(milliseconds: (_delaySeconds * 1000).toInt()),
    );

    // Find the frame closest to our target time
    _FrameData? bestFrame;
    for (final frame in _frameBuffer) {
      if (frame.timestamp.isBefore(targetTime) || frame.timestamp.isAtSameMomentAs(targetTime)) {
        bestFrame = frame;
      } else {
        break;
      }
    }

    if (bestFrame != null && mounted) {
      setState(() {
        _displayFrame = bestFrame!.bytes;
      });
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _stopStreaming();

    final currentDirection = _cameraController?.description.lensDirection;
    final newCamera = _cameras!.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => _cameras!.first,
    );

    await _cameraController?.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        _startStreaming();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Camera switch failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _stopStreaming();
    _cameraController?.dispose();
    _frameBuffer.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'DELAYED VIDEO',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: AppColors.textMuted),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _hasError
          ? _buildErrorState()
          : !_isInitialized
              ? _buildLoadingState()
              : _buildVideoView(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'INITIALIZING',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: AppColors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'CAMERA UNAVAILABLE',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 10,
                color: AppColors.error,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    return Column(
      children: [
        // Delayed video display
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: ClipRect(
              child: _displayFrame != null
                  ? Image.memory(
                      _displayFrame!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    )
                  : Container(
                      color: AppColors.surfaceDark,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              color: AppColors.gold.withValues(alpha: 0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'BUFFERING...',
                              style: TextStyle(
                                fontFamily: AppFonts.pixel,
                                fontSize: 10,
                                color: AppColors.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video will appear in ${_delaySeconds.toInt()}s',
                              style: TextStyle(
                                fontFamily: AppFonts.mono,
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
        ),

        // Delay control panel
        _buildDelayControls(),
      ],
    );
  }

  Widget _buildDelayControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Current delay display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DELAY:',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 9,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    '${_delaySeconds.toInt()}s',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 14,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider
            Row(
              children: [
                Text(
                  '${_minDelay.toInt()}s',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: AppColors.surfaceLight,
                      thumbColor: AppColors.gold,
                      overlayColor: AppColors.gold.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _delaySeconds,
                      min: _minDelay,
                      max: _maxDelay,
                      divisions: (_maxDelay - _minDelay).toInt(),
                      onChanged: (value) {
                        setState(() {
                          _delaySeconds = value;
                        });
                      },
                    ),
                  ),
                ),
                Text(
                  '${_maxDelay.toInt()}s',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Set delay to review your form after each shot',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 10,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameData {
  final Uint8List bytes;
  final DateTime timestamp;

  _FrameData({required this.bytes, required this.timestamp});
}
