import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../db/database.dart';
import '../services/membership_card_service.dart';

class FederationFormScreen extends StatefulWidget {
  final Federation? federation;

  const FederationFormScreen({super.key, this.federation});

  @override
  State<FederationFormScreen> createState() => _FederationFormScreenState();
}

class _FederationFormScreenState extends State<FederationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _membershipNumberController = TextEditingController();
  final _cardService = MembershipCardService();
  final _picker = ImagePicker();

  DateTime? _expiryDate;
  bool _isPrimary = false;
  String? _cardImagePath;
  bool _isSaving = false;

  bool get isEditing => widget.federation != null;

  @override
  void initState() {
    super.initState();
    if (widget.federation != null) {
      _nameController.text = widget.federation!.federationName;
      _membershipNumberController.text = widget.federation!.membershipNumber ?? '';
      _expiryDate = widget.federation!.expiryDate;
      _isPrimary = widget.federation!.isPrimary;
      _cardImagePath = widget.federation!.cardImagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membershipNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickCardImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.gold),
              title: Text(
                'Take Photo',
                style: TextStyle(fontFamily: AppFonts.body),
              ),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.camera);
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
                _captureImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present, color: AppColors.gold),
              title: Text(
                'Select File (Wallet Pass)',
                style: TextStyle(fontFamily: AppFonts.body),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            if (_cardImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  'Remove Card Image',
                  style: TextStyle(fontFamily: AppFonts.body, color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _cardImagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final federationId = widget.federation?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
        final savedPath = await _cardService.saveCardFromFile(
          federationId: federationId,
          sourceFile: File(image.path),
        );
        setState(() => _cardImagePath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pkpass', 'png', 'jpg', 'jpeg', 'heic', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        final federationId = widget.federation?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
        final savedPath = await _cardService.saveCardFromFile(
          federationId: federationId,
          sourceFile: File(result.files.single.path!),
        );
        setState(() => _cardImagePath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveFederation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<UserProfileProvider>();
      final name = _nameController.text.trim();
      final membershipNumber = _membershipNumberController.text.trim();

      if (isEditing) {
        await provider.updateFederation(
          federationId: widget.federation!.id,
          federationName: name,
          membershipNumber: membershipNumber.isEmpty ? null : membershipNumber,
          cardImagePath: _cardImagePath,
          expiryDate: _expiryDate,
          isPrimary: _isPrimary,
        );
      } else {
        await provider.addFederation(
          federationName: name,
          membershipNumber: membershipNumber.isEmpty ? null : membershipNumber,
          cardImagePath: _cardImagePath,
          expiryDate: _expiryDate,
          isPrimary: _isPrimary,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteFederation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Delete Federation?',
          style: TextStyle(fontFamily: AppFonts.pixel, color: AppColors.textPrimary),
        ),
        content: Text(
          'This will remove ${widget.federation!.federationName} from your profile.',
          style: TextStyle(fontFamily: AppFonts.body, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(fontFamily: AppFonts.pixel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE',
              style: TextStyle(fontFamily: AppFonts.pixel, color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<UserProfileProvider>();
      await provider.deleteFederation(widget.federation!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'EDIT FEDERATION' : 'ADD FEDERATION',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _deleteFederation,
              icon: const Icon(Icons.delete, color: AppColors.error),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Federation name
            Text(
              'Federation Name',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: TextStyle(fontFamily: AppFonts.body),
              decoration: const InputDecoration(
                hintText: 'e.g., Archery GB, World Archery',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a federation name';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Membership number
            Text(
              'Membership Number',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _membershipNumberController,
              style: TextStyle(fontFamily: AppFonts.body),
              decoration: const InputDecoration(
                hintText: 'Your membership ID',
              ),
            ),

            const SizedBox(height: 24),

            // Expiry date
            Text(
              'Expiry Date',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectExpiryDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expiryDate != null
                          ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                          : 'Select expiry date',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        color: _expiryDate != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Primary checkbox
            GestureDetector(
              onTap: () => setState(() => _isPrimary = !_isPrimary),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isPrimary ? AppColors.gold.withValues(alpha: 0.2) : AppColors.surfaceLight,
                  border: Border.all(
                    color: _isPrimary ? AppColors.gold : AppColors.surfaceBright,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPrimary ? Icons.check_box : Icons.check_box_outline_blank,
                      color: _isPrimary ? AppColors.gold : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primary Federation',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Display this membership on your profile',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Membership card image
            Text(
              'Membership Card',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickCardImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border.all(
                    color: AppColors.surfaceBright,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _cardImagePath != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              File(_cardImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundDark.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.gold,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supports images and Apple Wallet passes (.pkpass)',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 40),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveFederation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundDark,
                      ),
                    )
                  : Text(
                      isEditing ? 'SAVE CHANGES' : 'ADD FEDERATION',
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo,
          color: AppColors.textMuted,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'Add card image or screenshot',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
