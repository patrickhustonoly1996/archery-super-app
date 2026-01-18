import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User's arrow appearance for identification in tournament scenarios
class ArrowAppearance {
  final String? fletchColor;
  final String? nockColor;
  final String? wrapColor;
  final String? shaftColor;

  const ArrowAppearance({
    this.fletchColor,
    this.nockColor,
    this.wrapColor,
    this.shaftColor,
  });

  bool get hasAnyFeatures =>
      fletchColor != null || nockColor != null || wrapColor != null || shaftColor != null;

  Map<String, dynamic> toJson() => {
        if (fletchColor != null) 'fletchColor': fletchColor,
        if (nockColor != null) 'nockColor': nockColor,
        if (wrapColor != null) 'wrapColor': wrapColor,
        if (shaftColor != null) 'shaftColor': shaftColor,
      };

  factory ArrowAppearance.fromJson(Map<String, dynamic> json) {
    return ArrowAppearance(
      fletchColor: json['fletchColor'] as String?,
      nockColor: json['nockColor'] as String?,
      wrapColor: json['wrapColor'] as String?,
      shaftColor: json['shaftColor'] as String?,
    );
  }
}

/// Arrow position detected by vision API
class DetectedArrow {
  final double x; // -1.0 (left) to +1.0 (right), 0 = center
  final double y; // -1.0 (top) to +1.0 (bottom), 0 = center
  final int? faceIndex; // For triple-spot: 0, 1, 2
  final double confidence; // 0.0-1.0, lower means less certain (line cutters)
  final bool isLineCutter; // True if arrow is on/near a ring line
  final bool isMyArrow; // True if arrow matches user's registered appearance

  DetectedArrow({
    required this.x,
    required this.y,
    this.faceIndex,
    this.confidence = 1.0,
    this.isLineCutter = false,
    this.isMyArrow = false,
  });

  /// Whether this arrow needs user verification (low confidence or line cutter)
  bool get needsVerification => confidence < 0.5 || isLineCutter;

