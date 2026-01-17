import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'db/database.dart';
import 'theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/bow_training_provider.dart';
import 'providers/breath_training_provider.dart';
import 'providers/active_sessions_provider.dart';
import 'providers/spider_graph_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/firestore_sync_service.dart';
import 'utils/error_handler.dart';

/// Global scaffold messenger key for showing snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase in background - don't block app startup
  // AuthGate handles offline/unauthenticated state gracefully
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((e) {
    debugPrint('Firebase init error: $e');
  });

  runApp(const ArcherySuperApp());
}

class ArcherySuperApp extends StatefulWidget {
  const ArcherySuperApp({super.key});

  @override
  State<ArcherySuperApp> createState() => _ArcherySuperAppState();
}

class _ArcherySuperAppState extends State<ArcherySuperApp> {
  // Database created immediately - no blocking initialization
  // Drift/WASM connections are lazy; actual connection opens on first query
  late final AppDatabase _database = AppDatabase();

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AppDatabase>.value(
      value: _database,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => SessionProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                EquipmentProvider(context.read<AppDatabase>())..loadEquipment(),
          ),
          ChangeNotifierProvider(
            create: (context) => BowTrainingProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) => BreathTrainingProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => ActiveSessionsProvider()..loadSessions(),
          ),
          ChangeNotifierProvider(
            create: (context) => SpiderGraphProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) => ConnectivityProvider(),
          ),
        ],
        child: MaterialApp(
          title: 'Archery Super App',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Checks auth state and shows login or home screen
/// Offline-first: Uses cached auth state, doesn't block on network
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _timedOut = false;
  bool _hasReceivedData = false;
  User? _cachedUser;
  bool _hasTriggeredSync = false;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Try to get cached user - Firebase might not be initialized yet
    try {
      _cachedUser = FirebaseAuth.instance.currentUser;
      _firebaseReady = true;
    } catch (e) {
      // Firebase not ready yet - that's fine, we'll check connectivity
      debugPrint('Firebase not ready: $e');
      _firebaseReady = false;
    }

    // If we have a cached user, we're done - go straight to home
    if (_cachedUser != null) {
      _triggerBackgroundSync();
      if (mounted) setState(() {});
      return;
    }

    // No cached user - check connectivity to decide how long to wait
    // If offline, go straight to login (no point waiting for Firebase)
    final connectivity = context.read<ConnectivityProvider>();
    if (connectivity.isOffline) {
      if (mounted) setState(() => _timedOut = true);
      return;
    }

    // Online but no cached user - wait briefly for Firebase stream
    // Reduced from 3s to 1.5s for faster UX
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_hasReceivedData) {
        setState(() => _timedOut = true);
      }
    });
  }

  /// Trigger cloud restore (if local empty) then backup
  /// This ensures data is never lost across devices/browser clears
  void _triggerBackgroundSync() {
    if (_hasTriggeredSync) return;
    _hasTriggeredSync = true;

    // Run sync in background without blocking UI
    Future.microtask(() async {
      try {
        final db = context.read<AppDatabase>();
        final syncService = FirestoreSyncService();

        // First try to restore from cloud if local is empty
        // This handles the case where user clears browser data or logs in on new device
        try {
          final result = await syncService.restoreAllData(db);
          if (result.totalRestored > 0) {
            debugPrint('Cloud restore completed: ${result.message}');
          }
        } catch (e) {
          debugPrint('Cloud restore error: $e');
          // Show error for restore failures (user may have lost data)
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Cloud restore failed: $e'),
              backgroundColor: Colors.red.shade900,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Then backup any local data to cloud
        await ErrorHandler.runBackground(
          () => syncService.backupAllData(db),
          errorMessage: 'Cloud backup failed',
          onRetry: _triggerBackgroundSync,
        );
      } catch (e) {
        // Firebase not initialized (tests) or other initialization error
        debugPrint('Background sync skipped: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cached user, go straight to home (offline-first)
    if (_cachedUser != null) {
      return const HomeScreen();
    }

    // If Firebase isn't ready or timed out, show login immediately
    // No point waiting for a stream that can't connect
    if (!_firebaseReady || _timedOut) {
      return const LoginScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Track if we've received any data from the stream
        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          _hasReceivedData = true;
        }

        // Show loading while checking auth state (with timeout)
        if (!_hasReceivedData && !_timedOut) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }

        // User is logged in (stream confirmed)
        if (snapshot.hasData) {
          // Trigger restore/backup when user logs in
          _triggerBackgroundSync();
          return const HomeScreen();
        }

        // User is not logged in (or timed out with no cached user)
        return const LoginScreen();
      },
    );
  }
}
