import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/equipment_photo_service.dart';

/// A reusable photo capture field for equipment tuning positions
class EquipmentPhotoField extends StatefulWidget {
  final String label;
  final String? photoPath;
  final String bowId;
  final String fieldName;
  final ValueChanged<String?> onPhotoChanged;
  final String? helperText;

  const EquipmentPhotoField({
    super.key,
    required this.label,
    required this.photoPath,
    required this.bowId,
    required this.fieldName,
    required this.onPhotoChanged,
    this.helperText,
  });

  @override
  State<EquipmentPhotoField> createState() => _EquipmentPhotoFieldState();
}

class _EquipmentPhotoFieldState extends State<EquipmentPhotoField> {
  final _picker = ImagePicker();
  final _photoService = EquipmentPhotoService();
  bool _isLoading = false;

  Future<void> _showOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.gold),
              title: Text(
                'Take Photo',
                style: TextStyle(fontFamily: AppFonts.body),
              ),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gold),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(fontFamily: AppFonts.body),
              ),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto(ImageSource.gallery);
              },
            ),
            if (widget.photoPath != null) ...[
              ListTile(
                leading: const Icon(Icons.fullscreen, color: AppColors.textSecondary),
                title: Text(
                  'View Full Size',
                  style: TextStyle(fontFamily: AppFonts.body),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewFullSize();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(fontFamily: AppFonts.body, color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto(ImageSource source) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        // Delete old photo if exists
        if (widget.photoPath != null) {
          await _photoService.deletePhoto(widget.photoPath);
        }

        // Save new photo
        final savedPath = await _photoService.savePhoto(
          bowId: widget.bowId,
          fieldName: widget.fieldName,
          sourceFile: File(image.path),
        );

        widget.onPhotoChanged(savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    if (widget.photoPath != null) {
      await _photoService.deletePhoto(widget.photoPath);
      widget.onPhotoChanged(null);
    }
  }

  void _viewFullSize() {
    if (widget.photoPath == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenPhotoView(
          photoPath: widget.photoPath!,
          label: widget.label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: _isLoading ? null : _showOptions,
          onLongPress: widget.photoPath != null ? _viewFullSize : null,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border.all(
                color: widget.photoPath != null
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : AppColors.surfaceBright,
                width: widget.photoPath != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    ),
                  )
                : widget.photoPath != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.sm - 1),
                            child: Image.file(
                              File(widget.photoPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => _buildPlaceholder(),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundDark.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.gold,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildPlaceholder(),
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo,
          color: AppColors.textMuted,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add photo',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Full screen photo viewer
class _FullScreenPhotoView extends StatelessWidget {
  final String photoPath;
  final String label;

  const _FullScreenPhotoView({
    required this.photoPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          label,
          style: TextStyle(fontFamily: AppFonts.pixel),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(photoPath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Center(
              child: Text(
                'Unable to load image',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
