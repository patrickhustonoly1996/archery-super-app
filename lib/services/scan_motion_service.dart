import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Tracks device motion during the circular scan gesture.
/// Uses gyroscope data to detect rotation and calculate scan progress.
class ScanMotionService {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  // Motion state
  double _totalRotation = 0.0;
  double _currentAngularVelocity = 0.0;
  bool _isMoving = false;
  bool _isStable = true;
  DateTime? _lastEventTime;

  // Calibration
  double _gyroOffsetZ = 0.0;
  final List<double> _calibrationSamples = [];
  bool _isCalibrated = false;

  // Thresholds
  static const double kMinAngularVelocity = 0.15; // rad/s - minimum to count as moving
  static const double kMaxAngularVelocity = 2.0; // rad/s - too fast warning
  static const double kStabilityThreshold = 0.5; // g - device shake threshold
  static const double kFullRotation = 2 * math.pi; // Full circle in radians
  static const int kCalibrationSamples = 20;

  // Callbacks
  Function(double progress, double velocity)? onProgressUpdate;
  Function(bool isTooFast)? onSpeedWarning;
  Function(bool isUnstable)? onStabilityWarning;
  Function()? onScanComplete;

  /// Start tracking motion for a scan
  Future<void> startTracking() async {
    _reset();

    // Start calibration
    await _calibrate();

    // Listen to gyroscope for rotation tracking
    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_handleGyroscopeEvent);

    // Listen to accelerometer for stability detection
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_handleAccelerometerEvent);
  }

  /// Stop tracking motion
  void stopTracking() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  /// Reset tracking state
  void _reset() {
    _totalRotation = 0.0;
    _currentAngularVelocity = 0.0;
    _isMoving = false;
    _isStable = true;
    _lastEventTime = null;
    _isCalibrated = false;
    _calibrationSamples.clear();
  }

  /// Calibrate gyroscope to remove bias
  Future<void> _calibrate() async {
    _calibrationSamples.clear();

    final completer = Completer<void>();

    final calibrationSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      _calibrationSamples.add(event.z);

      if (_calibrationSamples.length >= kCalibrationSamples) {
        // Calculate average offset
        _gyroOffsetZ = _calibrationSamples.reduce((a, b) => a + b) /
            _calibrationSamples.length;
        _isCalibrated = true;
        completer.complete();
      }
    });

    await completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        _gyroOffsetZ = 0.0;
        _isCalibrated = true;
      },
    );

    await calibrationSub.cancel();
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    if (!_isCalibrated) return;

    final now = DateTime.now();
    if (_lastEventTime != null) {
      final dt = now.difference(_lastEventTime!).inMicroseconds / 1000000.0;

      // Z-axis rotation (phone rotating flat on a plane)
      final angularVelocityZ = event.z - _gyroOffsetZ;
      _currentAngularVelocity = angularVelocityZ.abs();

      // Check if moving
      _isMoving = _currentAngularVelocity > kMinAngularVelocity;

      // Check speed warning
      final isTooFast = _currentAngularVelocity > kMaxAngularVelocity;
      onSpeedWarning?.call(isTooFast);

      // Accumulate rotation (only positive/clockwise direction for now)
      if (_isMoving && angularVelocityZ > 0) {
        _totalRotation += angularVelocityZ * dt;

        // Clamp to full rotation
        if (_totalRotation >= kFullRotation) {
          _totalRotation = kFullRotation;
          onScanComplete?.call();
        }

        // Report progress
        final progress = _totalRotation / kFullRotation;
        onProgressUpdate?.call(progress, _currentAngularVelocity);
      }
    }

    _lastEventTime = now;
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Calculate magnitude of acceleration (should be ~9.8 when stable)
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Check for device shake/instability
    final deviation = (magnitude - 9.8).abs();
    final wasStable = _isStable;
    _isStable = deviation < kStabilityThreshold;

    if (wasStable != _isStable) {
      onStabilityWarning?.call(!_isStable);
    }
  }

  /// Get current scan progress (0.0 to 1.0)
  double get progress => _totalRotation / kFullRotation;

  /// Whether device is currently in motion
  bool get isMoving => _isMoving;

  /// Whether device is stable (not shaking)
  bool get isStable => _isStable;

  /// Current angular velocity in rad/s
  double get angularVelocity => _currentAngularVelocity;

  void dispose() {
    stopTracking();
  }
}

/// Simulated motion service for testing and web fallback
class SimulatedScanMotionService extends ScanMotionService {
  Timer? _simulationTimer;

  @override
  Future<void> startTracking() async {
    _reset();
    // Simulate motion progress over time for testing
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      _simulateTick,
    );
  }

  void _simulateTick(Timer timer) {
    // Increment by small amount each tick
    _totalRotation += 0.05;
    _currentAngularVelocity = 0.8; // Simulated comfortable speed
    _isMoving = true;

    if (_totalRotation >= kFullRotation) {
      _totalRotation = kFullRotation;
      timer.cancel();
      onScanComplete?.call();
    }

    onProgressUpdate?.call(progress, _currentAngularVelocity);
  }

  @override
  void stopTracking() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    super.stopTracking();
  }

  void _reset() {
    _totalRotation = 0.0;
    _currentAngularVelocity = 0.0;
    _isMoving = false;
  }
}
