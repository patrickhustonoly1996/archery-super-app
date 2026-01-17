import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Arrow position detected by vision API
class DetectedArrow {
  final double x; // -1.0 (left) to +1.0 (right), 0 = center
  final double y; // -1.0 (top) to +1.0 (bottom), 0 = center
  final int? faceIndex; // For triple-spot: 0, 1, 2

  DetectedArrow({required this.x, required this.y, this.faceIndex});

  factory DetectedArrow.fromJson(Map<String, dynamic> json) {
    return DetectedArrow(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      faceIndex: json['face'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        if (faceIndex != null) 'face': faceIndex,
      };
}

/// Result of vision API arrow detection
class ArrowDetectionResult {
  final List<DetectedArrow> arrows;
  final String? error;

  ArrowDetectionResult.success(this.arrows) : error = null;
  ArrowDetectionResult.failure(this.error) : arrows = [];

  bool get isSuccess => error == null;
}

/// Service for camera-based arrow detection using Claude Vision API
class VisionApiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';

  final String? _apiKey;

  VisionApiService({String? apiKey}) : _apiKey = apiKey;

  /// Detect arrows on a target image
  ///
  /// [shotImage] - The image with arrows to analyze
  /// [referenceImage] - Optional clean target reference image
  /// [targetType] - Target type ('40cm', '80cm', '122cm', 'triple_40cm')
  /// [isTripleSpot] - Whether this is a triple-spot (3 vertical faces)
  Future<ArrowDetectionResult> detectArrows({
    required Uint8List shotImage,
    Uint8List? referenceImage,
    required String targetType,
    bool isTripleSpot = false,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return ArrowDetectionResult.failure('API key not configured');
    }

    try {
      final prompt = _buildPrompt(targetType, isTripleSpot);
      final content = _buildContent(shotImage, referenceImage, prompt);

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': content}
          ],
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'API error ${response.statusCode}';
        return ArrowDetectionResult.failure(errorMsg);
      }

      final responseBody = jsonDecode(response.body);
      final textContent = responseBody['content']?[0]?['text'] as String?;

      if (textContent == null) {
        return ArrowDetectionResult.failure('Empty response from API');
      }

      return _parseResponse(textContent);
    } on SocketException {
      return ArrowDetectionResult.failure('No internet connection');
    } on http.ClientException catch (e) {
      return ArrowDetectionResult.failure('Network error: ${e.message}');
    } catch (e) {
      return ArrowDetectionResult.failure('Unexpected error: $e');
    }
  }

  String _buildPrompt(String targetType, bool isTripleSpot) {
    final targetDesc = _getTargetDescription(targetType);

    if (isTripleSpot) {
      return '''You are analyzing an archery target image with 3 vertical target faces (triple-spot layout).

TARGET: $targetDesc - three faces arranged vertically

Task: Identify all arrow positions on the target.

For each arrow, return its position as:
- "face": 0 (top), 1 (middle), or 2 (bottom)
- "x": normalized from -1.0 (left edge of that face) to +1.0 (right edge)
- "y": normalized from -1.0 (top of that face) to +1.0 (bottom)
- (0, 0) = center of that face (X ring)

Return ONLY a JSON array, no other text:
[{"face": 0, "x": 0.12, "y": -0.05}, {"face": 1, "x": -0.23, "y": 0.18}]

If no arrows are visible or you cannot reliably detect them, return:
{"error": "reason"}''';
    }

    return '''You are analyzing an archery target image.

TARGET: $targetDesc

Task: Identify all arrow positions on the target.

For each arrow, return its position as normalized coordinates where:
- (0, 0) = center of target (X ring)
- x: -1.0 (left edge) to +1.0 (right edge)
- y: -1.0 (top edge) to +1.0 (bottom edge)

Return ONLY a JSON array, no other text:
[{"x": 0.12, "y": -0.05}, {"x": -0.23, "y": 0.18}]

If no arrows are visible or you cannot reliably detect them, return:
{"error": "reason"}''';
  }

  String _getTargetDescription(String targetType) {
    switch (targetType) {
      case '40cm':
        return '40cm indoor target face (10 rings, gold center)';
      case '60cm':
        return '60cm target face (10 rings, gold center)';
      case '80cm':
        return '80cm target face (10 rings, gold center)';
      case '122cm':
        return '122cm outdoor target face (10 rings, gold center)';
      case 'triple_40cm':
        return '40cm triple-spot (3 vertical 40cm faces)';
      default:
        return '$targetType archery target face';
    }
  }

  List<Map<String, dynamic>> _buildContent(
    Uint8List shotImage,
    Uint8List? referenceImage,
    String prompt,
  ) {
    final content = <Map<String, dynamic>>[];

    // Add reference image if provided
    if (referenceImage != null) {
      content.add({
        'type': 'text',
        'text': 'REFERENCE IMAGE (clean target, no arrows):',
      });
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': base64Encode(referenceImage),
        },
      });
    }

    // Add shot image
    content.add({
      'type': 'text',
      'text': 'SHOT IMAGE (target with arrows to analyze):',
    });
    content.add({
      'type': 'image',
      'source': {
        'type': 'base64',
        'media_type': 'image/jpeg',
        'data': base64Encode(shotImage),
      },
    });

    // Add prompt
    content.add({
      'type': 'text',
      'text': prompt,
    });

    return content;
  }

  ArrowDetectionResult _parseResponse(String text) {
    // Clean up the response - extract JSON
    var jsonStr = text.trim();

    // Try to extract JSON from markdown code blocks
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(jsonStr);
    if (codeBlockMatch != null) {
      jsonStr = codeBlockMatch.group(1)!.trim();
    }

    try {
      final decoded = jsonDecode(jsonStr);

      // Check if it's an error response
      if (decoded is Map && decoded.containsKey('error')) {
        return ArrowDetectionResult.failure(decoded['error'] as String);
      }

      // Parse arrow array
      if (decoded is List) {
        final arrows = decoded.map((item) => DetectedArrow.fromJson(item as Map<String, dynamic>)).toList();
        return ArrowDetectionResult.success(arrows);
      }

      return ArrowDetectionResult.failure('Invalid response format');
    } catch (e) {
      return ArrowDetectionResult.failure('Failed to parse response: $e');
    }
  }

  /// Test if API key is valid
  Future<bool> validateApiKey() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
