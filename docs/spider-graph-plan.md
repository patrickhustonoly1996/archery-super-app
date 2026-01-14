# Spider Graph Implementation Plan

## Overview
Build a radar/spider chart visualization showing holistic development across 8 training dimensions. The graph normalizes each metric to 0-100% based on Patrick's personal targets.

## Target Definitions

| Spoke | Metric | 100% Target | Elite Target | Data Source |
|-------|--------|-------------|--------------|-------------|
| Score Level | Best handicap in period | Handicap 1 | - | Sessions, ImportedScores |
| Training Volume | Arrows per week | 600/week | 800/week | VolumeEntries |
| Training Frequency | Days trained per week | 7 days | - | All session tables |
| Bow Fitness | Hold time per week | 20 min/week | 37 min/week | OlyTrainingLogs |
| Form Quality | Structure feedback (inverted) | Score ≤2 | - | OlyTrainingLogs |
| Stability | Shaking feedback (inverted) | Score ≤2 | - | OlyTrainingLogs |
| Breath Hold | Best hold in period | 60 seconds | - | BreathTrainingLogs (NEW) |
| Breath Exhale | Best Patrick exhale | 60 seconds | - | BreathTrainingLogs (NEW) |

## Time Window Behavior
- Default: 7 days
- Expands automatically as user accumulates data (30, 90 days)
- User can manually select time window

---

## Phase 1: Database Schema - Breath Training Logs

### Task 1.1: Add BreathTrainingLogs table to database.dart

**File:** `lib/db/database.dart`

Add new table definition after line ~215 (after OlyTrainingLogs):

```dart
class BreathTrainingLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionType => text()(); // 'breathHold', 'pacedBreathing', 'patrickBreath'
  IntColumn get totalHoldSeconds => integer().nullable()(); // For breath hold sessions
  IntColumn get bestHoldThisSession => integer().nullable()(); // Best single hold
  IntColumn get bestExhaleSeconds => integer().nullable()(); // For Patrick breath
  IntColumn get rounds => integer().nullable()(); // Number of rounds completed
  TextColumn get difficulty => text().nullable()(); // 'beginner', 'intermediate', 'advanced'
  IntColumn get durationMinutes => integer().nullable()(); // For paced breathing
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### Task 1.2: Update database version and migration

**File:** `lib/db/database.dart`

- Increment `schemaVersion`
- Add migration in `migration` getter to create new table

### Task 1.3: Run build_runner to generate database code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Task 1.4: Add database methods for breath logs

**File:** `lib/db/database.dart`

Add methods:
- `insertBreathTrainingLog(BreathTrainingLogsCompanion log)`
- `getBreathTrainingLogs({DateTime? since})`
- `getBestBreathHold({DateTime? since})`
- `getBestExhaleTime({DateTime? since})`

---

## Phase 2: Persist Breath Training Sessions

### Task 2.1: Update BreathTrainingProvider

**File:** `lib/providers/breath_training_provider.dart`

Add method to save session results:
```dart
Future<void> saveBreathSession({
  required String sessionType,
  int? totalHoldSeconds,
  int? bestHoldThisSession,
  int? bestExhaleSeconds,
  int? rounds,
  String? difficulty,
  int? durationMinutes,
}) async {
  // Insert into BreathTrainingLogs table
}
```

### Task 2.2: Update Breath Hold Screen

**File:** `lib/screens/breath_training/breath_hold_screen.dart`

On session complete (after all rounds):
- Calculate total hold time
- Get best hold from session
- Call provider to save log

### Task 2.3: Update Paced Breathing Screen

**File:** `lib/screens/breath_training/paced_breathing_screen.dart`

On session complete:
- Save duration and completion status

### Task 2.4: Update Patrick Breath Screen

**File:** `lib/screens/breath_training/patrick_breath_screen.dart`

On test complete:
- Save best exhale time from attempts
- This data currently goes to SharedPreferences - also save to DB for historical tracking

---

## Phase 3: Spider Graph Provider

### Task 3.1: Create SpiderGraphProvider

**File:** `lib/providers/spider_graph_provider.dart` (NEW)

```dart
class SpiderGraphProvider extends ChangeNotifier {
  // Targets (configurable)
  static const defaultTargets = SpiderTargets(
    handicap: 1,
    arrowsPerWeek: 600,
    trainingDaysPerWeek: 7,
    holdMinutesPerWeek: 20,
    formScore: 2,
    stabilityScore: 2,
    breathHoldSeconds: 60,
    breathExhaleSeconds: 60,
  );

  // Elite targets
  static const eliteTargets = SpiderTargets(
    handicap: 1,
    arrowsPerWeek: 800,
    trainingDaysPerWeek: 7,
    holdMinutesPerWeek: 37,
    formScore: 2,
    stabilityScore: 2,
    breathHoldSeconds: 60,
    breathExhaleSeconds: 60,
  );

  SpiderTargets _targets = defaultTargets;
  int _timeWindowDays = 7;
  SpiderData? _data;

  Future<void> loadData() async {
    // Calculate each spoke value
  }

