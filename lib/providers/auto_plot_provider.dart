import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/arrow_specifications.dart';
import '../services/vision_api_service.dart';
import '../utils/unique_id.dart';

/// Free tier scan limit per month
const int kAutoPlotFreeLimit = 50;

/// Auto-Plot subscription tier
enum AutoPlotTier {
  free, // 50 scans/month
  pro, // Unlimited scans
}

/// State for the auto-plot flow
enum AutoPlotState {
  idle,
  capturing,
  processing,
  confirming,
  error,
}

/// Manages Auto-Plot state and business logic
class AutoPlotProvider extends ChangeNotifier {
  final AppDatabase _db;
  final VisionApiService _visionService;

  AutoPlotProvider(this._db, this._visionService);

  // State
  AutoPlotState _state = AutoPlotState.idle;
  AutoPlotTier _tier = AutoPlotTier.free;
  int _scanCount = 0;
  String? _errorMessage;

  // Current detection results
  List<DetectedArrow> _detectedArrows = [];
  Uint8List? _capturedImage;
  String? _selectedTargetType;

  // Registered targets
  List<RegisteredTarget> _registeredTargets = [];

  // Arrow appearance for identification
  ArrowAppearanceForAutoPlot? _arrowAppearance;
  String? _learnedAppearanceDescription; // Human-readable "green fletches, orange nocks"
  bool _hasLearnedAppearance = false;
  bool _isLearning = false;

  // Getters
  AutoPlotState get state => _state;
  AutoPlotTier get tier => _tier;
  int get scanCount => _scanCount;
  int get scansRemaining => _tier == AutoPlotTier.pro ? -1 : kAutoPlotFreeLimit - _scanCount;
  bool get canScan => _tier == AutoPlotTier.pro || _scanCount < kAutoPlotFreeLimit;
  String? get errorMessage => _errorMessage;
  List<DetectedArrow> get detectedArrows => _detectedArrows;
  Uint8List? get capturedImage => _capturedImage;
  String? get selectedTargetType => _selectedTargetType;
  List<RegisteredTarget> get registeredTargets => _registeredTargets;
  ArrowAppearanceForAutoPlot? get arrowAppearance => _arrowAppearance;
  String? get learnedAppearanceDescription => _learnedAppearanceDescription;
  bool get hasLearnedAppearance => _hasLearnedAppearance;
  bool get isLearning => _isLearning;

  /// Initialize provider - load usage and registered targets
  Future<void> initialize() async {
    await _loadUsage();
    await _loadRegisteredTargets();
  }

  Future<void> _loadUsage() async {
    // Try to get server-side usage (source of truth)
    final serverStatus = await _visionService.getUsageStatus();
    if (serverStatus != null) {
      _scanCount = serverStatus.scanCount;
      _tier = serverStatus.isPro ? AutoPlotTier.pro : AutoPlotTier.free;
    } else {
      // Fall back to local count if offline
      _scanCount = await _db.getCurrentAutoPlotScanCount();
    }
    notifyListeners();
  }

  Future<void> _loadRegisteredTargets() async {
    _registeredTargets = await _db.getAllRegisteredTargets();
    notifyListeners();
  }

  /// Set the subscription tier
  void setTier(AutoPlotTier tier) {
    _tier = tier;
    notifyListeners();
  }

  /// Set arrow appearance for identification (from user's quiver settings)
  void setArrowAppearance(ArrowAppearanceForAutoPlot? appearance) {
    _arrowAppearance = appearance;
    notifyListeners();
  }

  /// Load arrow appearance from quiver settings or learned appearance
  /// Priority: 1) Quiver equipment profile colors, 2) Previously learned appearance
  Future<void> loadArrowAppearanceFromQuiver(Quiver? quiver) async {
    // First try quiver settings (explicit user-entered colors)
    if (quiver?.settings != null) {
      final arrowSpecs = ArrowSpecifications.fromJson(quiver!.settings);
      final fromQuiver = arrowSpecs.appearanceForAutoPlot;
      if (fromQuiver.hasAnyFeatures) {
        _arrowAppearance = fromQuiver;
        _hasLearnedAppearance = false;
        notifyListeners();
        return;
      }
    }

    // If no quiver colors, we'll rely on previously learned appearance (if any)
    // The learned appearance is already loaded in _arrowAppearance from Firestore
    // during the API call (server stores and returns it)
    notifyListeners();
  }

