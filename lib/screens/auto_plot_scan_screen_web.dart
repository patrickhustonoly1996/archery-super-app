import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';
import '../services/scan_frame_service.dart';
import '../services/vision_api_service.dart';
import '../widgets/circular_sweep_guide.dart';
import 'auto_plot_confirm_screen.dart';
import 'auto_plot_upgrade_screen.dart';

/// Web implementation of Auto-Plot scanning.
/// Uses browser getUserMedia API since Flutter camera package has limited web support.
/// Motion is simulated via timed auto-capture since browsers don't have gyroscope access.
class AutoPlotScanScreenWeb extends StatefulWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotScanScreenWeb({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  State<AutoPlotScanScreenWeb> createState() => _AutoPlotScanScreenWebState();
}

class _AutoPlotScanScreenWebState extends State<AutoPlotScanScreenWeb> {
  static int _viewIdCounter = 0;
  late final String _viewId;

  web.HTMLVideoElement? _videoElement;
  web.HTMLCanvasElement? _canvasElement;
  web.MediaStream? _mediaStream;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Scan state
  bool _isScanning = false;
  bool _isScanComplete = false;
  bool _isProcessing = false;
  double _scanProgress = 0.0;

  // Frame capture
  final ScanFrameService _frameService = ScanFrameService();
  Timer? _scanTimer;
  static const Duration _scanDuration = Duration(seconds: 3);
  static const Duration _frameInterval = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _viewId = 'auto-plot-scan-video-${_viewIdCounter++}';
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopScanning();
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
      _videoElement!.setAttribute('playsinline', 'true');

      // Create canvas for frame capture
      _canvasElement = web.document.createElement('canvas') as web.HTMLCanvasElement;

      // Request camera access - prefer back camera for target scanning
      final constraints = web.MediaStreamConstraints(
        video: _createVideoConstraints(),
        audio: false.toJS,
      );

      final navigator = web.window.navigator;
      final mediaDevices = navigator.mediaDevices;

      _mediaStream = await mediaDevices.getUserMedia(constraints).toDart;
      _videoElement!.srcObject = _mediaStream;

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
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  JSObject _createVideoConstraints() {
    // Prefer back (environment) camera for scanning targets
    final jsObject = <String, dynamic>{
      'facingMode': {'ideal': 'environment'},
      'width': {'ideal': 1920},
      'height': {'ideal': 1080},
    }.jsify();
    return jsObject as JSObject;
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('notallowed') || errorStr.contains('permission')) {
      return 'Camera permission denied.\nAllow camera access in browser settings and reload.';
    } else if (errorStr.contains('notfound') || errorStr.contains('no device')) {
      return 'No camera found on this device.';
    } else if (errorStr.contains('notreadable') || errorStr.contains('in use')) {
      return 'Camera is in use by another app.';
    }
    return 'Failed to access camera: $error';
  }

  void _startScanning() async {
    if (_isScanning || _isProcessing) return;

    final provider = context.read<AutoPlotProvider>();
    if (!provider.canScan) {
      _showUpgradePrompt();
      return;
    }

    setState(() {
      _isScanning = true;
      _isScanComplete = false;
      _scanProgress = 0.0;
    });

    _frameService.clear();

    // On web, we do a timed auto-scan since there's no gyroscope
    // User just needs to hold the phone pointed at target
    final startTime = DateTime.now();
    final totalMs = _scanDuration.inMilliseconds;

    _scanTimer = Timer.periodic(_frameInterval, (timer) async {
      if (!_isScanning) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / totalMs).clamp(0.0, 1.0);

      // Capture frame
      await _captureFrame(progress);

      setState(() {
        _scanProgress = progress;
      });

      if (progress >= 1.0) {
        timer.cancel();
        _onScanComplete();
      }
    });
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _captureFrame(double progress) async {
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
      ctx.drawImage(_videoElement!, 0, 0);

      // Get image data as JPEG
      final dataUrl = _canvasElement!.toDataURL('image/jpeg', 0.85.toJS);
      final base64 = dataUrl.split(',').last;
      final bytes = Uint8List.fromList(base64Decode(base64));

      // Add frame with simulated rotation angle based on progress
      final angle = progress * 2 * 3.14159;
      _frameService.addFrame(bytes, angle);
    } catch (e) {
      debugPrint('Frame capture error: $e');
    }
  }

  void _onScanComplete() async {
    _stopScanning();

    setState(() {
      _isScanComplete = true;
    });

    // Auto-process after brief delay
    await Future.delayed(const Duration(milliseconds: 300));
    _processComposite();
  }

  Future<void> _processComposite() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate composite image
      final compositeImage = await _frameService.generateComposite();

      if (!mounted) return;

      // Process through Auto-Plot provider
      final provider = context.read<AutoPlotProvider>();
      await provider.processImage(compositeImage);

      if (!mounted) return;

      if (provider.state == AutoPlotState.confirming) {
        // Navigate to confirmation
        final result = await Navigator.of(context).push<List<DetectedArrow>>(
          MaterialPageRoute(
            builder: (_) => AutoPlotConfirmScreen(
              targetType: widget.targetType,
              isTripleSpot: widget.isTripleSpot,
            ),
          ),
        );

        if (result != null && mounted) {
          Navigator.of(context).pop(result);
        } else if (mounted) {
          _resetScan();
        }
      } else if (provider.state == AutoPlotState.error) {
        _showError(provider.errorMessage ?? 'Detection failed');
        _resetScan();
      }
    } catch (e) {
      _showError('Processing failed: $e');
      _resetScan();
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = false;
      _isScanComplete = false;
      _isProcessing = false;
      _scanProgress = 0.0;
    });
    _frameService.clear();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'RETRY',
          textColor: AppColors.textPrimary,
          onPressed: _resetScan,
        ),
      ),
    );
  }

  void _showUpgradePrompt() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AutoPlotUpgradeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'SCAN TARGET',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            context.read<AutoPlotProvider>().reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Consumer<AutoPlotProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildUsageIndicator(provider),
              Expanded(child: _buildScanArea()),
              _buildControls(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsageIndicator(AutoPlotProvider provider) {
    if (provider.tier == AutoPlotTier.pro) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: AppColors.gold.withOpacity(0.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              'AUTO-PLOT PRO',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 12,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      );
    }

    final remaining = provider.scansRemaining;
    final isLow = remaining <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isLow ? AppColors.error.withOpacity(0.2) : AppColors.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$remaining scans remaining this month',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: isLow ? AppColors.error : AppColors.textSecondary,
            ),
          ),
          if (isLow) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _showUpgradePrompt,
              child: Text(
                'UPGRADE',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanArea() {
    if (_hasError) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 16),
            Text(
              'Starting camera...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Allow camera access when prompted',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        Positioned.fill(
          child: HtmlElementView(viewType: _viewId),
        ),

        // Circular sweep guide overlay
        CircularSweepGuide(
          progress: _scanProgress,
          isScanning: _isScanning,
          isComplete: _isScanComplete,
        ),

        // Instruction overlay
        Positioned(
          top: 16,
          child: _buildInstructionOverlay(),
        ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: AppColors.background.withOpacity(0.85),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 24),
                Text(
                  'ANALYZING...',
                  style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Processing ${_frameService.frameCount} frames',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionOverlay() {
    String instruction;
    if (_isScanComplete) {
      instruction = 'SCAN COMPLETE';
    } else if (_isScanning) {
      instruction = 'Hold steady...';
    } else {
      instruction = 'TAP TO START SCAN';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            instruction,
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 16,
              color: _isScanComplete ? AppColors.gold : AppColors.textPrimary,
            ),
          ),
        ),
        if (_isScanning) ...[
          const SizedBox(height: 8),
          Text(
            '${(_scanProgress * 100).toInt()}% · ${_frameService.frameCount} frames',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (!_isScanning && !_isScanComplete) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Point at target and hold steady for 3 seconds',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }

  Widget _buildControls(AutoPlotProvider provider) {
    final canStart = !_isScanning && !_isProcessing && provider.canScan && _isInitialized;

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Target: ${widget.targetType}${widget.isTripleSpot ? ' (Triple)' : ''}',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: canStart ? _startScanning : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: canStart ? AppColors.gold : AppColors.textSecondary,
                    width: 4,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isScanning
                        ? AppColors.error
                        : (canStart ? AppColors.gold : AppColors.textSecondary),
                  ),
                  child: _isScanning
                      ? const Icon(Icons.stop, color: AppColors.background, size: 32)
                      : const Icon(Icons.radar, color: AppColors.background, size: 32),
                ),
              ),
            ),
            if (!provider.canScan) ...[
              const SizedBox(height: 16),
              Text(
                'Monthly limit reached',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
