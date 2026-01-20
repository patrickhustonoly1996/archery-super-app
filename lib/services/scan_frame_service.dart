import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Represents a captured frame during scanning
class ScanFrame {
  final Uint8List imageData;
  final double rotationAngle; // 0 to 2π
  final DateTime timestamp;
  final double qualityScore;

  ScanFrame({
    required this.imageData,
    required this.rotationAngle,
    required this.timestamp,
    required this.qualityScore,
  });
}

/// Manages frame capture, quality assessment, and composite generation
/// for the circular scan approach.
class ScanFrameService {
  // Captured frames organized by angular region
  final List<ScanFrame> _frames = [];

  // Configuration
  static const int kTargetFrameCount = 8; // Target frames for full rotation
  static const int kMaxFrames = 16; // Maximum frames to keep
  static const double kMinQualityScore = 0.3; // Minimum acceptable quality
  static const int kRegionCount = 8; // Divide circle into 8 regions

  // Callback for frame quality issues (allows UI to show warnings)
  Function(String reason)? onFrameDropped;

  // Track dropped frame statistics
  int _droppedFrameCount = 0;

  /// Get count of dropped frames in current scan
  int get droppedFrameCount => _droppedFrameCount;

  /// Add a captured frame
  /// Returns true if frame was accepted, false if dropped for quality
  /// Now async to run quality scoring in isolate for smooth UI
  Future<bool> addFrameAsync(Uint8List imageData, double rotationAngle) async {
    // Calculate quality score in isolate for performance
    final qualityScore = await compute(_quickQualityEstimateIsolate, imageData);

    if (qualityScore < kMinQualityScore) {
      // Skip low quality frames but notify caller
      _droppedFrameCount++;
      onFrameDropped?.call('Frame too blurry (quality: ${(qualityScore * 100).toInt()}%)');
      return false;
    }

    final frame = ScanFrame(
      imageData: imageData,
      rotationAngle: rotationAngle,
      timestamp: DateTime.now(),
      qualityScore: qualityScore,
    );

    _frames.add(frame);

    // If we have too many frames, remove the lowest quality from crowded regions
    if (_frames.length > kMaxFrames) {
      _pruneFrames();
    }

    return true;
  }

  /// Synchronous version for backwards compatibility (still blocks main thread)
  bool addFrame(Uint8List imageData, double rotationAngle) {
    final qualityScore = _quickQualityEstimate(imageData);

    if (qualityScore < kMinQualityScore) {
      _droppedFrameCount++;
      onFrameDropped?.call('Frame too blurry (quality: ${(qualityScore * 100).toInt()}%)');
      return false;
    }

    final frame = ScanFrame(
      imageData: imageData,
      rotationAngle: rotationAngle,
      timestamp: DateTime.now(),
      qualityScore: qualityScore,
    );

    _frames.add(frame);

    if (_frames.length > kMaxFrames) {
      _pruneFrames();
    }

    return true;
  }

  /// Quick quality estimate based on image variance (blur detection)
  double _quickQualityEstimate(Uint8List imageData) {
    try {
      // Decode a small version for speed
      final image = img.decodeJpg(imageData);
      if (image == null) return 0.0;

      // Resize for faster processing
      final small = img.copyResize(image, width: 100);

      // Convert to grayscale and calculate variance (higher = sharper)
      final grayscale = img.grayscale(small);

      double sum = 0;
      double sumSq = 0;
      int count = 0;

      for (int y = 0; y < grayscale.height; y++) {
        for (int x = 0; x < grayscale.width; x++) {
          final pixel = grayscale.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          sum += luminance;
          sumSq += luminance * luminance;
          count++;
        }
      }

      final mean = sum / count;
      final variance = (sumSq / count) - (mean * mean);

      // Normalize variance to 0-1 range (typical variance range is 0-2500)
      final normalizedVariance = math.min(1.0, variance / 2500);

      // Also check for overexposure (too many bright pixels)
      int brightPixels = 0;
      int darkPixels = 0;
      for (int y = 0; y < grayscale.height; y++) {
        for (int x = 0; x < grayscale.width; x++) {
          final pixel = grayscale.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          if (luminance > 240) brightPixels++;
          if (luminance < 15) darkPixels++;
        }
      }

      final brightRatio = brightPixels / count;
      final darkRatio = darkPixels / count;

      // Penalize overexposed or underexposed images
      double exposurePenalty = 1.0;
      if (brightRatio > 0.3) exposurePenalty *= (1.0 - brightRatio);
      if (darkRatio > 0.3) exposurePenalty *= (1.0 - darkRatio);

      return normalizedVariance * exposurePenalty;
    } catch (e) {
      debugPrint('Quality estimate error: $e');
      return 0.5; // Default to acceptable quality on error
    }
  }

