import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:archery_super_app/services/scan_frame_service.dart';

void main() {
  group('ScanFrameService', () {
    late ScanFrameService service;

    setUp(() {
      service = ScanFrameService();
    });

    tearDown(() {
      service.clear();
    });

    Uint8List createTestImage({
      int width = 100,
      int height = 100,
      int variance = 100,
    }) {
      // Create a simple test image with controllable variance
      final image = img.Image(width: width, height: height);

      // Fill with varying pixel values based on variance parameter
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Create some variation for blur detection
          final value = ((x + y) * variance ~/ 100) % 256;
          image.setPixelRgba(x, y, value, value, value, 255);
        }
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 85));
    }

    test('starts with zero frames', () {
      expect(service.frameCount, equals(0));
      expect(service.hasSufficientCoverage, isFalse);
    });

    test('adds frames with rotation angle', () {
      final imageData = createTestImage(variance: 80);

      service.addFrame(imageData, 0.0);
      expect(service.frameCount, equals(1));

      service.addFrame(imageData, 1.57);
      expect(service.frameCount, equals(2));
    });

    test('tracks frames by region', () {
      final imageData = createTestImage(variance: 80);

      // Add frames at different angles (8 regions, each π/4 radians)
      service.addFrame(imageData, 0.0); // Region 0
      service.addFrame(imageData, 0.8); // Region 1
      service.addFrame(imageData, 1.6); // Region 2
      service.addFrame(imageData, 2.4); // Region 3
      service.addFrame(imageData, 3.2); // Region 4
      service.addFrame(imageData, 4.0); // Region 5

      final regionCounts = service.getFrameCountByRegion();
      expect(regionCounts.where((c) => c > 0).length, greaterThanOrEqualTo(6));
    });

    test('reports sufficient coverage when 6+ regions have frames', () {
      final imageData = createTestImage(variance: 80);

      // Add frames covering at least 6 regions
      for (double angle = 0.0; angle < 5.0; angle += 0.8) {
        service.addFrame(imageData, angle);
      }

      expect(service.hasSufficientCoverage, isTrue);
    });

    test('clear removes all frames', () {
      final imageData = createTestImage(variance: 80);

      service.addFrame(imageData, 0.0);
      service.addFrame(imageData, 1.57);
      expect(service.frameCount, equals(2));

      service.clear();
      expect(service.frameCount, equals(0));
    });

    test('prunes frames when exceeding max', () {
      final imageData = createTestImage(variance: 80);

      // Add more than max frames
      for (int i = 0; i < 20; i++) {
        service.addFrame(imageData, i * 0.3);
      }

      // Should be pruned to max (16)
      expect(service.frameCount, lessThanOrEqualTo(ScanFrameService.kMaxFrames));
    });

    test('generateComposite throws when no frames', () async {
      expect(
        () => service.generateComposite(),
        throwsStateError,
      );
    });

    test('generateComposite returns image data with single frame', () async {
      final imageData = createTestImage(variance: 80);
      service.addFrame(imageData, 0.0);

      final composite = await service.generateComposite();
      expect(composite, isNotEmpty);

      // Verify it's valid JPEG
      final decoded = img.decodeJpg(composite);
      expect(decoded, isNotNull);
    });

    test('generateComposite returns image data with multiple frames', () async {
      final imageData = createTestImage(variance: 80);

      // Add several frames
      for (double angle = 0.0; angle < 6.0; angle += 1.0) {
        service.addFrame(imageData, angle);
      }

      final composite = await service.generateComposite();
      expect(composite, isNotEmpty);

      // Verify it's valid JPEG
      final decoded = img.decodeJpg(composite);
      expect(decoded, isNotNull);
    });
  });

  group('ScanFrame', () {
    test('stores frame data correctly', () {
      final imageData = Uint8List.fromList([1, 2, 3, 4]);
      final timestamp = DateTime.now();

      final frame = ScanFrame(
        imageData: imageData,
        rotationAngle: 1.57,
        timestamp: timestamp,
        qualityScore: 0.85,
      );

      expect(frame.imageData, equals(imageData));
      expect(frame.rotationAngle, equals(1.57));
      expect(frame.timestamp, equals(timestamp));
      expect(frame.qualityScore, equals(0.85));
    });
  });
}