  factory DetectedArrow.fromJson(Map<String, dynamic> json) {
    return DetectedArrow(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      faceIndex: json['face'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isLineCutter: json['isLineCutter'] as bool? ?? false,
      isMyArrow: json['isMyArrow'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        if (faceIndex != null) 'face': faceIndex,
        'confidence': confidence,
        'isLineCutter': isLineCutter,
        'isMyArrow': isMyArrow,
      };

  /// Create a copy with updated position (for adjustment)
  DetectedArrow copyWith({double? x, double? y, int? faceIndex, double? confidence, bool? isLineCutter, bool? isMyArrow}) {
    return DetectedArrow(
      x: x ?? this.x,
      y: y ?? this.y,
      faceIndex: faceIndex ?? this.faceIndex,
      confidence: confidence ?? this.confidence,
      isLineCutter: isLineCutter ?? this.isLineCutter,
      isMyArrow: isMyArrow ?? this.isMyArrow,
    );
  }
}

/// Result of vision API arrow detection
class ArrowDetectionResult {
  final List<DetectedArrow> arrows;
  final String? error;

  ArrowDetectionResult.success(this.arrows) : error = null;
  ArrowDetectionResult.failure(this.error) : arrows = [];

  bool get isSuccess => error == null;
}

/// Auto-Plot usage status
class AutoPlotStatus {
  final int scanCount;
  final bool isPro;
  final int limit;
  final int remaining;

  AutoPlotStatus({
    required this.scanCount,
    required this.isPro,
    required this.limit,
    required this.remaining,
  });

  factory AutoPlotStatus.fromJson(Map<String, dynamic> json) {
    return AutoPlotStatus(
      scanCount: json['scanCount'] as int? ?? 0,
      isPro: json['isPro'] as bool? ?? false,
      limit: json['limit'] as int? ?? 50,
      remaining: json['remaining'] as int? ?? 50,
    );
  }

  bool get hasScansRemaining => isPro || remaining > 0;
}

/// Service for camera-based arrow detection using Firebase Functions backend
class VisionApiService {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  VisionApiService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get userId => _auth.currentUser?.uid;

  /// Detect arrows on a target image via Firebase Function
  ///
  /// [shotImage] - The image with arrows to analyze
  /// [referenceImage] - Optional clean target reference image
  /// [targetType] - Target type ('40cm', '80cm', '122cm', 'triple_40cm')
  /// [isTripleSpot] - Whether this is a triple-spot (3 vertical faces)
  /// [arrowAppearance] - Optional user's arrow appearance for identification
  Future<ArrowDetectionResult> detectArrows({
    required Uint8List shotImage,
    Uint8List? referenceImage,
    required String targetType,
    bool isTripleSpot = false,
    ArrowAppearance? arrowAppearance,
  }) async {
    if (!isAuthenticated) {
      return ArrowDetectionResult.failure('Authentication required. Please sign in.');
    }

    try {
      final callable = _functions.httpsCallable(
        'detectArrows',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'shotImage': base64Encode(shotImage),
        'referenceImage': referenceImage != null ? base64Encode(referenceImage) : null,
        'targetType': targetType,
        'isTripleSpot': isTripleSpot,
        'userId': userId,
        if (arrowAppearance != null && arrowAppearance.hasAnyFeatures)
          'arrowAppearance': arrowAppearance.toJson(),
      });

      final data = result.data;

      if (data['success'] == true) {
        final arrowsList = data['arrows'] as List<dynamic>?;
        if (arrowsList != null) {
          final arrows = arrowsList
              .map((item) => DetectedArrow.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return ArrowDetectionResult.success(arrows);
        }
        return ArrowDetectionResult.success([]);
      } else {
        return ArrowDetectionResult.failure(data['error'] as String? ?? 'Unknown error');
      }
    } on FirebaseFunctionsException catch (e) {
      // Handle specific Firebase Functions errors
      switch (e.code) {
        case 'unauthenticated':
          return ArrowDetectionResult.failure('Please sign in to use Auto-Plot');
        case 'resource-exhausted':
          return ArrowDetectionResult.failure('Monthly scan limit reached. Upgrade to Auto-Plot Pro for unlimited scans.');
        case 'unavailable':
          return ArrowDetectionResult.failure('Service temporarily unavailable. Please try again.');
        default:
          return ArrowDetectionResult.failure(e.message ?? 'Service error: ${e.code}');
      }
    } catch (e) {
      return ArrowDetectionResult.failure('Connection error: $e');
    }
  }

  /// Get Auto-Plot usage status
  Future<AutoPlotStatus?> getUsageStatus() async {
    if (!isAuthenticated) {
      return null;
    }

    try {
      final callable = _functions.httpsCallable(
        'getAutoPlotStatus',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );

      final result = await callable.call<Map<String, dynamic>>({});
      final data = result.data;

      if (data.containsKey('error')) {
        return null;
      }

      return AutoPlotStatus.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Learn arrow appearance from user's manual selection
  /// Asks AI to describe the visual characteristics of selected arrows
  Future<LearnedAppearanceResult> learnArrowAppearance({
    required Uint8List image,
    required List<DetectedArrow> selectedArrows,
  }) async {
    if (!isAuthenticated) {
      return LearnedAppearanceResult.failure('Authentication required');
    }

    try {
      final callable = _functions.httpsCallable(
        'learnArrowAppearance',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final arrowPositions = selectedArrows.map((a) => {
        'x': a.x,
        'y': a.y,
      }).toList();

      final result = await callable.call<Map<String, dynamic>>({
        'image': base64Encode(image),
        'arrowPositions': arrowPositions,
        'userId': userId,
      });

      final data = result.data;

      if (data['success'] == true) {
        final appearanceData = data['appearance'] as Map<String, dynamic>?;
        ArrowAppearance? appearance;
        if (appearanceData != null) {
          appearance = ArrowAppearance(
            fletchColor: appearanceData['fletchColor'] as String?,
            nockColor: appearanceData['nockColor'] as String?,
            wrapColor: appearanceData['wrapColor'] as String?,
          );
        }
        return LearnedAppearanceResult.success(
          appearance: appearance,
          description: data['description'] as String?,
        );
      } else {
        return LearnedAppearanceResult.failure(
          data['error'] as String? ?? 'Failed to learn appearance',
        );
      }
    } catch (e) {
      return LearnedAppearanceResult.failure('Connection error: $e');
    }
  }
}

/// Result of learning arrow appearance
class LearnedAppearanceResult {
  final bool isSuccess;
  final ArrowAppearance? appearance;
  final String? description;
  final String? error;

  LearnedAppearanceResult._({
    required this.isSuccess,
    this.appearance,
    this.description,
    this.error,
  });

  factory LearnedAppearanceResult.success({
    ArrowAppearance? appearance,
    String? description,
  }) {
    return LearnedAppearanceResult._(
      isSuccess: true,
      appearance: appearance,
      description: description,
    );
  }

  factory LearnedAppearanceResult.failure(String error) {
    return LearnedAppearanceResult._(
      isSuccess: false,
      error: error,
    );
  }
}
