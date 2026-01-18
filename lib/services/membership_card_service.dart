import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for saving and managing membership card images
/// Supports both regular images (PNG, JPG) and Apple Wallet passes (.pkpass)
class MembershipCardService {
  static const String _cardFolder = 'membership_cards';

  /// Get the directory for storing membership cards
  Future<Directory> _getCardDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cardDir = Directory(path.join(appDir.path, _cardFolder));
    if (!await cardDir.exists()) {
      await cardDir.create(recursive: true);
    }
    return cardDir;
  }

  /// Save a membership card image from bytes
  /// Returns the local file path
  Future<String> saveCardImage({
    required String federationId,
    required Uint8List imageBytes,
    required String originalFileName,
  }) async {
    try {
      final cardDir = await _getCardDirectory();
      final extension = path.extension(originalFileName).toLowerCase();

      // Sanitize filename
      final sanitizedName = federationId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final fileName = '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = path.join(cardDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      debugPrint('Error saving card image: $e');
      rethrow;
    }
  }

  /// Save a membership card from a file (e.g., from image picker or file picker)
  Future<String> saveCardFromFile({
    required String federationId,
    required File sourceFile,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final fileName = path.basename(sourceFile.path);
      return saveCardImage(
        federationId: federationId,
        imageBytes: bytes,
        originalFileName: fileName,
      );
    } catch (e) {
      debugPrint('Error saving card from file: $e');
      rethrow;
    }
  }

  /// Delete a membership card image
  Future<void> deleteCardImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting card image: $e');
    }
  }

  /// Check if a file is a valid card format
  static bool isValidCardFormat(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.pkpass', '.heic', '.webp'].contains(extension);
  }

  /// Check if a file is an Apple Wallet pass
  static bool isWalletPass(String fileName) {
    return path.extension(fileName).toLowerCase() == '.pkpass';
  }

  /// Get all saved card images for debugging
  Future<List<File>> getAllCards() async {
    try {
      final cardDir = await _getCardDirectory();
      final files = await cardDir.list().where((e) => e is File).cast<File>().toList();
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Clear all stored card images (for debugging/testing)
  Future<void> clearAllCards() async {
    try {
      final cardDir = await _getCardDirectory();
      if (await cardDir.exists()) {
        await cardDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing cards: $e');
    }
  }

  /// Get the file size of a card image
  Future<int> getCardFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
