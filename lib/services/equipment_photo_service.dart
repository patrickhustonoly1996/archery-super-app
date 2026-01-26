import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for saving and managing equipment tuning photos
class EquipmentPhotoService {
  static const String _photoFolder = 'equipment_photos';

  /// Get the directory for storing equipment photos
  Future<Directory> _getPhotoDirectory(String bowId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, _photoFolder, bowId));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  /// Save an equipment photo from a file (e.g., from image picker)
  /// [bowId] - The ID of the bow this photo belongs to
  /// [fieldName] - The field name (e.g., 'buttonPosition', 'centreShot')
  /// [sourceFile] - The source file to save
  /// Returns the local file path
  Future<String> savePhoto({
    required String bowId,
    required String fieldName,
    required File sourceFile,
  }) async {
    try {
      final photoDir = await _getPhotoDirectory(bowId);
      final extension = path.extension(sourceFile.path).toLowerCase();

      // Create filename with timestamp to avoid conflicts
      final fileName = '${fieldName}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = path.join(photoDir.path, fileName);

      // Read and write to new location
      final bytes = await sourceFile.readAsBytes();
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('Error saving equipment photo: $e');
      rethrow;
    }
  }

  /// Delete an equipment photo
  Future<void> deletePhoto(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting equipment photo: $e');
    }
  }

  /// Delete all photos for a bow
  Future<void> deleteAllPhotosForBow(String bowId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(path.join(appDir.path, _photoFolder, bowId));
      if (await photoDir.exists()) {
        await photoDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting bow photos: $e');
    }
  }

  /// Check if a photo file exists
  Future<bool> photoExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    return File(filePath).exists();
  }
}