  /// Remove lowest quality frames from crowded regions
  void _pruneFrames() {
    // Group frames by region
    final regions = List.generate(kRegionCount, (_) => <ScanFrame>[]);
    final regionSize = (2 * math.pi) / kRegionCount;

    for (final frame in _frames) {
      final regionIndex = (frame.rotationAngle / regionSize).floor() % kRegionCount;
      regions[regionIndex].add(frame);
    }

    // Find and remove lowest quality frame from most crowded region
    int maxCount = 0;
    int maxRegion = 0;
    for (int i = 0; i < regions.length; i++) {
      if (regions[i].length > maxCount) {
        maxCount = regions[i].length;
        maxRegion = i;
      }
    }

    if (regions[maxRegion].length > 1) {
      // Sort by quality and remove lowest
      regions[maxRegion].sort((a, b) => a.qualityScore.compareTo(b.qualityScore));
      final toRemove = regions[maxRegion].first;
      _frames.remove(toRemove);
    }
  }

  /// Get the number of captured frames
  int get frameCount => _frames.length;

  /// Get frames organized by region for display
  List<int> getFrameCountByRegion() {
    final counts = List.filled(kRegionCount, 0);
    final regionSize = (2 * math.pi) / kRegionCount;

    for (final frame in _frames) {
      final regionIndex = (frame.rotationAngle / regionSize).floor() % kRegionCount;
      counts[regionIndex]++;
    }

    return counts;
  }

  /// Check if we have sufficient coverage
  bool get hasSufficientCoverage {
    final regionCounts = getFrameCountByRegion();
    // Need at least 1 frame in 6 of 8 regions
    final coveredRegions = regionCounts.where((c) => c > 0).length;
    return coveredRegions >= 6;
  }

  /// Generate composite image from captured frames
  /// This selects the best regions from each frame to create an optimal composite
  Future<Uint8List> generateComposite() async {
    if (_frames.isEmpty) {
      throw StateError('No frames captured');
    }

    // If only one frame, return it directly
    if (_frames.length == 1) {
      return _frames.first.imageData;
    }

    // Run composite generation in isolate
    return compute(_generateCompositeIsolate, _frames);
  }

  /// Clear all captured frames
  void clear() {
    _frames.clear();
    _droppedFrameCount = 0;
  }

  /// Get all frames (for debugging/preview)
  List<ScanFrame> get frames => List.unmodifiable(_frames);
}

/// Isolate function for composite generation
/// Optimized to reduce memory pressure by limiting concurrent image decoding
Future<Uint8List> _generateCompositeIsolate(List<ScanFrame> frames) async {
  // Sort frames by quality
  final sortedFrames = List<ScanFrame>.from(frames)
    ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

  // Use the highest quality frame as the base
  final baseImage = img.decodeJpg(sortedFrames.first.imageData);
  if (baseImage == null) {
    throw StateError('Failed to decode base image');
  }

  // For simplicity, we'll use a region-based approach:
  // Divide the image into vertical strips and use the best frame for each region
  final regionCount = 8;
  final stripWidth = baseImage.width ~/ regionCount;

  // Create output image - start with base image content
  final composite = img.Image(
    width: baseImage.width,
    height: baseImage.height,
  );

  // Copy base image to composite first
  for (int y = 0; y < baseImage.height; y++) {
    for (int x = 0; x < baseImage.width; x++) {
      composite.setPixel(x, y, baseImage.getPixel(x, y));
    }
  }

  // Limit to top 4 frames to reduce memory pressure (was 8)
  // Process one region at a time, decoding only needed images
  final maxFramesToUse = math.min(4, sortedFrames.length);

  // Track which frame is best for each region
  final bestFrameForRegion = List<int>.filled(regionCount, 0);
  final bestQualityForRegion = List<double>.filled(regionCount, 0);

  // First pass: find best frame for each region using quick quality check
  // Decode one frame at a time to reduce peak memory
  for (int frameIdx = 0; frameIdx < maxFramesToUse; frameIdx++) {
    final frame = sortedFrames[frameIdx];
    final decoded = img.decodeJpg(frame.imageData);
    if (decoded == null) continue;

    // Resize if needed
    final image = (decoded.width != baseImage.width || decoded.height != baseImage.height)
        ? img.copyResize(decoded, width: baseImage.width, height: baseImage.height)
        : decoded;

    // Check each region's quality
    for (int region = 0; region < regionCount; region++) {
      final startX = region * stripWidth;
      final endX = (region == regionCount - 1) ? baseImage.width : (region + 1) * stripWidth;

      final localQuality = _calculateRegionQuality(image, startX, endX);
      if (localQuality > bestQualityForRegion[region]) {
        bestQualityForRegion[region] = localQuality;
        bestFrameForRegion[region] = frameIdx;
      }
    }

    // If this frame is best for any region, copy those regions now
    // This avoids needing to decode the frame again later
    for (int region = 0; region < regionCount; region++) {
      if (bestFrameForRegion[region] == frameIdx) {
        final startX = region * stripWidth;
        final endX = (region == regionCount - 1) ? baseImage.width : (region + 1) * stripWidth;

        for (int y = 0; y < composite.height; y++) {
          for (int x = startX; x < endX; x++) {
            composite.setPixel(x, y, image.getPixel(x, y));
          }
        }
      }
    }
    // Image goes out of scope here, allowing GC
  }

  // Apply slight blur at region boundaries to reduce seams
  for (int region = 1; region < regionCount; region++) {
    final boundaryX = region * stripWidth;
    _blendBoundary(composite, boundaryX, 4);
  }

  // Encode result
  return Uint8List.fromList(img.encodeJpg(composite, quality: 92));
}

