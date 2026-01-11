import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'db/database.dart';
import 'theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'providers/equipment_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

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
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _timedOut = false;
  bool _hasReceivedData = false;

  @override
  void initState() {
    super.initState();
    // Timeout after 3 seconds - if auth check hangs, show login
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasReceivedData) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

        // User is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // User is not logged in (or timed out)
        return const LoginScreen();
      },
    );
  }
}
