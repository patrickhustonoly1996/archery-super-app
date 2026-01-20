import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Converts camera image stream frames to various formats efficiently.
/// Designed for smooth video preview with minimal overhead.
class CameraStreamConverter {
  /// Convert CameraImage (YUV420/BGRA) to JPEG bytes.
  /// Runs in isolate for performance.
  static Future<Uint8List> toJpeg(CameraImage cameraImage, {int quality = 85}) async {
    return compute(_convertToJpeg, _ConvertParams(cameraImage, quality));
  }

  /// Convert CameraImage to img.Image for processing.
  /// Runs in isolate for performance.
  static Future<img.Image> toImage(CameraImage cameraImage) async {
    return compute(_convertToImage, cameraImage);
  }

  /// Check if image format is YUV420 (Android typical).
  static bool isYuv420(CameraImage image) {
    return image.format.group == ImageFormatGroup.yuv420;
  }

  /// Check if image format is BGRA (iOS typical).
  static bool isBgra(CameraImage image) {
    return image.format.group == ImageFormatGroup.bgra8888;
  }
}

class _ConvertParams {
  final CameraImage image;
  final int quality;
  _ConvertParams(this.image, this.quality);
}

/// Isolate function to convert camera image to JPEG
Uint8List _convertToJpeg(_ConvertParams params) {
  final image = _convertToImage(params.image);
  return Uint8List.fromList(img.encodeJpg(image, quality: params.quality));
}

/// Isolate function to convert camera image to img.Image
img.Image _convertToImage(CameraImage cameraImage) {
  if (cameraImage.format.group == ImageFormatGroup.yuv420) {
    return _convertYuv420ToImage(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    return _convertBgraToImage(cameraImage);
  } else {
    throw UnsupportedError('Unsupported image format: ${cameraImage.format.group}');
  }
}

/// Convert YUV420 (Android) to img.Image
img.Image _convertYuv420ToImage(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yRowStride = yPlane.bytesPerRow;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;

  final result = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final yIndex = y * yRowStride + x;
      final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

      final yValue = yBytes[yIndex];
      final uValue = uBytes[uvIndex];
      final vValue = vBytes[uvIndex];

      // YUV to RGB conversion
      final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
      final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
      final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

      result.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return result;
}

/// Convert BGRA8888 (iOS) to img.Image
img.Image _convertBgraToImage(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final bytes = image.planes[0].bytes;
  final bytesPerRow = image.planes[0].bytesPerRow;

  final result = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final index = y * bytesPerRow + x * 4;
      final b = bytes[index];
      final g = bytes[index + 1];
      final r = bytes[index + 2];
      // Alpha at index + 3, ignore for JPEG

      result.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return result;
}

/// A frame captured from the camera stream with timestamp.
class StreamFrame {
  final CameraImage raw;
  final int timestamp;

  StreamFrame({required this.raw, required this.timestamp});
}

/// Manages smooth camera preview with efficient frame buffering.
/// Provides both live preview and delayed capture capability.
class SmoothCameraBuffer {
  int _delayMs;
  final int captureIntervalMs;
  final int maxBufferSizeMs;

  final List<_BufferedFrame> _buffer = [];
  int _lastCaptureTime = 0;

  /// Callback when a delayed frame is available for display.
  void Function(Uint8List jpegBytes)? onDelayedFrame;

  /// Callback when a frame has been buffered.
  void Function(int bufferCount)? onFrameBuffered;

  SmoothCameraBuffer({
    int delayMs = 7000,
    this.captureIntervalMs = 100,
    this.maxBufferSizeMs = 22000,
  }) : _delayMs = delayMs;

  /// Current delay in milliseconds.
  int get delayMs => _delayMs;

  /// Process incoming camera frame.
  /// Captures at intervals for buffer, returns delayed frame when available.
  Future<void> processFrame(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Only buffer frames at specified interval to save memory/CPU
    if (now - _lastCaptureTime >= captureIntervalMs) {
      _lastCaptureTime = now;

      // Convert to JPEG in background isolate
      final jpeg = await CameraStreamConverter.toJpeg(image);

      _buffer.add(_BufferedFrame(bytes: jpeg, timestamp: now));

      // Prune old frames
      final cutoff = now - maxBufferSizeMs;
      _buffer.removeWhere((f) => f.timestamp < cutoff);

      onFrameBuffered?.call(_buffer.length);

      // Find and emit delayed frame
      final targetTime = now - delayMs;
      _BufferedFrame? delayedFrame;
      for (final f in _buffer) {
        if (f.timestamp <= targetTime) {
          delayedFrame = f;
        } else {
          break;
        }
      }

      if (delayedFrame != null) {
        onDelayedFrame?.call(delayedFrame.bytes);
      }
    }
  }

  /// Get all buffered frames (for video export).
  List<Uint8List> getFrames({int? startMs, int? endMs}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = startMs ?? 0;
    final end = endMs ?? now;

    return _buffer
        .where((f) => f.timestamp >= start && f.timestamp <= end)
        .map((f) => f.bytes)
        .toList();
  }

  /// Get frames from the delayed view window.
  List<Uint8List> getDelayedFrames({required int durationMs}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTime = now - delayMs;
    final startTime = endTime - durationMs;
    return getFrames(startMs: startTime, endMs: endTime);
  }

  /// Clear the buffer.
  void clear() {
    _buffer.clear();
    _lastCaptureTime = 0;
  }

  /// Current buffer size in frames.
  int get frameCount => _buffer.length;

  /// Update delay without clearing buffer.
  void setDelay(int delayMs) {
    _delayMs = delayMs;
  }
}

class _BufferedFrame {
  final Uint8List bytes;
  final int timestamp;
  _BufferedFrame({required this.bytes, required this.timestamp});
}
