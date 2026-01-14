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
import 'breath_training/breath_training_home_screen.dart';
import 'bow_training_screen.dart';
import 'delayed_camera_screen.dart';
import 'performance_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasIncompleteSession = false;
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _introController;
  bool _introComplete = false;

  List<_MenuItem> get _menuItems => [
    if (_hasIncompleteSession)
      _MenuItem(
        label: 'RESUME',
        sublabel: 'Continue round',
        pixelIcon: PixelIconType.resume,
        isHighlight: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlottingScreen()),
          ).then((_) => _refreshIncompleteSession());
        },
      ),
    _MenuItem(
      label: 'SCORE',
      sublabel: 'New session',
      pixelIcon: PixelIconType.target,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SessionStartScreen()),
      ),
    ),
    _MenuItem(
      label: 'HISTORY',
      sublabel: 'Past sessions',
      pixelIcon: PixelIconType.scroll,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      ),
    ),
    _MenuItem(
      label: 'STATS',
      sublabel: 'Trends & data',
      pixelIcon: PixelIconType.chart,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
      ),
    ),
    _MenuItem(
      label: 'PROFILE',
      sublabel: 'Performance radar',
      pixelIcon: PixelIconType.radar,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PerformanceProfileScreen()),
      ),
    ),
    _MenuItem(
      label: 'BOW DRILLS',
      sublabel: 'Timed training',
      pixelIcon: PixelIconType.bow,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BowTrainingScreen()),
      ),
    ),
    _MenuItem(
      label: 'DELAY CAM',
      sublabel: 'Form review',
      pixelIcon: PixelIconType.video,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DelayedCameraScreen()),
      ),
    ),
    _MenuItem(
      label: 'BREATHE',
      sublabel: 'Focus & calm',
      pixelIcon: PixelIconType.lungs,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BreathTrainingHomeScreen()),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _checkForIncompleteSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIncompleteSession();
    }
  }

  void _refreshIncompleteSession() async {
    final provider = context.read<SessionProvider>();
    final hasIncomplete =
        provider.hasActiveSession && !provider.isSessionComplete;
    if (mounted && hasIncomplete != _hasIncompleteSession) {
      setState(() {
        _hasIncompleteSession = hasIncomplete;
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _checkForIncompleteSession() async {
    try {
      final provider = context.read<SessionProvider>();
      final hasIncomplete = await provider
          .checkForIncompleteSession()
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (mounted) {
        setState(() {
          _hasIncompleteSession = hasIncomplete;
          _isLoading = false;
        });
        // Start intro animation
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _introController.forward().then((_) {
              if (mounted) setState(() => _introComplete = true);
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasIncompleteSession = false;
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _introController.forward().then((_) {
              if (mounted) setState(() => _introComplete = true);
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: _PixelLoadingIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Subtle scanlines
          const _ScanlineOverlay(),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(onSettings: () => _showSettingsMenu(context)),

                // Main content area - collapsing header + menu
                Expanded(
                  child: AnimatedBuilder(
                    animation: _introController,
                    builder: (context, _) {
                      final menuOpacity = CurvedAnimation(
                        parent: _introController,
                        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                      );

                      return CustomScrollView(
                        slivers: [
                          // Collapsing logo header
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _CollapsingLogoHeader(
                              pulseController: _pulseController,
                              expandedHeight: 200,
                              collapsedHeight: 56,
                            ),
                          ),

                          // Menu items
                          if (_introComplete)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = _menuItems[index];
                                    final isSelected = index == _selectedIndex;

                                    return FadeTransition(
                                      opacity: menuOpacity,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: _MenuItemWidget(
                                          item: item,
                                          isSelected: isSelected,
                                          pulseController: _pulseController,
                                          onTap: () {
                                            setState(() => _selectedIndex = index);
                                            item.onTap();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: _menuItems.length,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Footer
                if (_introComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'SELECT MODE',
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 8,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RetroBottomSheet(
        children: [
          _RetroSheetItem(
            icon: Icons.file_upload_outlined,
            label: 'IMPORT',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ImportScreen()));
            },
          ),
          _RetroSheetItem(
            icon: Icons.archive_outlined,
            label: 'EQUIPMENT',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EquipmentScreen()));
            },
          ),
          const SizedBox(height: 8),
          _RetroSheetItem(
            icon: Icons.logout,
            label: 'SIGN OUT',
            isDestructive: true,
            onTap: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DATA MODEL
// =============================================================================

enum PixelIconType { resume, target, scroll, chart, bow, lungs, video, radar }

class _MenuItem {
  final String label;
  final String sublabel;
  final PixelIconType pixelIcon;
  final VoidCallback onTap;
  final bool isHighlight;

  const _MenuItem({
    required this.label,
    required this.sublabel,
    required this.pixelIcon,
    required this.onTap,
    this.isHighlight = false,
  });
}

// =============================================================================
// TOP BAR
// =============================================================================

class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;

  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'v1.0.1',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 6,
                color: AppColors.textMuted,
              ),
            ),
          ),
          // Settings
          GestureDetector(
            onTap: onSettings,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.tune,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      color: AppColors.gold,
    );
  }
}

// =============================================================================
// COLLAPSING LOGO HEADER - Smooth scroll-linked collapse effect
// =============================================================================

class _CollapsingLogoHeader extends SliverPersistentHeaderDelegate {
  final AnimationController pulseController;
  final double expandedHeight;
  final double collapsedHeight;

  _CollapsingLogoHeader({
    required this.pulseController,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _CollapsingLogoHeader oldDelegate) =>
      expandedHeight != oldDelegate.expandedHeight ||
      collapsedHeight != oldDelegate.collapsedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Calculate collapse progress (0 = expanded, 1 = collapsed)
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedProgress = 1.0 - progress;

    // Interpolated values
    final iconSize = 64 * (0.5 + (expandedProgress * 0.5)); // 32-64
    final titleSize = 20 * (0.6 + (expandedProgress * 0.4)); // 12-20
    final subtitleOpacity = expandedProgress; // Fades out completely
    final decorationOpacity = expandedProgress * 0.4; // Fades faster
    final verticalPadding = 40 * expandedProgress + 8; // 8-48
    final spacing = 24 * expandedProgress + 4; // 4-28

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final glow = 0.3 + (pulseController.value * 0.3);

        return Container(
          color: AppColors.backgroundDark,
          child: Stack(
            children: [
              // Subtle bottom border when collapsed
              if (progress > 0.5)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 1,
                    color: AppColors.gold.withValues(alpha: (progress - 0.5) * 0.4),
                  ),
                ),

              // Main content
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: verticalPadding),
                  child: progress < 0.85
                      ? _buildExpandedLayout(
                          iconSize: iconSize,
                          titleSize: titleSize,
                          spacing: spacing,
                          subtitleOpacity: subtitleOpacity,
                          decorationOpacity: decorationOpacity,
                          glow: glow,
                        )
                      : _buildCollapsedLayout(glow: glow),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedLayout({
    required double iconSize,
    required double titleSize,
    required double spacing,
    required double subtitleOpacity,
    required double decorationOpacity,
    required double glow,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing arrow icon
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: glow),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _PixelArrowIcon(size: iconSize),
        ),

        SizedBox(height: spacing),

        // ARCHERY title
        Text(
          'ARCHERY',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: titleSize,
            color: AppColors.gold,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: AppColors.gold.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),

        // Decorative line + subtitle (fades out on collapse)
        if (subtitleOpacity > 0.1) ...[
          SizedBox(height: 8 * subtitleOpacity),
          Opacity(
            opacity: subtitleOpacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PixelDot(),
                Container(
                  width: 60 * subtitleOpacity,
                  height: 2,
                  color: AppColors.gold.withValues(alpha: decorationOpacity),
                ),
                const SizedBox(width: 8),
                Text(
                  'SUPER APP',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 8,
                    color: AppColors.textMuted.withValues(alpha: subtitleOpacity),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60 * subtitleOpacity,
                  height: 2,
                  color: AppColors.gold.withValues(alpha: decorationOpacity),
                ),
                _PixelDot(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsedLayout({required double glow}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact icon
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: glow * 0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const _PixelArrowIcon(size: 28),
        ),
        const SizedBox(width: 12),
        // Inline title
        Text(
          'ARCHERY',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: AppColors.gold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 4,
          height: 4,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Text(
          'SUPER APP',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 6,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PIXEL ARROW ICON - Custom painted pixel art
// =============================================================================

class _PixelArrowIcon extends StatelessWidget {
  final double size;

  const _PixelArrowIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelArrowPainter(),
    );
  }
}

class _PixelArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 16;
    final paint = Paint()..color = AppColors.gold;

    // Draw a stylized pixel arrow pointing right
    // Arrow shaft
    for (int x = 2; x <= 12; x++) {
      _drawPixel(canvas, x, 7, pixelSize, paint);
      _drawPixel(canvas, x, 8, pixelSize, paint);
    }

    // Arrow head - top part
    _drawPixel(canvas, 10, 4, pixelSize, paint);
    _drawPixel(canvas, 11, 5, pixelSize, paint);
    _drawPixel(canvas, 12, 6, pixelSize, paint);
    _drawPixel(canvas, 13, 7, pixelSize, paint);
    _drawPixel(canvas, 13, 8, pixelSize, paint);

    // Arrow head - bottom part
    _drawPixel(canvas, 12, 9, pixelSize, paint);
    _drawPixel(canvas, 11, 10, pixelSize, paint);
    _drawPixel(canvas, 10, 11, pixelSize, paint);

    // Fletching at back
    final fletchPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.6);
    _drawPixel(canvas, 2, 5, pixelSize, fletchPaint);
    _drawPixel(canvas, 3, 6, pixelSize, fletchPaint);
    _drawPixel(canvas, 2, 10, pixelSize, fletchPaint);
    _drawPixel(canvas, 3, 9, pixelSize, fletchPaint);

    // Target circle in corner
    final targetPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pixelSize * 0.5;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      pixelSize * 2,
      targetPaint,
    );
  }

  void _drawPixel(Canvas canvas, int x, int y, double pixelSize, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// PIXEL MENU ICONS
// =============================================================================

class _PixelMenuIcon extends StatelessWidget {
  final PixelIconType type;
  final Color color;
  final double size;

  const _PixelMenuIcon({
    required this.type,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelMenuIconPainter(type: type, color: color),
    );
  }
}

class _PixelMenuIconPainter extends CustomPainter {
  final PixelIconType type;
  final Color color;

  _PixelMenuIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 12; // 12x12 grid
    final paint = Paint()..color = color;
    final dimPaint = Paint()..color = color.withValues(alpha: 0.5);

    switch (type) {
      case PixelIconType.resume:
        _drawResume(canvas, p, paint, dimPaint);
      case PixelIconType.target:
        _drawTarget(canvas, p, paint, dimPaint);
      case PixelIconType.scroll:
        _drawScroll(canvas, p, paint, dimPaint);
      case PixelIconType.chart:
        _drawChart(canvas, p, paint, dimPaint);
      case PixelIconType.bow:
        _drawBow(canvas, p, paint, dimPaint);
      case PixelIconType.lungs:
        _drawLungs(canvas, p, paint, dimPaint);
      case PixelIconType.video:
        _drawVideo(canvas, p, paint, dimPaint);
      case PixelIconType.radar:
        _drawRadar(canvas, p, paint, dimPaint);
    }
  }

  // Play/Resume arrow
  void _drawResume(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Play triangle pointing right
    _px(canvas, 3, 2, p, paint);
    _px(canvas, 3, 3, p, paint);
    _px(canvas, 4, 3, p, paint);
    _px(canvas, 3, 4, p, paint);
    _px(canvas, 4, 4, p, paint);
    _px(canvas, 5, 4, p, paint);
    _px(canvas, 3, 5, p, paint);
    _px(canvas, 4, 5, p, paint);
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 6, 5, p, paint);
    _px(canvas, 3, 6, p, paint);
    _px(canvas, 4, 6, p, paint);
    _px(canvas, 5, 6, p, paint);
    _px(canvas, 6, 6, p, paint);
    _px(canvas, 7, 6, p, paint);
    _px(canvas, 3, 7, p, paint);
    _px(canvas, 4, 7, p, paint);
    _px(canvas, 5, 7, p, paint);
    _px(canvas, 6, 7, p, paint);
    _px(canvas, 3, 8, p, paint);
    _px(canvas, 4, 8, p, paint);
    _px(canvas, 5, 8, p, paint);
    _px(canvas, 3, 9, p, paint);
    _px(canvas, 4, 9, p, paint);
    _px(canvas, 3, 10, p, paint);
  }

  // Target/bullseye
  void _drawTarget(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Outer ring
    for (int i = 3; i <= 8; i++) {
      _px(canvas, i, 1, p, dimPaint);
      _px(canvas, i, 10, p, dimPaint);
    }
    for (int i = 3; i <= 8; i++) {
      _px(canvas, 1, i, p, dimPaint);
      _px(canvas, 10, i, p, dimPaint);
    }
    _px(canvas, 2, 2, p, dimPaint);
    _px(canvas, 9, 2, p, dimPaint);
    _px(canvas, 2, 9, p, dimPaint);
    _px(canvas, 9, 9, p, dimPaint);

    // Inner ring
    for (int i = 4; i <= 7; i++) {
      _px(canvas, i, 3, p, paint);
      _px(canvas, i, 8, p, paint);
    }
    _px(canvas, 3, 4, p, paint);
    _px(canvas, 3, 7, p, paint);
    _px(canvas, 8, 4, p, paint);
    _px(canvas, 8, 7, p, paint);

    // Bullseye center
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 6, 5, p, paint);
    _px(canvas, 5, 6, p, paint);
    _px(canvas, 6, 6, p, paint);
  }

  // Scroll/history
  void _drawScroll(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Scroll body
    for (int y = 2; y <= 9; y++) {
      _px(canvas, 3, y, p, paint);
      _px(canvas, 8, y, p, paint);
    }
    // Top curl
    _px(canvas, 4, 1, p, paint);
    _px(canvas, 5, 1, p, paint);
    _px(canvas, 6, 1, p, paint);
    _px(canvas, 7, 1, p, paint);
    _px(canvas, 2, 2, p, dimPaint);
    _px(canvas, 9, 2, p, dimPaint);
    // Bottom curl
    _px(canvas, 4, 10, p, paint);
    _px(canvas, 5, 10, p, paint);
    _px(canvas, 6, 10, p, paint);
    _px(canvas, 7, 10, p, paint);
    _px(canvas, 2, 9, p, dimPaint);
    _px(canvas, 9, 9, p, dimPaint);
    // Text lines
    _px(canvas, 4, 4, p, dimPaint);
    _px(canvas, 5, 4, p, dimPaint);
    _px(canvas, 6, 4, p, dimPaint);
    _px(canvas, 4, 6, p, dimPaint);
    _px(canvas, 5, 6, p, dimPaint);
    _px(canvas, 6, 6, p, dimPaint);
    _px(canvas, 7, 6, p, dimPaint);
    _px(canvas, 4, 8, p, dimPaint);
    _px(canvas, 5, 8, p, dimPaint);
  }

  // Bar chart
  void _drawChart(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Axes
    for (int y = 1; y <= 10; y++) {
      _px(canvas, 1, y, p, dimPaint);
    }
    for (int x = 1; x <= 10; x++) {
      _px(canvas, x, 10, p, dimPaint);
    }
    // Bars
    for (int y = 7; y <= 9; y++) {
      _px(canvas, 3, y, p, paint);
    }
    for (int y = 4; y <= 9; y++) {
      _px(canvas, 5, y, p, paint);
    }
    for (int y = 5; y <= 9; y++) {
      _px(canvas, 7, y, p, paint);
    }
    for (int y = 2; y <= 9; y++) {
      _px(canvas, 9, y, p, paint);
    }
  }

  // Recurve bow
  void _drawBow(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Bow limbs (curved)
    _px(canvas, 2, 1, p, paint);
    _px(canvas, 3, 2, p, paint);
    _px(canvas, 3, 3, p, paint);
    _px(canvas, 2, 4, p, paint);
    _px(canvas, 2, 5, p, paint);
    _px(canvas, 2, 6, p, paint);
    _px(canvas, 2, 7, p, paint);
    _px(canvas, 2, 8, p, paint);
    _px(canvas, 3, 9, p, paint);
    _px(canvas, 3, 10, p, paint);
    _px(canvas, 2, 11, p, paint);
    // Bow string
    for (int y = 1; y <= 11; y++) {
      _px(canvas, 4, y, p, dimPaint);
    }
    // Arrow on string
    for (int x = 5; x <= 9; x++) {
      _px(canvas, x, 6, p, paint);
    }
    // Arrow head
    _px(canvas, 10, 5, p, paint);
    _px(canvas, 10, 6, p, paint);
    _px(canvas, 10, 7, p, paint);
  }

  // Lungs/breathing
  void _drawLungs(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Trachea
    _px(canvas, 5, 1, p, paint);
    _px(canvas, 6, 1, p, paint);
    _px(canvas, 5, 2, p, paint);
    _px(canvas, 6, 2, p, paint);
    // Bronchi split
    _px(canvas, 4, 3, p, dimPaint);
    _px(canvas, 5, 3, p, paint);
    _px(canvas, 6, 3, p, paint);
    _px(canvas, 7, 3, p, dimPaint);
    // Left lung
    _px(canvas, 2, 4, p, paint);
    _px(canvas, 3, 4, p, paint);
    _px(canvas, 4, 4, p, paint);
    _px(canvas, 1, 5, p, paint);
    _px(canvas, 2, 5, p, paint);
    _px(canvas, 3, 5, p, paint);
    _px(canvas, 4, 5, p, paint);
    _px(canvas, 1, 6, p, paint);
    _px(canvas, 2, 6, p, paint);
    _px(canvas, 3, 6, p, paint);
    _px(canvas, 4, 6, p, paint);
    _px(canvas, 1, 7, p, paint);
    _px(canvas, 2, 7, p, paint);
    _px(canvas, 3, 7, p, paint);
    _px(canvas, 4, 7, p, paint);
    _px(canvas, 2, 8, p, paint);
    _px(canvas, 3, 8, p, paint);
    _px(canvas, 4, 8, p, paint);
    _px(canvas, 3, 9, p, dimPaint);
    // Right lung
    _px(canvas, 7, 4, p, paint);
    _px(canvas, 8, 4, p, paint);
    _px(canvas, 9, 4, p, paint);
    _px(canvas, 7, 5, p, paint);
    _px(canvas, 8, 5, p, paint);
    _px(canvas, 9, 5, p, paint);
    _px(canvas, 10, 5, p, paint);
    _px(canvas, 7, 6, p, paint);
    _px(canvas, 8, 6, p, paint);
    _px(canvas, 9, 6, p, paint);
    _px(canvas, 10, 6, p, paint);
    _px(canvas, 7, 7, p, paint);
    _px(canvas, 8, 7, p, paint);
    _px(canvas, 9, 7, p, paint);
    _px(canvas, 10, 7, p, paint);
    _px(canvas, 7, 8, p, paint);
    _px(canvas, 8, 8, p, paint);
    _px(canvas, 9, 8, p, paint);
    _px(canvas, 8, 9, p, dimPaint);
  }

  // Video camera icon
  void _drawVideo(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Camera body (rectangle)
    for (int x = 1; x <= 7; x++) {
      _px(canvas, x, 3, p, paint);
      _px(canvas, x, 9, p, paint);
    }
    for (int y = 3; y <= 9; y++) {
      _px(canvas, 1, y, p, paint);
      _px(canvas, 7, y, p, paint);
    }
    // Camera body fill
    for (int x = 2; x <= 6; x++) {
      for (int y = 4; y <= 8; y++) {
        _px(canvas, x, y, p, dimPaint);
      }
    }
    // Lens circle
    _px(canvas, 3, 5, p, paint);
    _px(canvas, 4, 5, p, paint);
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 3, 6, p, paint);
    _px(canvas, 5, 6, p, paint);
    _px(canvas, 3, 7, p, paint);
    _px(canvas, 4, 7, p, paint);
    _px(canvas, 5, 7, p, paint);
    // Viewfinder triangle (pointing right)
    _px(canvas, 8, 4, p, paint);
    _px(canvas, 8, 5, p, paint);
    _px(canvas, 9, 5, p, paint);
    _px(canvas, 8, 6, p, paint);
    _px(canvas, 9, 6, p, paint);
    _px(canvas, 10, 6, p, paint);
    _px(canvas, 8, 7, p, paint);
    _px(canvas, 9, 7, p, paint);
    _px(canvas, 8, 8, p, paint);
    // Recording indicator dot
    _px(canvas, 6, 4, p, paint);
  }

  // Radar/spider chart
  void _drawRadar(Canvas canvas, double p, Paint paint, Paint dimPaint) {
    // Pentagon outline (5 axes)
    // Top vertex
    _px(canvas, 5, 1, p, dimPaint);
    _px(canvas, 6, 1, p, dimPaint);
    // Top-right edge
    _px(canvas, 8, 2, p, dimPaint);
    _px(canvas, 9, 3, p, dimPaint);
    _px(canvas, 10, 4, p, dimPaint);
    _px(canvas, 10, 5, p, dimPaint);
    // Bottom-right edge
    _px(canvas, 9, 7, p, dimPaint);
    _px(canvas, 8, 8, p, dimPaint);
    _px(canvas, 7, 9, p, dimPaint);
    // Bottom-left edge
    _px(canvas, 4, 9, p, dimPaint);
    _px(canvas, 3, 8, p, dimPaint);
    _px(canvas, 2, 7, p, dimPaint);
    // Top-left edge
    _px(canvas, 1, 5, p, dimPaint);
    _px(canvas, 1, 4, p, dimPaint);
    _px(canvas, 2, 3, p, dimPaint);
    _px(canvas, 3, 2, p, dimPaint);
    // Axis lines from center
    _px(canvas, 5, 3, p, paint);
    _px(canvas, 5, 4, p, paint);
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 6, 3, p, paint);
    _px(canvas, 6, 4, p, paint);
    _px(canvas, 6, 5, p, paint);
    // Axis to bottom-right
    _px(canvas, 7, 6, p, paint);
    _px(canvas, 8, 7, p, paint);
    // Axis to bottom-left
    _px(canvas, 4, 6, p, paint);
    _px(canvas, 3, 7, p, paint);
    // Axis to top-right
    _px(canvas, 7, 4, p, paint);
    _px(canvas, 8, 3, p, paint);
    // Axis to top-left
    _px(canvas, 4, 4, p, paint);
    _px(canvas, 3, 3, p, paint);
    // Center dot
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 6, 5, p, paint);
    _px(canvas, 5, 6, p, paint);
    _px(canvas, 6, 6, p, paint);
  }

  void _px(Canvas canvas, int x, int y, double p, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelMenuIconPainter oldDelegate) =>
      type != oldDelegate.type || color != oldDelegate.color;
}

// =============================================================================
// MENU ITEM WIDGET
// =============================================================================

class _MenuItemWidget extends StatelessWidget {
  final _MenuItem item;
  final bool isSelected;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _MenuItemWidget({
    required this.item,
    required this.isSelected,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final glowAlpha = item.isHighlight
            ? 0.2 + (pulseController.value * 0.15)
            : (isSelected ? 0.1 : 0.0);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border.all(
                color: item.isHighlight
                    ? AppColors.gold
                    : (isSelected
                        ? AppColors.gold.withValues(alpha: 0.5)
                        : AppColors.surfaceLight),
                width: item.isHighlight ? 2 : 1,
              ),
              boxShadow: glowAlpha > 0
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: glowAlpha),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Selection indicator bar
                Container(
                  width: 3,
                  height: 28,
                  color: isSelected || item.isHighlight
                      ? AppColors.gold
                      : Colors.transparent,
                ),
                const SizedBox(width: 12),

                // Pixel icon box
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: item.isHighlight
                          ? AppColors.gold.withValues(alpha: 0.5)
                          : AppColors.surfaceLight,
                    ),
                  ),
                  child: Center(
                    child: _PixelMenuIcon(
                      type: item.pixelIcon,
                      color: item.isHighlight || isSelected
                          ? AppColors.gold
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 10,
                          color: item.isHighlight || isSelected
                              ? AppColors.gold
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.sublabel,
                        style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Text(
                  '>',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 12,
                    color: isSelected || item.isHighlight
                        ? AppColors.gold
                        : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// LOADING INDICATOR
// =============================================================================

class _PixelLoadingIndicator extends StatefulWidget {
  const _PixelLoadingIndicator();

  @override
  State<_PixelLoadingIndicator> createState() => _PixelLoadingIndicatorState();
}

class _PixelLoadingIndicatorState extends State<_PixelLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LOADING',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final dots = (_controller.value * 4).floor();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: i < dots ? AppColors.gold : AppColors.surfaceLight,
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// SCANLINE OVERLAY
// =============================================================================

class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanlinePainter(),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// BOTTOM SHEET
// =============================================================================

class _RetroBottomSheet extends StatelessWidget {
  final List<Widget> children;

  const _RetroBottomSheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pixel-style handle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: AppColors.gold.withValues(alpha: 0.4),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'OPTIONS',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 10,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _RetroSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _RetroSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 9,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
