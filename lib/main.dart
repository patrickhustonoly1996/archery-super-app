import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'providers/field_course_provider.dart';
import 'providers/field_session_provider.dart';
import 'services/vision_api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/sync_service.dart';
import 'services/weather_service.dart';
import 'config/app_secrets.dart';
import 'widgets/splash_branding.dart';
import 'widgets/level_up_celebration.dart';

/// Global scaffold messenger key for showing snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Global Firebase init future - AuthGate awaits this with timeout
late final Future<FirebaseApp> firebaseInitFuture;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Firebase initialization (don't await - let app render while it loads)
  // AuthGate will await this with a timeout for offline resilience
  // On web, also set persistence to LOCAL so PWA sessions survive browser restart
  firebaseInitFuture = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((app) async {
    if (kIsWeb) {
      // Ensure Firebase Auth persists sessions in IndexedDB for PWA
      // Without this, sessions may not survive PWA restarts
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
    return app;
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
  void initState() {
    super.initState();
    // Initialize SyncService singleton with database reference
    SyncService().initialize(_database);
    // Initialize weather API for sightmark conditions
    // Key passed via: --dart-define=WEATHER_API_KEY=your_key
    if (AppSecrets.hasWeatherKey) {
      WeatherService.setApiKey(AppSecrets.weatherApiKey);
    }
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
            // Defer loading - not needed for home screen
            create: (context) => ActiveSessionsProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => SpiderGraphProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) => ConnectivityProvider(),
          ),
          ChangeNotifierProvider(
            // Defer loading - badges show default values until loaded
            create: (context) => SkillsProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) => SightMarksProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            // Defer initialization - only needed when using auto-plot
            create: (context) {
              final visionService = VisionApiService();
              return AutoPlotProvider(context.read<AppDatabase>(), visionService);
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
          ChangeNotifierProvider(
            create: (context) => FieldCourseProvider(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider(
            create: (context) => FieldSessionProvider(context.read<AppDatabase>()),
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
                // Apply accessibility settings
                // Only override text scaling if user chose a manual option
                // Otherwise, follow the system's text size setting
                final mediaQuery = MediaQuery.of(context);
                final customScale = accessibility.textScaleFactor;
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    // Only override if not using system scaling
                    textScaler: customScale != null
                        ? TextScaler.linear(customScale)
                        : null, // null = keep system setting
                    boldText: accessibility.boldText,
                    disableAnimations: accessibility.reduceMotion,
                  ),
                  child: child!,
                );
              },
              home: const CelebrationListener(child: AuthGate()),
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

  // Auth state - starts unknown, determined by _checkAuthState
  bool _isInitializing = true; // Show splash until auth state is determined
  bool _wasLoggedIn = false; // Local flag for offline resilience
  User? _cachedUser;
  bool _firebaseReady = false;

  // Navigation state
  bool _homeScreenShown = false; // Once true, never show splash again this session

  // Sync state
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
  /// Only sync when going to background (paused/inactive) to save pending data.
  /// Don't sync on resume - that's wasteful. Data-driven sync happens in
  /// providers when data is actually created/modified.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_wasLoggedIn) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // Coming back to foreground - no sync needed
        // Data-driven sync happens when data is created/modified
        debugPrint('Lifecycle: resumed');
        break;

      case AppLifecycleState.paused:
        // Going to background - CRITICAL: sync to save any pending data
        // This protects against OS killing the app while backgrounded
        debugPrint('Lifecycle: paused - syncing pending data');
        _triggerBackgroundSync(urgent: true);
        break;

      case AppLifecycleState.inactive:
        // Phone call, control center, etc
        // App might be killed after this, so save pending data now
        debugPrint('Lifecycle: inactive - syncing pending data');
        _triggerBackgroundSync(urgent: true);
        break;

      case AppLifecycleState.hidden:
        // App hidden but still running (desktop/web) - no sync needed
        debugPrint('Lifecycle: hidden');
        break;

      case AppLifecycleState.detached:
        // Engine detaching - too late to sync
        debugPrint('Lifecycle: detached');
        break;
    }
  }

  Future<void> _checkAuthState() async {
    // FAST PATH: Load local flag first - this is instant and works offline
    final prefs = await SharedPreferences.getInstance();
    _wasLoggedIn = prefs.getBool(_wasLoggedInKey) ?? false;

    // If user was previously logged in, go straight to home - no Firebase wait
    // This is the key to instant startup for returning users
    if (_wasLoggedIn) {
      _isInitializing = false;
      if (mounted) setState(() {});
      _verifyAuthInBackground(prefs);
      return;
    }

    // User wasn't logged in before - check Firebase (with short timeout)
    try {
      await firebaseInitFuture.timeout(
        const Duration(milliseconds: 300), // Reduced from 500ms
        onTimeout: () => throw TimeoutException('Firebase init timed out'),
      );
      _firebaseReady = true;
      _cachedUser = FirebaseAuth.instance.currentUser;

      // If Firebase has a cached session, use it
      if (_cachedUser != null) {
        await prefs.setBool(_wasLoggedInKey, true);
        _wasLoggedIn = true;
        _triggerBackgroundSync();
      }
    } catch (e) {
      // Firebase slow/offline - that's fine, show login
      debugPrint('Firebase init timed out: $e');
      _firebaseReady = false;
    }

    // Done initializing - show appropriate screen
    _isInitializing = false;
    if (mounted) setState(() {});
  }

  /// Persist "was logged in" flag to SharedPreferences
  /// Called when user successfully authenticates via StreamBuilder
  /// This ensures they don't have to re-login when Firebase is slow on restart
  void _persistLoginFlag() {
    if (_wasLoggedIn) return; // Already set, skip
    _wasLoggedIn = true;

    // Persist asynchronously - don't block UI
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_wasLoggedInKey, true);
      debugPrint('Login flag persisted - user will stay logged in');
    });
  }

  /// Verify auth state in background after showing home screen
  /// Uses auth state listener instead of one-time check to handle async session restore
  void _verifyAuthInBackground(SharedPreferences prefs) {
    Future.microtask(() async {
      try {
        await firebaseInitFuture.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Firebase init timed out during verification');
          },
        );

        _firebaseReady = true;

        // Listen to auth state changes instead of checking currentUser once
        // Firebase Auth may need time to restore session from keychain/storage
        // We give it up to 5 seconds to emit an authenticated state
        final completer = Completer<User?>();
        StreamSubscription<User?>? subscription;

        subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
          if (!completer.isCompleted) {
            completer.complete(user);
            subscription?.cancel();
          }
        });

        // Also check currentUser immediately in case it's already available
        final immediateUser = FirebaseAuth.instance.currentUser;
        if (immediateUser != null && !completer.isCompleted) {
          completer.complete(immediateUser);
          subscription.cancel();
        }

        // Wait for auth state with timeout
        final user = await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            subscription?.cancel();
            // Timeout means Firebase couldn't confirm auth state
            // Keep local flag - user is likely offline or session is still restoring
            debugPrint('Auth state listener timed out - keeping local flag');
            return null;
          },
        );

        if (user != null) {
          // User is confirmed logged in - trigger sync
          _cachedUser = user;
          _triggerBackgroundSync();
          debugPrint('Auth verified: user ${user.uid} is logged in');
        } else {
          // No user after waiting - but DON'T clear flag automatically
          // The user could be offline, or Firebase could be having issues
          // Only clear flag if user explicitly logs out (via AuthService.signOut)
          debugPrint('Auth verification: no user found, but keeping local flag for resilience');
          // Note: We used to clear the flag here, but this caused users to be
          // signed out unexpectedly when Firebase was slow to restore sessions.
          // Now we only clear the flag on explicit logout.
        }
      } on TimeoutException {
        // Firebase timed out - don't clear flag, user might just be offline
        debugPrint('Background auth verification timed out - keeping local flag');
      } catch (e) {
        // Don't clear flag on errors - user might be offline
        debugPrint('Background auth verification failed: $e - keeping local flag');
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
          // Always reset syncing state - the provider is global and persists
          // even if this widget unmounts during sync
          connectivityProvider.setSyncing(false);
        }
      } catch (e) {
        // Firebase not initialized (tests) or other initialization error
        debugPrint('Background sync skipped: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PHASE 1: Show splash while determining auth state
    // This prevents any visual jumping - one clean transition
    if (_isInitializing) {
      return const SplashBranding();
    }

    // PHASE 2: Once home shown, stay there (prevents splash on navigation)
    if (_homeScreenShown) {
      // Unless user explicitly logged out
      if (_cachedUser == null && !_wasLoggedIn) {
        _homeScreenShown = false;
        return const LoginScreen();
      }
      return const HomeScreen();
    }

    // PHASE 3: Returning user - instant home screen
    if (_wasLoggedIn || _cachedUser != null) {
      _homeScreenShown = true;
      return const HomeScreen();
    }

    // PHASE 4: New user or fresh login - use StreamBuilder for auth changes
    if (_firebaseReady) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // User just logged in
            _persistLoginFlag();
            _triggerBackgroundSync();
            _homeScreenShown = true;
            return const HomeScreen();
          }
          // Not logged in yet
          return const LoginScreen();
        },
      );
    }

    // PHASE 5: Firebase not ready, no cached login - show login
    return const LoginScreen();
  }
}
