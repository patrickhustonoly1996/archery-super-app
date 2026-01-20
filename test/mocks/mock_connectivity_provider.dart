import 'package:flutter/foundation.dart';
import 'package:archery_super_app/providers/connectivity_provider.dart';

/// Mock ConnectivityProvider for testing.
///
/// Extends the real ConnectivityProvider for type compatibility with
/// Provider<ConnectivityProvider> while allowing full control over state.
///
/// Note: Tests using this mock must call TestWidgetsFlutterBinding.ensureInitialized()
/// before creating instances, as the parent constructor initializes platform channels.
///
/// Always reports online status by default.
class MockConnectivityProvider extends ConnectivityProvider {
  bool _testIsOnline;
  bool _testIsSyncing = false;

  MockConnectivityProvider({bool isOnline = true}) : _testIsOnline = isOnline;

  @override
  bool get isOnline => _testIsOnline;

  @override
  bool get isOffline => !_testIsOnline;

  @override
  bool get isSyncing => _testIsSyncing;

  /// Set online status for testing
  void setOnline(bool online) {
    if (_testIsOnline != online) {
      _testIsOnline = online;
      notifyListeners();
    }
  }

  @override
  void setSyncing(bool syncing) {
    if (_testIsSyncing != syncing) {
      _testIsSyncing = syncing;
      notifyListeners();
    }
  }
}

/// Standalone mock connectivity provider for unit tests.
///
/// Does not extend ConnectivityProvider, so it doesn't trigger platform
/// channel initialization. Use this for pure unit tests that don't need
/// type compatibility with Provider<ConnectivityProvider>.
class StandaloneMockConnectivityProvider with ChangeNotifier {
  bool _isOnline;
  bool _isSyncing = false;

  StandaloneMockConnectivityProvider({bool isOnline = true})
      : _isOnline = isOnline;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isSyncing => _isSyncing;

  /// Set online status for testing
  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  /// Set syncing status for testing
  void setSyncing(bool syncing) {
    if (_isSyncing != syncing) {
      _isSyncing = syncing;
      notifyListeners();
    }
  }
}