/// Calculate quality score for a specific region of an image
double _calculateRegionQuality(img.Image image, int startX, int endX) {
  double sum = 0;
  double sumSq = 0;
  int count = 0;

  // Sample every 4th pixel for speed
  for (int y = 0; y < image.height; y += 4) {
    for (int x = startX; x < endX; x += 4) {
      final pixel = image.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      sum += luminance;
      sumSq += luminance * luminance;
      count++;
    }
  }

  if (count == 0) return 0;

  final mean = sum / count;
  final variance = (sumSq / count) - (mean * mean);

  return variance;
}

/// Blend pixels at region boundary to reduce visible seams
void _blendBoundary(img.Image image, int boundaryX, int blendWidth) {
  for (int y = 0; y < image.height; y++) {
    for (int dx = -blendWidth; dx <= blendWidth; dx++) {
      final x = boundaryX + dx;
      if (x < 0 || x >= image.width) continue;

      // Get neighboring pixels
      final leftX = math.max(0, x - 1);
      final rightX = math.min(image.width - 1, x + 1);

      final left = image.getPixel(leftX, y);
      final center = image.getPixel(x, y);
      final right = image.getPixel(rightX, y);

      // Simple 3-tap blur
      final blendedR = ((left.r + center.r * 2 + right.r) / 4).round();
      final blendedG = ((left.g + center.g * 2 + right.g) / 4).round();
      final blendedB = ((left.b + center.b * 2 + right.b) / 4).round();

      image.setPixelRgba(x, y, blendedR, blendedG, blendedB, 255);
    }
  }
}

/// Isolate function for quality estimation (runs off main thread)
double _quickQualityEstimateIsolate(Uint8List imageData) {
  try {
    // Decode a small version for speed
    final image = img.decodeJpg(imageData);
    if (image == null) return 0.0;

    // Resize for faster processing (smaller = faster in isolate)
    final small = img.copyResize(image, width: 64);

    // Convert to grayscale and calculate variance (higher = sharper)
    final grayscale = img.grayscale(small);

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        sum += luminance;
        sumSq += luminance * luminance;
        count++;
      }
    }

    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);

    // Normalize variance to 0-1 range (typical variance range is 0-2500)
    final normalizedVariance = math.min(1.0, variance / 2500);

    // Also check for overexposure (too many bright pixels)
    int brightPixels = 0;
    int darkPixels = 0;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        if (luminance > 240) brightPixels++;
        if (luminance < 15) darkPixels++;
      }
    }

    final brightRatio = brightPixels / count;
    final darkRatio = darkPixels / count;

    // Penalize overexposed or underexposed images
    double exposurePenalty = 1.0;
    if (brightRatio > 0.3) exposurePenalty *= (1.0 - brightRatio);
    if (darkRatio > 0.3) exposurePenalty *= (1.0 - darkRatio);

    return normalizedVariance * exposurePenalty;
  } catch (e) {
    return 0.5; // Default to acceptable quality on error
  }
}
