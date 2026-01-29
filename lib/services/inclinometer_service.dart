import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Measures device tilt angle for field archery slope compensation.
///
/// Reports the pitch angle of the device:
/// - Negative degrees = device tilted up (uphill shot)
/// - Positive degrees = device tilted down (downhill shot)
/// - Zero = flat/level
///
/// Uses accelerometer with low-pass filter for stable readings.
class InclinometerService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  // State
  double _currentAngle = 0.0;
  bool _isStable = false;
  bool _isReading = false;

  // Low-pass filter
  double _filteredX = 0.0;
  double _filteredY = 0.0;
  double _filteredZ = 0.0;
  bool _filterInitialized = false;
  static const double _filterAlpha = 0.1; // smoothing factor

  // Stability detection
  final List<double> _recentReadings = [];
  static const int _stabilityWindowSize = 10;
  static const double _stabilityThreshold = 0.5; // degrees variance threshold

  // Callbacks
  Function(double angle, bool isStable)? onAngleUpdate;

  /// Current angle in degrees (negative = uphill, positive = downhill)
  double get currentAngle => _currentAngle;

  /// Whether the reading is stable (low variance)
  bool get isStable => _isStable;

  /// Whether the service is actively reading
  bool get isReading => _isReading;

  /// Start reading accelerometer data
  void startReading() {
    if (_isReading) return;
    _isReading = true;
    _filterInitialized = false;
    _recentReadings.clear();

    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_handleAccelerometerEvent);
  }

  /// Stop reading accelerometer data
  void stopReading() {
    _isReading = false;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Apply low-pass filter for stabilization
    if (!_filterInitialized) {
      _filteredX = event.x;
      _filteredY = event.y;
      _filteredZ = event.z;
      _filterInitialized = true;
    } else {
      _filteredX = _filteredX + _filterAlpha * (event.x - _filteredX);
      _filteredY = _filteredY + _filterAlpha * (event.y - _filteredY);
      _filteredZ = _filteredZ + _filterAlpha * (event.z - _filteredZ);
    }

    // Calculate pitch angle from filtered accelerometer data
    // atan2(y, sqrt(x^2 + z^2)) gives the tilt from horizontal
    // When phone is held in portrait and tilted up/down:
    // - y increases when tilted upward (phone bottom up)
    // - z decreases when tilted from vertical
    final pitch = math.atan2(
      _filteredY,
      math.sqrt(_filteredX * _filteredX + _filteredZ * _filteredZ),
    ) * (180 / math.pi);

    // Convert to archery convention:
    // Negative = uphill (phone tilted up), Positive = downhill (phone tilted down)
    // When phone is held upright (~90° from flat), we measure deviation from vertical
    _currentAngle = -(pitch - 90); // 90° is vertical (phone upright), deviation from that

    // Clamp to reasonable range
    _currentAngle = _currentAngle.clamp(-45.0, 45.0);

    // Update stability tracking
    _recentReadings.add(_currentAngle);
    if (_recentReadings.length > _stabilityWindowSize) {
      _recentReadings.removeAt(0);
    }
    _isStable = _calculateIsStable();

    // Notify listeners
    onAngleUpdate?.call(_currentAngle, _isStable);
  }

  bool _calculateIsStable() {
    if (_recentReadings.length < _stabilityWindowSize) return false;

    // Calculate variance of recent readings
    final mean = _recentReadings.reduce((a, b) => a + b) / _recentReadings.length;
    final variance = _recentReadings.fold(
      0.0,
      (sum, reading) => sum + (reading - mean) * (reading - mean),
    ) / _recentReadings.length;

    return variance < _stabilityThreshold;
  }

  /// Dispose and clean up resources
  void dispose() {
    stopReading();
    onAngleUpdate = null;
  }
}

/// Simulated inclinometer for testing and platforms without sensors
class SimulatedInclinometerService extends InclinometerService {
  Timer? _simulationTimer;
  double _targetAngle;

  SimulatedInclinometerService({double targetAngle = -12.5})
      : _targetAngle = targetAngle;

  /// Set the simulated angle
  set targetAngle(double angle) {
    _targetAngle = angle;
  }

  @override
  void startReading() {
    if (_isReading) return;
    _isReading = true;
    _recentReadings.clear();

    // Simulate gradual settling to target angle
    double current = 0.0;
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        // Ease toward target angle
        current += (_targetAngle - current) * 0.15;
        _currentAngle = current;

        _recentReadings.add(_currentAngle);
        if (_recentReadings.length > _stabilityWindowSize) {
          _recentReadings.removeAt(0);
        }
        _isStable = _calculateIsStable();

        onAngleUpdate?.call(_currentAngle, _isStable);
      },
    );
  }

  @override
  void stopReading() {
    _isReading = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
