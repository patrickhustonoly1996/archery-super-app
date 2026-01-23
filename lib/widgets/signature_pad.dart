import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';

/// Signature capture widget with save/load capability.
/// Signatures are stored as PNG byte data for persistence.
class SignaturePad extends StatefulWidget {
  final String label;
  final Uint8List? savedSignature;
  final ValueChanged<Uint8List?> onSignatureChanged;
  final double width;
  final double height;

  const SignaturePad({
    super.key,
    required this.label,
    this.savedSignature,
    required this.onSignatureChanged,
    this.width = 200,
    this.height = 80,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late SignatureController _controller;
  Uint8List? _currentSignature;

  @override
  void initState() {
    super.initState();
    _currentSignature = widget.savedSignature;
    _controller = SignatureController(
      penStrokeWidth: 2,
      penColor: AppColors.textPrimary,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _controller.clear();
    setState(() {
      _currentSignature = null;
    });
    widget.onSignatureChanged(null);
  }

  void _startEditing() {
    // Open full screen signature dialog for detailed signatures
    _showFullScreenSignature();
  }

  Future<void> _showFullScreenSignature() async {
    final result = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FullScreenSignatureDialog(
        label: widget.label,
        existingSignature: _currentSignature,
      ),
    );

    if (result != null) {
      setState(() {
        _currentSignature = result;
      });
      widget.onSignatureChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border.all(
              color: AppColors.surfaceLight,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildDisplayView(),
        ),
      ],
    );
  }

  Widget _buildDisplayView() {
    if (_currentSignature != null) {
      return Stack(
        children: [
          Center(
            child: Image.memory(
              _currentSignature!,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.edit,
                  onTap: _startEditing,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.delete_outline,
                  onTap: _clearSignature,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Empty state - tap to sign
    return GestureDetector(
      onTap: _startEditing,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.draw_outlined,
              color: AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to sign',
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Compact signature display for showing saved signatures in scorecards.
class SignatureDisplay extends StatelessWidget {
  final Uint8List? signature;
  final String label;
  final double width;
  final double height;

  const SignatureDisplay({
    super.key,
    this.signature,
    required this.label,
    this.width = 150,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.textMuted, width: 1),
            ),
          ),
          child: signature != null
              ? Image.memory(signature!, fit: BoxFit.contain)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

/// Full screen signature dialog for detailed signature capture.
class _FullScreenSignatureDialog extends StatefulWidget {
  final String label;
  final Uint8List? existingSignature;

  const _FullScreenSignatureDialog({
    required this.label,
    this.existingSignature,
  });

  @override
  State<_FullScreenSignatureDialog> createState() => _FullScreenSignatureDialogState();
}

class _FullScreenSignatureDialogState extends State<_FullScreenSignatureDialog> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.textPrimary,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isNotEmpty) {
      final signature = await _controller.toPngBytes();
      if (mounted) {
        Navigator.pop(context, signature);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 18,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.clear(),
                    tooltip: 'Clear',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),

            // Signature area - takes most of the screen
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border.all(color: AppColors.gold, width: 2),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.sm - 2),
                  child: Stack(
                    children: [
                      Signature(
                        controller: _controller,
                        backgroundColor: AppColors.surfaceDark,
                      ),
                      // Hint text when empty
                      if (_controller.isEmpty)
                        Center(
                          child: Text(
                            'Sign here',
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 24,
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Draw your signature using your finger or stylus',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
