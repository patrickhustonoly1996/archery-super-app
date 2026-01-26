import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/equipment_photo_service.dart';

/// A small camera icon button that sits beside form fields
/// Shows gold when photo exists, muted when empty
class PhotoHintButton extends StatefulWidget {
  final String? photoPath;
  final String bowId;
  final String fieldName;
  final String label;
  final ValueChanged<String?> onPhotoChanged;

  const PhotoHintButton({
    super.key,
    required this.photoPath,
    required this.bowId,
    required this.fieldName,
    required this.label,
    required this.onPhotoChanged,
  });

  @override
  State<PhotoHintButton> createState() => _PhotoHintButtonState();
}

class _PhotoHintButtonState extends State<PhotoHintButton> {
  final _picker = ImagePicker();
  final _photoService = EquipmentPhotoService();
  bool _isLoading = false;

  bool get _hasPhoto => widget.photoPath != null && widget.photoPath!.isNotEmpty;

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
                '${widget.label} Photo',
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
            if (_hasPhoto) ...[
              ListTile(
                leading: const Icon(Icons.fullscreen, color: AppColors.textSecondary),
                title: Text(
                  'View Photo',
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
        if (_hasPhoto) {
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
    if (_hasPhoto) {
      await _photoService.deletePhoto(widget.photoPath);
      widget.onPhotoChanged(null);
    }
  }

  void _viewFullSize() {
    if (!_hasPhoto) return;

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
    return GestureDetector(
      onTap: _isLoading ? null : _showOptions,
      onLongPress: _hasPhoto ? _viewFullSize : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hasPhoto
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: Border.all(
            color: _hasPhoto ? AppColors.gold : AppColors.surfaceBright,
            width: _hasPhoto ? 1.5 : 1,
          ),
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              )
            : Icon(
                _hasPhoto ? Icons.camera_alt : Icons.camera_alt_outlined,
                size: 18,
                color: _hasPhoto ? AppColors.gold : AppColors.textMuted,
              ),
      ),
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
