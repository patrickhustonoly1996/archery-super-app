import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';
import '../services/scan_motion_service.dart';
import '../services/scan_frame_service.dart';
import '../services/vision_api_service.dart';
import '../widgets/circular_sweep_guide.dart';
import 'auto_plot_confirm_screen.dart';
import 'auto_plot_upgrade_screen.dart';

/// Screen for circular scan-based Auto-Plot capture.
/// Uses a ritualistic circular motion to capture multiple frames
/// and composite the best data for arrow detection.
class AutoPlotScanScreen extends StatefulWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotScanScreen({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  State<AutoPlotScanScreen> createState() => _AutoPlotScanScreenState();
}

class _AutoPlotScanScreenState extends State<AutoPlotScanScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  String _cameraErrorMessage = '';

  // Motion tracking
  late ScanMotionService _motionService;

  // Frame capture
  final ScanFrameService _frameService = ScanFrameService();
  Timer? _frameCaptureTimer;

  // State
  bool _isScanning = false;
  bool _isScanComplete = false;
  bool _isProcessing = false;
  double _scanProgress = 0.0;
  bool _showSpeedWarning = false;
  bool _showStabilityWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use simulated motion service on web, real service on native
    _motionService = kIsWeb
        ? SimulatedScanMotionService()
        : ScanMotionService();

    _setupMotionCallbacks();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScanning();
    _cameraController?.dispose();
    _motionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Stop scanning first to prevent capture attempts on disposed camera
      if (_isScanning) {
        _stopScanning();
        _resetScan();
      }
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _setupMotionCallbacks() {
    _motionService.onProgressUpdate = (progress, velocity) {
      if (mounted) {
        setState(() {
          _scanProgress = progress;
        });
      }
    };

    _motionService.onSpeedWarning = (isTooFast) {
      if (mounted && _showSpeedWarning != isTooFast) {
        setState(() => _showSpeedWarning = isTooFast);
        if (isTooFast) {
          HapticFeedback.lightImpact();
        }
      }
    };

    _motionService.onStabilityWarning = (isUnstable) {
      if (mounted && _showStabilityWarning != isUnstable) {
        setState(() => _showStabilityWarning = isUnstable);
        if (isUnstable) {
          HapticFeedback.mediumImpact();
        }
      }
    };

    _motionService.onScanComplete = () {
      _onScanComplete();
    };
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      setState(() {
        _hasCameraError = true;
        _cameraErrorMessage = 'Camera scanning not supported on web.\nUse mobile app for best experience.';
      });
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _hasCameraError = true;
        _cameraErrorMessage = 'Camera permission required for scanning';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasCameraError = true;
          _cameraErrorMessage = 'No cameras available';
        });
        return;
      }

      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Set focus mode for consistent captures
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Focus mode may not be supported on all devices
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      setState(() {
        _hasCameraError = true;
        _cameraErrorMessage = 'Camera initialization failed: $e';
      });
    }
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

    // Haptic feedback to signal start
    HapticFeedback.heavyImpact();

    // Start motion tracking
    await _motionService.startTracking();

    // Start frame capture timer
    _frameCaptureTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (_) => _captureFrame(),
    );
  }

  void _stopScanning() {
    _frameCaptureTimer?.cancel();
    _frameCaptureTimer = null;
    _motionService.stopTracking();

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _captureFrame() async {
    if (!_isScanning || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Don't capture if there are warnings
    if (_showSpeedWarning || _showStabilityWarning) {
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();

      // Add frame with current rotation angle (async for smooth UI)
      await _frameService.addFrameAsync(bytes, _scanProgress * 2 * math.pi);

      if (mounted) {
        setState(() {}); // Trigger rebuild to show frame count
      }
    } catch (e) {
      debugPrint('Frame capture error: $e');
    }
  }

  void _onScanComplete() async {
    _stopScanning();

    // Haptic feedback for completion
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();

    setState(() {
      _isScanComplete = true;
    });

    // Auto-process after brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    _processComposite();
  }

  Future<void> _processComposite() async {
    if (_isProcessing) return;

    // Check if we have any frames to process
    if (_frameService.frameCount == 0) {
      _showError('No frames captured. Please try again with better lighting.');
      _resetScan();
      return;
    }

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
    if (provider.hasUnlimitedAutoPlot) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: AppColors.gold.withValues(alpha: 0.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              'PROFESSIONAL',
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
      color: isLow ? AppColors.error.withValues(alpha: 0.2) : AppColors.surfaceDark,
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
    if (_hasCameraError) {
      return _buildErrorView();
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
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
          child: ScanInstructionOverlay(
            isScanning: _isScanning,
            isComplete: _isScanComplete,
            progress: _scanProgress,
            framesCollected: _frameService.frameCount,
          ),
        ),

        // Warning overlays - stacked to avoid overlap
        if (_showSpeedWarning || _showStabilityWarning)
          Positioned(
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showSpeedWarning)
                  _buildWarning('TOO FAST', 'Slow down the rotation'),
                if (_showSpeedWarning && _showStabilityWarning)
                  const SizedBox(height: 8),
                if (_showStabilityWarning)
                  _buildWarning('UNSTABLE', 'Keep device steady'),
              ],
            ),
          ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: AppColors.background.withValues(alpha: 0.85),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _cameraErrorMessage,
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AutoPlotProvider provider) {
    final canStart = !_isScanning && !_isProcessing && provider.canScan && _isCameraInitialized;
    final canStop = _isScanning && !_isProcessing;

    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Target type indicator
            Text(
              'Target: ${widget.targetType}${widget.isTripleSpot ? ' (Triple)' : ''}',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // Motion hint
            if (!_isScanning && !_isProcessing)
              Text(
                'Move in a slow circle around the target',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            if (_isScanning)
              Text(
                'Tap to cancel scan',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: AppColors.error,
                ),
              ),
            const SizedBox(height: 16),
            // Scan button - can start OR stop
            GestureDetector(
              onTap: canStart
                  ? _startScanning
                  : canStop
                      ? () {
                          _stopScanning();
                          _resetScan();
                        }
                      : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (canStart || canStop) ? (_isScanning ? AppColors.error : AppColors.gold) : AppColors.textSecondary,
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
                      : const Icon(Icons.auto_awesome, color: AppColors.background, size: 32),
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
