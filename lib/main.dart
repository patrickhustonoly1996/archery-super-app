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
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/firestore_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const ArcherySuperApp());
}

class ArcherySuperApp extends StatefulWidget {
  const ArcherySuperApp({super.key});

  @override
  State<ArcherySuperApp> createState() => _ArcherySuperAppState();
}

class _ArcherySuperAppState extends State<ArcherySuperApp> {
  AppDatabase? _database;
  String? _initError;
  bool _isInitializing = true;
  String _status = 'Starting...';

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      setState(() => _status = 'Opening database...');
      _database = AppDatabase();

      // Add timeout for web - WASM can hang
      setState(() => _status = 'Loading data...');
      await _database!.getAllRoundTypes().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Database timed out - WASM may have failed to load');
        },
      );

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('Database init error: $e');
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error if database failed
    if (_initError != null) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to initialize database',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(_initError!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initError = null;
                        _isInitializing = true;
                      });
                      _initDatabase();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show loading while initializing
    if (_isInitializing || _database == null) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 16),
                Text(_status, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Provider<AppDatabase>.value(
      value: _database!,
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
        ],
        child: MaterialApp(
          title: 'Archery Super App',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
    // Check cached auth state immediately (works offline)
    _cachedUser = FirebaseAuth.instance.currentUser;

    // Only set timeout if no cached user - need to wait for stream
    if (_cachedUser == null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_hasReceivedData) {
          setState(() => _timedOut = true);
        }
      });
    }

    // Trigger background sync if user is already logged in
    if (_cachedUser != null) {
      _triggerBackgroundSync();
    }
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
        final result = await syncService.restoreAllData(db);
        if (result.totalRestored > 0) {
          debugPrint('Cloud restore completed: ${result.message}');
        }

        // Then backup any local data to cloud
        await syncService.backupAllData(db);
        debugPrint('Background sync completed');
      } catch (e) {
        debugPrint('Background sync error (non-fatal): $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cached user, go straight to home (offline-first)
    if (_cachedUser != null) {
      return const HomeScreen();
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
