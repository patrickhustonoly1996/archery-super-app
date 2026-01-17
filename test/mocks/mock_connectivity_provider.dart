import 'package:flutter/foundation.dart';

/// Mock ConnectivityProvider for testing.
///
/// Always reports online status by default. Can be configured
/// for offline testing scenarios.
class MockConnectivityProvider with ChangeNotifier {
  bool _isOnline;
  bool _isSyncing = false;

  MockConnectivityProvider({bool isOnline = true}) : _isOnline = isOnline;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get isOffline => !_isOnline;

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
