import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';
import '../services/vision_api_service.dart';
import 'auto_plot_confirm_screen.dart';
import 'auto_plot_upgrade_screen.dart';

/// Screen to capture target image for Auto-Plot arrow detection
class AutoPlotCaptureScreen extends StatefulWidget {
  final String targetType;
  final bool isTripleSpot;

  const AutoPlotCaptureScreen({
    super.key,
    required this.targetType,
    this.isTripleSpot = false,
  });

  @override
  State<AutoPlotCaptureScreen> createState() => _AutoPlotCaptureScreenState();
}

class _AutoPlotCaptureScreenState extends State<AutoPlotCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Camera not supported on web';
      });
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Camera permission denied';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available';
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
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final provider = context.read<AutoPlotProvider>();
    if (provider.state == AutoPlotState.processing) return;

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();

      if (!mounted) return;

      // Process the image
      await provider.processImage(bytes);

      if (!mounted) return;

      if (provider.state == AutoPlotState.confirming) {
        // Navigate to confirmation screen
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
        }
      } else if (provider.state == AutoPlotState.error) {
        _showError(provider.errorMessage ?? 'Detection failed');
      }
    } catch (e) {
      _showError('Failed to capture: $e');
    }
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
          onPressed: () {
            context.read<AutoPlotProvider>().retryCapture();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'AUTO-PLOT',
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
              // Usage indicator
              _buildUsageIndicator(provider),
              // Camera preview
              Expanded(child: _buildCameraPreview(provider)),
              // Controls
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AutoPlotUpgradeScreen(),
                  ),
                );
              },
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

  Widget _buildCameraPreview(AutoPlotProvider provider) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
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

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (provider.state == AutoPlotState.processing) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_cameraController!),
          Container(
            color: AppColors.background.withValues(alpha: 0.8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 24),
                Text(
                  'Detecting arrows...',
                  style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(_cameraController!),
        _buildTargetGuideOverlay(),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Point camera at target with arrows. Keep steady.',
              style: TextStyle(fontFamily: AppFonts.body, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetGuideOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.8;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(size / 2),
          ),
        );
      },
    );
  }

  Widget _buildControls(AutoPlotProvider provider) {
    final isProcessing = provider.state == AutoPlotState.processing;
    final canCapture = !isProcessing && provider.canScan;

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
            const SizedBox(height: 16),
            // Capture button
            GestureDetector(
              onTap: canCapture ? _captureAndProcess : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: canCapture ? AppColors.gold : AppColors.textSecondary,
                    width: 4,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canCapture ? AppColors.gold : AppColors.textSecondary,
                  ),
                  child: isProcessing
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: AppColors.background,
                          size: 32,
                        ),
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