  /// Learn arrow appearance from user's manual selection
  /// Call this after user confirms their arrows for the first time
  Future<bool> learnArrowAppearance(List<DetectedArrow> selectedArrows) async {
    if (_capturedImage == null || selectedArrows.isEmpty) {
      return false;
    }

    _isLearning = true;
    notifyListeners();

    try {
      final result = await _visionService.learnArrowAppearance(
        image: _capturedImage!,
        selectedArrows: selectedArrows,
      );

      if (result.isSuccess && result.appearance != null) {
        _arrowAppearance = ArrowAppearanceForAutoPlot(
          fletchColor: result.appearance!.fletchColor,
          nockColor: result.appearance!.nockColor,
          wrapColor: result.appearance!.wrapColor,
        );
        _learnedAppearanceDescription = result.description;
        _hasLearnedAppearance = true;
        _isLearning = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Silent failure - learning is a nice-to-have
    }

    _isLearning = false;
    notifyListeners();
    return false;
  }

  /// Check if a target type has a registered reference
  bool hasRegisteredTarget(String targetType) {
    return _registeredTargets.any((t) => t.targetType == targetType);
  }

  /// Get registered target for a type
  RegisteredTarget? getRegisteredTargetForType(String targetType) {
    try {
      return _registeredTargets.firstWhere((t) => t.targetType == targetType);
    } catch (_) {
      return null;
    }
  }

  /// Register a new target reference image
  Future<void> registerTarget({
    required String targetType,
    required Uint8List imageData,
    bool isTripleSpot = false,
  }) async {
    // Save image to local storage
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${dir.path}/auto_plot_targets');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final id = UniqueId.withPrefix('tgt');
    final imagePath = '${targetDir.path}/$id.jpg';
    final file = File(imagePath);
    await file.writeAsBytes(imageData);

    // Save to database
    await _db.insertRegisteredTarget(
      RegisteredTargetsCompanion.insert(
        id: id,
        targetType: targetType,
        imagePath: imagePath,
        isTripleSpot: Value(isTripleSpot),
      ),
    );

    await _loadRegisteredTargets();
  }

  /// Delete a registered target
  Future<void> deleteRegisteredTarget(String id) async {
    final target = _registeredTargets.firstWhere((t) => t.id == id);

    // Delete image file
    final file = File(target.imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete from database
    await _db.deleteRegisteredTarget(id);
    await _loadRegisteredTargets();
  }

  /// Start the auto-plot capture flow
  void startCapture(String targetType) {
    _selectedTargetType = targetType;
    _state = AutoPlotState.capturing;
    _errorMessage = null;
    _detectedArrows = [];
    _capturedImage = null;
    notifyListeners();
  }

  /// Process a captured image
  Future<void> processImage(Uint8List imageData) async {
    if (!canScan) {
      _state = AutoPlotState.error;
      _errorMessage = 'Monthly scan limit reached. Upgrade to Auto-Plot Pro for unlimited scans.';
      notifyListeners();
      return;
    }

    _capturedImage = imageData;
    _state = AutoPlotState.processing;
    _errorMessage = null;
    notifyListeners();

    // Get reference image if available
    Uint8List? referenceImage;
    final registeredTarget = getRegisteredTargetForType(_selectedTargetType!);
    if (registeredTarget != null) {
      final file = File(registeredTarget.imagePath);
      if (await file.exists()) {
        referenceImage = await file.readAsBytes();
      }
    }

    // Convert arrow appearance for API
    ArrowAppearance? apiAppearance;
    if (_arrowAppearance != null && _arrowAppearance!.hasAnyFeatures) {
      apiAppearance = ArrowAppearance(
        fletchColor: _arrowAppearance!.fletchColor,
        nockColor: _arrowAppearance!.nockColor,
        wrapColor: _arrowAppearance!.wrapColor,
      );
    }

    // Call vision API
    final result = await _visionService.detectArrows(
      shotImage: imageData,
      referenceImage: referenceImage,
      targetType: _selectedTargetType!,
      isTripleSpot: registeredTarget?.isTripleSpot ?? _selectedTargetType!.contains('triple'),
      arrowAppearance: apiAppearance,
    );

    if (result.isSuccess) {
      _detectedArrows = result.arrows;
      _state = AutoPlotState.confirming;

      // Refresh usage from server (Firebase Function incremented it)
      await _loadUsage();
    } else {
      _state = AutoPlotState.error;
      _errorMessage = result.error;
    }

    notifyListeners();
  }

  /// Adjust a detected arrow position
  void adjustArrow(int index, double x, double y) {
    if (index < 0 || index >= _detectedArrows.length) return;

    final arrow = _detectedArrows[index];
    _detectedArrows[index] = DetectedArrow(
      x: x,
      y: y,
      faceIndex: arrow.faceIndex,
    );
    notifyListeners();
  }

  /// Remove a detected arrow
  void removeArrow(int index) {
    if (index < 0 || index >= _detectedArrows.length) return;
    _detectedArrows.removeAt(index);
    notifyListeners();
  }

  /// Add a manual arrow (if detection missed one)
  void addArrow(double x, double y, {int? faceIndex}) {
    _detectedArrows.add(DetectedArrow(x: x, y: y, faceIndex: faceIndex));
    notifyListeners();
  }

  /// Confirm arrows and return them for plotting
  List<DetectedArrow> confirmArrows() {
    final arrows = List<DetectedArrow>.from(_detectedArrows);
    reset();
    return arrows;
  }

  /// Cancel and retry capture
  void retryCapture() {
    _state = AutoPlotState.capturing;
    _errorMessage = null;
    _detectedArrows = [];
    _capturedImage = null;
    notifyListeners();
  }

  /// Reset to idle state
  void reset() {
    _state = AutoPlotState.idle;
    _errorMessage = null;
    _detectedArrows = [];
    _capturedImage = null;
    _selectedTargetType = null;
    notifyListeners();
  }
}
