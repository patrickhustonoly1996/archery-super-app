import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/auto_plot_provider.dart';

/// Screen to register clean target reference images for Auto-Plot
class TargetRegistrationScreen extends StatefulWidget {
  const TargetRegistrationScreen({super.key});

  @override
  State<TargetRegistrationScreen> createState() => _TargetRegistrationScreenState();
}

class _TargetRegistrationScreenState extends State<TargetRegistrationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCapturing = false;

  // Selected target type
  String _selectedTargetType = '40cm';
  bool _isTripleSpot = false;

  static const _targetTypes = [
    ('40cm', '40cm Indoor'),
    ('60cm', '60cm'),
    ('80cm', '80cm'),
    ('122cm', '122cm Outdoor'),
    ('triple_40cm', 'Triple Spot 40cm'),
  ];

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

    // Request camera permission
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

      // Use the back camera
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

  Future<void> _captureTarget() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();

      if (!mounted) return;

      // Register the target
      final provider = context.read<AutoPlotProvider>();
      await provider.registerTarget(
        targetType: _selectedTargetType,
        imageData: bytes,
        isTripleSpot: _isTripleSpot,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Target registered: $_selectedTargetType'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register target: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('REGISTER TARGET', style: AppFonts.pixel(size: 20)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Camera preview area
          Expanded(
            child: _buildCameraPreview(),
          ),
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
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
                style: AppFonts.body(color: AppColors.error),
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

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        CameraPreview(_cameraController!),
        // Target guide overlay
        _buildTargetGuideOverlay(),
        // Instructions
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Position a CLEAN target (no arrows) within the guide.',
              style: AppFonts.body(size: 14),
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
            border: Border.all(color: AppColors.gold, width: 2),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Center(
            child: Container(
              width: size * 0.1,
              height: size * 0.1,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 1),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Target type selector
            _buildTargetTypeSelector(),
            const SizedBox(height: 16),
            // Capture button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCapturing ? null : _captureTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCapturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.background,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('CAPTURE TARGET', style: AppFonts.pixel(size: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TARGET TYPE', style: AppFonts.pixel(size: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _targetTypes.map((type) {
            final isSelected = _selectedTargetType == type.$1;
            return ChoiceChip(
              label: Text(type.$2, style: AppFonts.body(size: 12)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTargetType = type.$1;
                    _isTripleSpot = type.$1 == 'triple_40cm';
                  });
                }
              },
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.background,
              labelStyle: AppFonts.body(
                size: 12,
                color: isSelected ? AppColors.background : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
