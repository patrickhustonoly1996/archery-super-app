import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
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
import 'providers/skills_provider.dart';
import 'providers/sight_marks_provider.dart';
import 'providers/auto_plot_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/entitlement_provider.dart';
import 'providers/classification_provider.dart';
import 'providers/accessibility_provider.dart';
import 'providers/locale_provider.dart';
import 'services/vision_api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/sync_service.dart';
import 'widgets/splash_branding.dart';

/// Global scaffold messenger key for showing snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Global Firebase init future - AuthGate awaits this with timeout
late final Future<FirebaseApp> firebaseInitFuture;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Firebase initialization (don't await - let app render while it loads)
  // AuthGate will await this with a timeout for offline resilience
  firebaseInitFuture = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  void initState() {
    super.initState();
    // Initialize SyncService singleton with database reference
    SyncService().initialize(_database);
  }

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
          ChangeNotifierProvider(
            create: (context) =>
                SkillsProvider(context.read<AppDatabase>())..loadSkills(),
          ),
          ChangeNotifierProvider(
            create: (context) => SightMarksProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) {
              // VisionApiService uses Firebase Functions backend - no API key needed
              final visionService = VisionApiService();
              return AutoPlotProvider(context.read<AppDatabase>(), visionService)
                ..initialize();
            },
          ),
          ChangeNotifierProvider(
            create: (context) =>
                UserProfileProvider(context.read<AppDatabase>())..loadProfile(),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                EntitlementProvider(context.read<AppDatabase>())..loadEntitlement(),
          ),
          ChangeNotifierProvider(
            create: (context) => ClassificationProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) => AccessibilityProvider()..loadSettings(),
          ),
          ChangeNotifierProvider(
            create: (context) => LocaleProvider()..initialize(),
          ),
        ],
        child: Consumer2<AccessibilityProvider, LocaleProvider>(
          builder: (context, accessibility, localeProvider, child) {
            return MaterialApp(
              title: 'Archery Super App',
              theme: AppTheme.darkTheme,
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: scaffoldMessengerKey,
              // Localization configuration
              locale: localeProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: SupportedLocales.all,
              builder: (context, child) {
                // Apply text scaling from accessibility settings
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(accessibility.textScaleFactor),
                    boldText: accessibility.boldText,
                    disableAnimations: accessibility.reduceMotion,
                  ),
                  child: child!,
                );
              },
              home: const AuthGate(),
            );
          },
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

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  static const String _wasLoggedInKey = 'was_logged_in';
  static const Duration _syncDebounce = Duration(seconds: 30); // Don't sync more often than this

  bool _timedOut = false;
  bool _hasReceivedData = false;
  User? _cachedUser;
  bool _firebaseReady = false;
  bool _wasLoggedIn = false; // Local flag for offline resilience
  DateTime? _lastSyncAttempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Sync on app lifecycle changes for robust data persistence
  ///
  /// - resumed: User switches back to app - sync to get latest from cloud
  /// - paused: App going to background - sync to save pending data
  /// - inactive: Phone call, control center, etc - trigger quick sync
  /// - hidden: App hidden but running - sync to preserve data
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_wasLoggedIn) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // Coming back to foreground - sync to get latest data
        debugPrint('Lifecycle: resumed - triggering sync');
        _triggerBackgroundSync();
        break;

      case AppLifecycleState.paused:
        // Going to background - CRITICAL: sync to save any pending data
        // This protects against OS killing the app while backgrounded
        debugPrint('Lifecycle: paused - triggering sync to save pending data');
        _triggerBackgroundSync(urgent: true);
        break;

      case AppLifecycleState.inactive:
        // Phone call, control center, etc - trigger sync
        // App might be killed after this, so save data now
        debugPrint('Lifecycle: inactive - triggering sync');
        _triggerBackgroundSync(urgent: true);
        break;

      case AppLifecycleState.hidden:
        // App hidden but still running (desktop/web)
        debugPrint('Lifecycle: hidden - triggering sync');
        _triggerBackgroundSync();
        break;

      case AppLifecycleState.detached:
        // Engine detaching - too late to sync
        debugPrint('Lifecycle: detached - cannot sync');
        break;
    }
  }

  Future<void> _checkAuthState() async {
    // Load local "was logged in" flag first (instant, works offline)
    final prefs = await SharedPreferences.getInstance();
    _wasLoggedIn = prefs.getBool(_wasLoggedInKey) ?? false;

    // If user was previously logged in, go straight to home - no Firebase wait
    // Firebase will verify in background and update the flag if needed
    if (_wasLoggedIn) {
      if (mounted) setState(() {});
      _verifyAuthInBackground(prefs);
      return;
    }

    // User wasn't logged in - need to wait for Firebase to authenticate
    try {
      await firebaseInitFuture.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          throw TimeoutException('Firebase init timed out');
        },
      );
      _cachedUser = FirebaseAuth.instance.currentUser;
      _firebaseReady = true;

      // If logged in now, update flag and go to home
      if (_cachedUser != null) {
        await prefs.setBool(_wasLoggedInKey, true);
        _wasLoggedIn = true;
        _triggerBackgroundSync();
        if (mounted) setState(() {});
        return;
      }
    } catch (e) {
      // Firebase didn't initialize in time (likely offline or slow network)
      debugPrint('Firebase init failed/timed out: $e');
      _firebaseReady = false;
    }

    // No cached user and Firebase isn't ready - show login
    if (!_firebaseReady) {
      if (mounted) setState(() => _timedOut = true);
      return;
    }

    // Firebase is ready but no cached user - wait briefly for auth stream
    // (handles fresh login completion)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_hasReceivedData) {
        setState(() => _timedOut = true);
      }
    });
  }

  /// Verify auth state in background after showing home screen
  /// Updates local flag if Firebase says user is actually logged out
  void _verifyAuthInBackground(SharedPreferences prefs) {
    Future.microtask(() async {
      try {
        await firebaseInitFuture;
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // User is still logged in - trigger sync
          _cachedUser = user;
          _firebaseReady = true;
          _triggerBackgroundSync();
        } else {
          // Firebase says not logged in - user probably logged out elsewhere
          // Update flag but don't kick them out mid-session
          await prefs.setBool(_wasLoggedInKey, false);
          debugPrint('Auth state mismatch: local=true, firebase=false');
        }
      } catch (e) {
        debugPrint('Background auth verification failed: $e');
      }
    });
  }

  /// Trigger bidirectional sync with cloud
  /// Merges local and cloud data so both have the same complete dataset
  /// Non-blocking, debounced, and skipped when offline
  ///
  /// [urgent] - If true, skips debounce and syncs immediately.
  ///            Use for critical moments like app going to background.
  void _triggerBackgroundSync({bool urgent = false}) {
    // Debounce: don't sync too frequently (unless urgent)
    if (!urgent &&
        _lastSyncAttempt != null &&
        DateTime.now().difference(_lastSyncAttempt!) < _syncDebounce) {
      debugPrint('Skipping sync: debounce active');
      return;
    }

    final syncService = SyncService();

    // SyncService handles its own mutex lock, but we still debounce here
    // For urgent syncs, we queue it even if already syncing (will be picked up after)
    if (!urgent && syncService.isSyncing) {
      debugPrint('Skipping sync: already syncing');
      return;
    }

    _lastSyncAttempt = DateTime.now();

    // Run sync in background without blocking UI
    Future.microtask(() async {
      if (!mounted) return;

      try {
        final connectivityProvider = context.read<ConnectivityProvider>();

        // Only sync if we're online
        if (!connectivityProvider.isOnline) {
          debugPrint('Skipping sync: device is offline');
          return;
        }

        // Only sync if authenticated
        if (!syncService.isAuthenticated) {
          debugPrint('Skipping sync: not authenticated');
          return;
        }

        connectivityProvider.setSyncing(true);

        try {
          final result = await syncService.syncAll();

          // If we downloaded data, refresh relevant providers
          if (result.downloaded > 0 && mounted) {
            debugPrint('Sync downloaded ${result.downloaded} items, refreshing providers');
            // Refresh equipment and sessions providers so UI shows new data
            context.read<EquipmentProvider>().loadEquipment();
            context.read<ActiveSessionsProvider>().loadSessions();
          }

          if (result.totalSynced > 0) {
            debugPrint('Sync completed: ${result.message} (↓${result.downloaded} ↑${result.uploaded})');
          } else if (!result.alreadySyncing) {
            debugPrint('Sync completed: already in sync');
          }
        } catch (e) {
          debugPrint('Sync error: $e');
          // Don't show error snackbar for routine sync failures
          // The user can retry by reopening the app
        } finally {
          if (mounted) {
            connectivityProvider.setSyncing(false);
          }
        }
      } catch (e) {
        // Firebase not initialized (tests) or other initialization error
        debugPrint('Background sync skipped: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cached user from Firebase, go straight to home
    if (_cachedUser != null) {
      return const HomeScreen();
    }

    // Offline mode: Firebase isn't ready but user was previously logged in
    // Trust local flag and show home screen
    if (!_firebaseReady && _wasLoggedIn) {
      return const HomeScreen();
    }

    // If Firebase isn't ready or timed out, show login
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

        // Show branded splash while checking auth state (with timeout)
        if (!_hasReceivedData && !_timedOut) {
          return const SplashBranding();
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