  // Returns 0-100 for each spoke
  SpiderData get data => _data ?? SpiderData.empty();
}
```

### Task 3.2: Implement spoke calculations

Each spoke calculation method:

**Score Level (0-100):**
```dart
// Lower handicap = better, so invert
// HC 1 = 100%, HC 100 = 0%
double scoreLevel = max(0, (100 - bestHandicap) / 99 * 100);
```

**Training Volume (0-100):**
```dart
double volume = min(100, (arrowsThisWeek / target) * 100);
```

**Training Frequency (0-100):**
```dart
double frequency = min(100, (daysTrainedThisWeek / 7) * 100);
```

**Bow Fitness (0-100):**
```dart
double bowFitness = min(100, (holdMinutesThisWeek / targetMinutes) * 100);
```

**Form Quality (0-100):**
```dart
// Lower score = better, scores are 1-10
// Score 2 = 100%, Score 10 = 0%
double formQuality = max(0, (10 - avgStructureScore) / 8 * 100);
```

**Stability (0-100):**
```dart
// Same inversion as form
double stability = max(0, (10 - avgShakingScore) / 8 * 100);
```

**Breath Hold (0-100):**
```dart
double breathHold = min(100, (bestHoldSeconds / 60) * 100);
```

**Breath Exhale (0-100):**
```dart
double breathExhale = min(100, (bestExhaleSeconds / 60) * 100);
```

### Task 3.3: Handle missing data

- If no data for a spoke in the time window, return `null` (not 0)
- Widget will render missing spokes in gray or dotted line

---

## Phase 4: Spider Graph Widget

### Task 4.1: Create SpiderGraphWidget

**File:** `lib/widgets/spider_graph_widget.dart` (NEW)

Use `fl_chart`'s `RadarChart`:

```dart
class SpiderGraphWidget extends StatelessWidget {
  final SpiderData data;

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Color(0xFFFFD700).withOpacity(0.3),
            borderColor: Color(0xFFFFD700),
            entryRadius: 3,
            dataEntries: [
              RadarEntry(value: data.scoreLevel ?? 0),
              RadarEntry(value: data.trainingVolume ?? 0),
              RadarEntry(value: data.trainingFrequency ?? 0),
              RadarEntry(value: data.bowFitness ?? 0),
              RadarEntry(value: data.formQuality ?? 0),
              RadarEntry(value: data.stability ?? 0),
              RadarEntry(value: data.breathHold ?? 0),
              RadarEntry(value: data.breathExhale ?? 0),
            ],
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(color: Colors.white24),
        tickBorderData: BorderSide(color: Colors.white12),
        gridBorderData: BorderSide(color: Colors.white12),
        tickCount: 4, // 25%, 50%, 75%, 100%
        ticksTextStyle: TextStyle(color: Colors.white38, fontSize: 10),
        titleTextStyle: TextStyle(color: Colors.white70, fontSize: 12),
        getTitle: (index, angle) {
          switch (index) {
            case 0: return RadarChartTitle(text: 'Score');
            case 1: return RadarChartTitle(text: 'Volume');
            case 2: return RadarChartTitle(text: 'Frequency');
            case 3: return RadarChartTitle(text: 'Bow Fitness');
            case 4: return RadarChartTitle(text: 'Form');
            case 5: return RadarChartTitle(text: 'Stability');
            case 6: return RadarChartTitle(text: 'Breath Hold');
            case 7: return RadarChartTitle(text: 'Exhale');
            default: return RadarChartTitle(text: '');
          }
        },
        titlePositionPercentageOffset: 0.2,
      ),
    );
  }
}
```

### Task 4.2: Add time window selector

Dropdown or segmented control for 7/30/90 days

### Task 4.3: Add tap-to-detail interaction (optional)

Tapping a spoke shows breakdown:
- Current value
- Target value
- Trend (improving/declining)

---

## Phase 5: Integration

### Task 5.1: Add SpiderGraphProvider to main.dart

**File:** `lib/main.dart`

Register provider in MultiProvider

### Task 5.2: Add to Home Screen

**File:** `lib/screens/home_screen.dart`

Add compact spider graph card:
- ~200px height
- Time window selector
- "View Details" button

### Task 5.3: Create Progress Detail Screen (optional)

**File:** `lib/screens/progress_screen.dart` (NEW)

Full-screen view with:
- Larger spider graph
- Individual spoke breakdowns
- Historical comparison (this week vs last week)
- Elite mode toggle

---

## Testing Checklist

- [ ] Breath sessions save to database correctly
- [ ] All 8 spoke calculations return expected values
- [ ] Missing data handled gracefully (no crashes)
- [ ] Time window changes update graph
- [ ] Graph renders correctly with partial data
- [ ] Targets can be switched between normal/elite

---

## File Summary

**Modified files:**
- `lib/db/database.dart` - Add BreathTrainingLogs table
- `lib/db/database.g.dart` - Generated
- `lib/providers/breath_training_provider.dart` - Add save methods
- `lib/screens/breath_training/breath_hold_screen.dart` - Save on complete
- `lib/screens/breath_training/paced_breathing_screen.dart` - Save on complete
- `lib/screens/breath_training/patrick_breath_screen.dart` - Save on complete
- `lib/main.dart` - Register SpiderGraphProvider
- `lib/screens/home_screen.dart` - Add spider graph card

**New files:**
- `lib/providers/spider_graph_provider.dart`
- `lib/widgets/spider_graph_widget.dart`
- `lib/screens/progress_screen.dart` (optional)

---

## Estimated Complexity

- Phase 1 (DB): Straightforward migration
- Phase 2 (Persist): Minor updates to 3-4 screens
- Phase 3 (Provider): Medium - 8 calculation methods
- Phase 4 (Widget): Straightforward with fl_chart
- Phase 5 (Integration): Minor UI work

All changes are reversible. No auth/payments/sync affected.
