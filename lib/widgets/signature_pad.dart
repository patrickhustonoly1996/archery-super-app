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
  bool _isEditing = false;
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

  Future<void> _saveSignature() async {
    if (_controller.isNotEmpty) {
      final signature = await _controller.toPngBytes();
      setState(() {
        _currentSignature = signature;
        _isEditing = false;
      });
      widget.onSignatureChanged(signature);
    } else {
      setState(() => _isEditing = false);
    }
  }

  void _clearSignature() {
    _controller.clear();
    setState(() {
      _currentSignature = null;
    });
    widget.onSignatureChanged(null);
  }

  void _startEditing() {
    _controller.clear();
    setState(() => _isEditing = true);
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
              color: _isEditing ? AppColors.gold : AppColors.surfaceLight,
              width: _isEditing ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _isEditing
              ? _buildEditingView()
              : _buildDisplayView(),
        ),
      ],
    );
  }

  Widget _buildEditingView() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Signature(
            controller: _controller,
            backgroundColor: AppColors.surfaceDark,
          ),
        ),
        // Action buttons
        Positioned(
          right: 4,
          bottom: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.close,
                onTap: () => setState(() => _isEditing = false),
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.refresh,
                onTap: () => _controller.clear(),
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.check,
                onTap: _saveSignature,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
        // Hint text
        if (_controller.isEmpty)
          Center(
            child: Text(
              'Sign here',
              style: TextStyle(
                fontFamily: AppFonts.body,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
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
