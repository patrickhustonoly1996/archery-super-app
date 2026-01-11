import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/auth_service.dart';
import 'session_start_screen.dart';
import 'plotting_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'import_screen.dart';
import 'equipment_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasIncompleteSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForIncompleteSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshIncompleteSession();
    }
  }

  /// Called when navigating back to this screen
  void _refreshIncompleteSession() async {
    final provider = context.read<SessionProvider>();
    final hasIncomplete = provider.hasActiveSession && !provider.isSessionComplete;
    if (mounted && hasIncomplete != _hasIncompleteSession) {
      setState(() {
        _hasIncompleteSession = hasIncomplete;
      });
    }
  }

  Future<void> _checkForIncompleteSession() async {
    try {
      final provider = context.read<SessionProvider>();
      final hasIncomplete = await provider.checkForIncompleteSession()
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (mounted) {
        setState(() {
          _hasIncompleteSession = hasIncomplete;
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error (e.g., web DB init failure), just show home screen
      if (mounted) {
        setState(() {
          _hasIncompleteSession = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.backgroundDark,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archery',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Super App',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surfaceDark),

              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(
                      icon: Icons.file_upload_outlined,
                      label: 'Import Scores',
                      onTap: () {
                        Navigator.pop(context); // Close drawer first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImportScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.archive_outlined,
                      label: 'Equipment',
                      onTap: () {
                        Navigator.pop(context); // Close drawer first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EquipmentScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Footer
              const Divider(color: AppColors.surfaceDark),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.textMuted, size: 20),
                title: Text(
                  'Sign out',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close drawer first
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archery',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Super App',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Main actions
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Resume Session button (shown when incomplete session exists)
                    if (_hasIncompleteSession)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _HomeButton(
                          icon: Icons.play_arrow,
                          label: 'Resume Session',
                          description: 'Continue your in-progress round',
                          highlight: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlottingScreen(),
                              ),
                            ).then((_) => _refreshIncompleteSession());
                          },
                        ),
                      ),

                    // New Session button
                    _HomeButton(
                      icon: Icons.add_circle_outline,
                      label: 'New Session',
                      description: 'Start scoring a round',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SessionStartScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // History button
                    _HomeButton(
                      icon: Icons.history,
                      label: 'History',
                      description: 'View past sessions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Statistics button
                    _HomeButton(
                      icon: Icons.show_chart,
                      label: 'Statistics',
                      description: 'Training volume & trends',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool highlight;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppColors.gold.withOpacity(0.15) : AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: highlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(color: AppColors.gold, width: 1),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(highlight ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: onTap,
    );
  }
}
