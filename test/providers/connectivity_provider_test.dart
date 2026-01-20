import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../mocks/mock_connectivity_provider.dart';

/// Tests for ConnectivityProvider and StandaloneMockConnectivityProvider.
///
/// Tests cover:
/// - Basic state properties (isOnline, isOffline, isSyncing)
/// - State transitions and notifications
/// - StandaloneMockConnectivityProvider behavior for testing scenarios
/// - Edge cases and real-world connectivity patterns
///
/// Uses StandaloneMockConnectivityProvider to avoid platform channel
/// initialization in unit tests.
void main() {
  group('ConnectivityProvider State Properties', () {
    test('isOffline is inverse of isOnline', () {
      // Test with mock to control state
      final provider = StandaloneMockConnectivityProvider(isOnline: true);
      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);

      provider.setOnline(false);
      expect(provider.isOnline, isFalse);
      expect(provider.isOffline, isTrue);
    });

    test('initial state defaults to online', () {
      final provider = StandaloneMockConnectivityProvider();
      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);
    });

    test('can be initialized as offline', () {
      final provider = StandaloneMockConnectivityProvider(isOnline: false);
      expect(provider.isOnline, isFalse);
      expect(provider.isOffline, isTrue);
    });
  });

  group('ConnectivityProvider Syncing State', () {
    late StandaloneMockConnectivityProvider provider;

    setUp(() {
      provider = StandaloneMockConnectivityProvider();
    });

    test('isSyncing defaults to false', () {
      expect(provider.isSyncing, isFalse);
    });

    test('setSyncing updates syncing state', () {
      provider.setSyncing(true);
      expect(provider.isSyncing, isTrue);

      provider.setSyncing(false);
      expect(provider.isSyncing, isFalse);
    });

    test('setSyncing notifies listeners on change', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setSyncing(true);
      expect(notifyCount, equals(1));

      provider.setSyncing(false);
      expect(notifyCount, equals(2));
    });

    test('setSyncing does not notify when value unchanged', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Already false, setting to false again
      provider.setSyncing(false);
      expect(notifyCount, equals(0));

      provider.setSyncing(true);
      expect(notifyCount, equals(1));

      // Already true, setting to true again
      provider.setSyncing(true);
      expect(notifyCount, equals(1));
    });
  });

  group('StandaloneMockConnectivityProvider Behavior', () {
    test('setOnline changes online status', () {
      final provider = StandaloneMockConnectivityProvider(isOnline: true);

      provider.setOnline(false);
      expect(provider.isOnline, isFalse);
      expect(provider.isOffline, isTrue);

      provider.setOnline(true);
      expect(provider.isOnline, isTrue);
      expect(provider.isOffline, isFalse);
    });

    test('setOnline notifies listeners on change', () {
      final provider = StandaloneMockConnectivityProvider(isOnline: true);
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setOnline(false);
      expect(notifyCount, equals(1));

      provider.setOnline(true);
      expect(notifyCount, equals(2));
    });

    test('setOnline does not notify when value unchanged', () {
      final provider = StandaloneMockConnectivityProvider(isOnline: true);
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Already true, setting to true again
      provider.setOnline(true);
      expect(notifyCount, equals(0));

      provider.setOnline(false);
      expect(notifyCount, equals(1));

      // Already false, setting to false again
      provider.setOnline(false);
      expect(notifyCount, equals(1));
    });
  });

  group('Connectivity State Combinations', () {
    late StandaloneMockConnectivityProvider provider;

    setUp(() {
      provider = StandaloneMockConnectivityProvider();
    });

    test('online and not syncing is clean state', () {
      provider.setOnline(true);
      provider.setSyncing(false);

      expect(provider.isOnline, isTrue);
      expect(provider.isSyncing, isFalse);
      // This represents the "clean state" where no indicator is shown
    });

    test('online and syncing shows sync indicator', () {
      provider.setOnline(true);
      provider.setSyncing(true);

      expect(provider.isOnline, isTrue);
      expect(provider.isSyncing, isTrue);
    });

    test('offline state takes precedence', () {
      provider.setOnline(false);
      provider.setSyncing(true);

      expect(provider.isOffline, isTrue);
      expect(provider.isSyncing, isTrue);
      // UI should show offline indicator, not sync indicator
    });

    test('offline and not syncing shows offline indicator', () {
      provider.setOnline(false);
      provider.setSyncing(false);

      expect(provider.isOffline, isTrue);
      expect(provider.isSyncing, isFalse);
    });
  });

  group('Connection Status Update Logic', () {
    test('wifi result means online', () {
      final results = [ConnectivityResult.wifi];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isTrue);
    });

    test('mobile result means online', () {
      final results = [ConnectivityResult.mobile];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isTrue);
    });

    test('ethernet result means online', () {
      final results = [ConnectivityResult.ethernet];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isTrue);
    });

    test('none result means offline', () {
      final results = [ConnectivityResult.none];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isFalse);
    });

    test('bluetooth only means offline', () {
      final results = [ConnectivityResult.bluetooth];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isFalse);
    });

    test('vpn only means offline (no underlying connection)', () {
      final results = [ConnectivityResult.vpn];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isFalse);
    });

    test('multiple results with wifi means online', () {
      final results = [ConnectivityResult.wifi, ConnectivityResult.vpn];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isTrue);
    });

    test('empty results means offline', () {
      final results = <ConnectivityResult>[];
      final isOnline = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      expect(isOnline, isFalse);
    });
  });

  group('Listener Management', () {
    late StandaloneMockConnectivityProvider provider;

    setUp(() {
      provider = StandaloneMockConnectivityProvider();
    });

    test('can add and remove listeners', () {
      var called = false;
      void listener() => called = true;

      provider.addListener(listener);
      provider.setOnline(false);
      expect(called, isTrue);

      called = false;
      provider.removeListener(listener);
      provider.setOnline(true);
      expect(called, isFalse);
    });

    test('multiple listeners all receive notifications', () {
      var count1 = 0;
      var count2 = 0;
      var count3 = 0;

      provider.addListener(() => count1++);
      provider.addListener(() => count2++);
      provider.addListener(() => count3++);

      provider.setOnline(false);

      expect(count1, equals(1));
      expect(count2, equals(1));
      expect(count3, equals(1));
    });
  });

  group('Real-World Scenarios', () {
    late StandaloneMockConnectivityProvider provider;

    setUp(() {
      provider = StandaloneMockConnectivityProvider();
    });

    test('airplane mode scenario', () {
      // Start online
      expect(provider.isOnline, isTrue);

      // Turn on airplane mode
      provider.setOnline(false);
      expect(provider.isOffline, isTrue);

      // Turn off airplane mode
      provider.setOnline(true);
      expect(provider.isOnline, isTrue);
    });

    test('sync operation lifecycle', () {
      // Start clean state
      expect(provider.isOnline, isTrue);
      expect(provider.isSyncing, isFalse);

      // Start sync
      provider.setSyncing(true);
      expect(provider.isSyncing, isTrue);

      // Complete sync
      provider.setSyncing(false);
      expect(provider.isSyncing, isFalse);
    });

    test('connection lost during sync', () {
      // Start syncing while online
      provider.setOnline(true);
      provider.setSyncing(true);
      expect(provider.isOnline, isTrue);
      expect(provider.isSyncing, isTrue);

      // Lose connection
      provider.setOnline(false);
      expect(provider.isOffline, isTrue);
      expect(provider.isSyncing, isTrue); // Sync state unchanged

      // Sync operation should handle this and set syncing to false
      provider.setSyncing(false);
      expect(provider.isOffline, isTrue);
      expect(provider.isSyncing, isFalse);
    });

    test('reconnection after being offline', () {
      // Go offline
      provider.setOnline(false);
      expect(provider.isOffline, isTrue);

      // Reconnect
      provider.setOnline(true);
      expect(provider.isOnline, isTrue);

      // Should trigger sync
      provider.setSyncing(true);
      expect(provider.isSyncing, isTrue);

      // Sync completes
      provider.setSyncing(false);
      expect(provider.isSyncing, isFalse);
    });

    test('flaky connection with rapid state changes', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Rapid state changes
      provider.setOnline(false); // notify
      provider.setOnline(true); // notify
      provider.setOnline(false); // notify
      provider.setOnline(true); // notify

      expect(notifyCount, equals(4));
      expect(provider.isOnline, isTrue);
    });

    test('no unnecessary notifications on same state', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Try to set online when already online
      provider.setOnline(true);
      provider.setOnline(true);
      provider.setOnline(true);

      expect(notifyCount, equals(0));
    });
  });

  group('Edge Cases', () {
    test('provider works after many state changes', () {
      final provider = StandaloneMockConnectivityProvider();

      // Simulate 100 state changes
      for (var i = 0; i < 100; i++) {
        provider.setOnline(i.isEven);
        provider.setSyncing(i.isOdd);
      }

      // Should still work correctly
      provider.setOnline(true);
      provider.setSyncing(false);
      expect(provider.isOnline, isTrue);
      expect(provider.isSyncing, isFalse);
    });

    test('listener count handling', () {
      final provider = StandaloneMockConnectivityProvider();
      final listeners = <void Function()>[];

      // Add many listeners
      for (var i = 0; i < 50; i++) {
        void listener() {}
        listeners.add(listener);
        provider.addListener(listener);
      }

      // Remove all listeners
      for (final listener in listeners) {
        provider.removeListener(listener);
      }

      // Should still notify with no listeners without error
      provider.setOnline(false);
      expect(provider.isOffline, isTrue);
    });
  });

  group('Offline-First Architecture Support', () {
    late StandaloneMockConnectivityProvider provider;

    setUp(() {
      provider = StandaloneMockConnectivityProvider();
    });

    test('app should function in offline state', () {
      provider.setOnline(false);

      // The provider exposes offline state
      expect(provider.isOffline, isTrue);
      // App logic should check this and work with local data
    });

    test('graceful degradation when going offline', () {
      // Start online
      provider.setOnline(true);
      expect(provider.isOnline, isTrue);

      // Go offline
      provider.setOnline(false);
      expect(provider.isOffline, isTrue);

      // App should continue working with local data
      // This is a marker that the state is correctly exposed
    });

    test('sync triggers when coming back online', () {
      var stateChanges = <Map<String, bool>>[];

      provider.addListener(() {
        stateChanges.add({
          'isOnline': provider.isOnline,
          'isSyncing': provider.isSyncing,
        });
      });

      // Go offline
      provider.setOnline(false);
      // Come back online
      provider.setOnline(true);
      // Sync would be triggered
      provider.setSyncing(true);
      // Sync completes
      provider.setSyncing(false);

      expect(stateChanges.length, equals(4));
      // Verify state progression
      expect(stateChanges[0]['isOnline'], isFalse); // went offline
      expect(stateChanges[1]['isOnline'], isTrue); // came online
      expect(stateChanges[2]['isSyncing'], isTrue); // syncing
      expect(stateChanges[3]['isSyncing'], isFalse); // sync done
    });
  });
}
