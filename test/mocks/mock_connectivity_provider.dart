import 'package:archery_super_app/providers/connectivity_provider.dart';

/// Mock ConnectivityProvider for testing.
///
/// Extends the real ConnectivityProvider but overrides the connectivity
/// checking to avoid platform-specific issues in tests.
/// Always reports online status by default.
class MockConnectivityProvider extends ConnectivityProvider {
  bool _testIsOnline;

  MockConnectivityProvider({bool isOnline = true}) : _testIsOnline = isOnline;

  @override
  bool get isOnline => _testIsOnline;

  @override
  bool get isOffline => !_testIsOnline;

  /// Set online status for testing
  void setOnline(bool online) {
    if (_testIsOnline != online) {
      _testIsOnline = online;
      notifyListeners();
    }
  }
}
