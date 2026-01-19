import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../db/database.dart';
import 'bow_training_screen.dart';

/// Library screen for browsing all session templates - lazy loaded
class BowTrainingLibraryScreen extends StatefulWidget {
  const BowTrainingLibraryScreen({super.key});

  @override
  State<BowTrainingLibraryScreen> createState() =>
      _BowTrainingLibraryScreenState();
}

class _BowTrainingLibraryScreenState extends State<BowTrainingLibraryScreen> {
  List<OlySessionTemplate> _sessions = [];
  Map<String, OlyExerciseType> _exerciseTypes = {};
  UserTrainingProgressData? _userProgress;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  /// Load the full session library - only when this screen is opened
  Future<void> _loadLibrary() async {
    final db = context.read<AppDatabase>();

    // Ensure data exists
    await db.ensureOlyTrainingDataExists();

    final sessions = await db.getAllOlySessionTemplates();
    final exerciseTypes = await db.getAllOlyExerciseTypes();
    final progress = await db.getUserTrainingProgress();

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _exerciseTypes = {for (var et in exerciseTypes) et.id: et};
        _userProgress = progress;
        _isLoading = false;
      });
    }
  }

  List<OlySessionTemplate> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    final query = _searchQuery.toLowerCase();
    return _sessions.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.version.contains(query) ||
          (s.focus?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Map<String, List<OlySessionTemplate>> get _sessionsByLevel {
    final grouped = <String, List<OlySessionTemplate>>{};
    for (final session in _filteredSessions) {
      final level = session.version.split('.').first;
      grouped.putIfAbsent('Level $level', () => []).add(session);
    }
    return grouped;
  }

  void _startSession(OlySessionTemplate session) async {
    final provider = context.read<BowTrainingProvider>();
    await provider.startSession(session);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BowTrainingScreen(initialSession: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Library'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search sessions...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.gold),
                        SizedBox(height: AppSpacing.md),
                        Text('Loading session library...'),
                      ],
                    ),
                  )
                : _sessions.isEmpty
                    ? _EmptyLibrary()
                    : _SessionLibraryList(
                        sessionsByLevel: _sessionsByLevel,
                        suggestedVersion: _userProgress?.currentLevel,
                        onStartSession: _startSession,
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No sessions available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _SessionLibraryList extends StatelessWidget {
  final Map<String, List<OlySessionTemplate>> sessionsByLevel;
  final String? suggestedVersion;
  final Function(OlySessionTemplate) onStartSession;

  const _SessionLibraryList({
    required this.sessionsByLevel,
    required this.suggestedVersion,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final levels = sessionsByLevel.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final sessions = sessionsByLevel[level]!;

        return _LevelSection(
          levelName: level,
          sessions: sessions,
          suggestedVersion: suggestedVersion,
          onStartSession: onStartSession,
          initiallyExpanded: sessions.any((s) => s.version == suggestedVersion),
        );
      },
    );
  }
}

class _LevelSection extends StatefulWidget {
  final String levelName;
  final List<OlySessionTemplate> sessions;
  final String? suggestedVersion;
  final Function(OlySessionTemplate) onStartSession;
  final bool initiallyExpanded;

  const _LevelSection({
    required this.levelName,
    required this.sessions,
    required this.suggestedVersion,
    required this.onStartSession,
    this.initiallyExpanded = false,
  });

  @override
  State<_LevelSection> createState() => _LevelSectionState();
}

class _LevelSectionState extends State<_LevelSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.levelName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${widget.sessions.length} sessions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          ...widget.sessions.map((session) => _SessionTile(
                session: session,
                isRecommended: session.version == widget.suggestedVersion,
                onTap: () => widget.onStartSession(session),
              )),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final OlySessionTemplate session;
  final bool isRecommended;
  final VoidCallback onTap;

  const _SessionTile({
    required this.session,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isRecommended
          ? AppColors.gold.withValues(alpha: 0.1)
          : AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        side: isRecommended
            ? BorderSide(color: AppColors.gold.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Version badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRecommended
                      ? AppColors.gold.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Center(
                  child: Text(
                    session.version,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isRecommended
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.name,
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: isRecommended
                                          ? AppColors.gold
                                          : AppColors.textPrimary,
                                    ),
                          ),
                        ),
                        if (isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEXT',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    if (session.focus != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.focus!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Duration and play
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.durationMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isRecommended
                              ? AppColors.gold
                              : AppColors.textSecondary,
                        ),
                  ),
                  Icon(
                    Icons.play_arrow,
                    color: isRecommended ? AppColors.gold : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
