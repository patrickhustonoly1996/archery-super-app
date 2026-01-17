# Fixes Needed

Tracked issues from investigation sessions. Each section has enough detail to implement without re-investigation.

---

## Branches To Merge

**Status:** ✅ ALL MERGED (January 2026)

All feature branches have been merged into main:

### handicap-graph ✅ MERGED
**Branch:** `origin/claude/archery-handicap-graph-ySjH2`
- Time filters: 1m, 3m, 6m, 9m, 12m, 2y, 5y, custom date range
- Milestone markers on graph (PBs, classifications)
- New `Milestones` database table

### volume-upload ✅ MERGED
**Branch:** `origin/claude/arrow-volume-upload-NJ9nO`
- Dedicated upload screen with better UX
- Column mapping for CSV imports
- Paste data support
- Preview before import

### arrow-specs ✅ MERGED
**Branch:** `origin/claude/bow-equipment-specs-NadxK`
- Comprehensive arrow specifications for quivers
- Equipment detail tracking

### sessions-memory ✅ MERGED
**Branch:** `origin/claude/add-training-intro-screen-VkAap`
- Session memory (remembers last session type)
- Favorites system
- Custom session builder
- BowTrainingIntroScreen for quick-start access

---

## P0: Plotting Coordinate Bug

**Status:** ✅ FIXED (January 2026)

**What was wrong:**
- `OverflowBox` default alignment is `Alignment.center` which conflicted with `Transform.scale(alignment: Alignment.topLeft)`
- The vertical-only offset (0, -60) meant arrow was straight above finger, easily blocked by hand

**Fixes applied:**
1. Added `alignment: Alignment.topLeft` to OverflowBox in both:
   - `lib/widgets/target_face.dart:649` (zoom window)
   - `lib/widgets/group_centre_widget.dart:177` (group centre widget)

2. Changed offset from vertical to diagonal:
   - Right-handers: (-42, -42) = up-left
   - Left-handers: (+42, -42) = up-right
   - New parameter: `InteractiveTargetFace(isLeftHanded: true/false)`

**Key learning - The 3 Coordinate Systems:**
| System | Origin | Range | Used For |
|--------|--------|-------|----------|
| Widget Pixels | Top-left | (0,0) to (size, size) | Touch events, Flutter positioning |
| Normalized | Center | (-1, -1) to (1, 1) | Database storage (size-independent) |
| Physical (mm) | Center | ±610mm for 122cm face | Handicap math, sight adjustments |

**Conversion formula (Widget → Normalized):**
```dart
normalizedX = (widgetX - centerX) / radius;
normalizedY = (widgetY - centerY) / radius;
```

---

## P0: Widgets Not Displaying Correctly

**Status:** ✅ FIXED (January 2026)

**Root cause:** Same OverflowBox alignment issue as zoom window.

**Fix:** Added `alignment: Alignment.topLeft` to `lib/widgets/group_centre_widget.dart:177`

Also removed duplicate flawed zoom calculation - now uses `SmartZoom.calculateZoomFactor()`.

---

## P0: Zoom Completely Broken + Missing Pinch-to-Zoom

**Status:** ✅ FIXED (January 2026)

### SmartZoom Algorithm - Rewritten

**Old (broken):** Used score frequency - 12 arrows all scoring 9 but scattered = same zoom as 12 arrows bunched tight.

**New (correct):** Uses actual arrow positions
1. Calculate group center (mean of arrow positions)
2. Find 90th percentile distance from center (ignores 1 wild outlier)
3. Zoom = `1 / (spreadRadius + 0.2 padding)`
4. Result: Tight group → ~5x zoom, Wide group → 2x zoom

**Key constants:**
- `minArrowsForAdaptiveZoom = 3` (was 12)
- `minZoom = 2.0`
- `maxZoom = 6.0`
- `paddingRings = 0.2` (~2 rings of padding around group)

### Pinch-to-Zoom - Added

**Implementation:** Unified scale gesture handling
- 1 finger drag → plots arrow
- 2 finger pinch → zooms target (1x to 6x)

Uses `onScaleStart/Update/End` with `details.pointerCount` to distinguish.

**Files changed:**
- `lib/utils/smart_zoom.dart` - complete rewrite
- `lib/widgets/target_face.dart` - added scale handlers, Transform.scale wrapper
- `lib/widgets/group_centre_widget.dart` - now uses SmartZoom

---

## P1: Imperial 5-Zone Scoring

**Status:** ✅ FIXED (January 2026)
**Problem:** York, Bristol, Warwick, Albion etc use 5-zone scoring (9-7-5-3-1 by color) but app only supports 10-zone.

**Implementation (completed):**
- `lib/db/database.dart:26-27` - Added `scoringType` column with '10-zone' default
- `lib/db/database.dart:346-355` - Migration updates existing imperial rounds
- `lib/db/round_types_seed.dart` - All `agb_imperial` rounds have `scoringType: '5-zone'`
- `lib/theme/app_theme.dart:303-333` - `scoreFromDistanceMm()` supports both scoring types
- `lib/theme/app_theme.dart:337-350` - `ringTo5ZoneScore()` conversion function
- `lib/providers/session_provider.dart:58,215-219` - Scoring type passed through plotting flow
- `lib/utils/target_coordinate_system.dart:18,172-177` - Coordinate system supports scoring type
- `test/utils/scoring_test.dart` - Comprehensive tests for all boundary cases

**Visual stays the same** - still show all 10 rings on target face. Only the numbers change.

---

## P2: Volume Graph Visibility

**Status:** ✅ FIXED (January 2026)
**Issues fixed:**
- Hard to see with red light glasses (night mode)
- Needed time period selector
- Needed date/title visibility

**Files changed:**
- `lib/widgets/volume_chart.dart` - Complete rewrite with new features

**What was implemented:**
1. **High contrast for red light glasses:**
   - Gold line at 70% opacity, 2.5px thickness
   - Larger data points (5-6px)
   - Brighter labels
   - Taller chart (160px)

2. **Time period selector:**
   - Chip row: 1W, 1M, 3M, 6M, 1Y, All, Indoor, Outdoor, Custom
   - Indoor = Oct-Mar, Outdoor = Apr-Sep
   - Custom opens bottom sheet with quick picks and date range picker

3. **Date range display:**
   - Shows actual date range below chart
   - Session count in header

---

## P1: Plotting Flow Tests Missing Provider

**Status:** Not started
**Problem:** 10 tests failing in `test/integration/plotting_flow_test.dart` because `PlottingScreen` now uses `ConnectivityProvider` (for offline indicator) but the tests don't provide it.

**Root cause:** Widget tree fails to build when `Consumer<ConnectivityProvider>` can't find the provider, so the menu never renders and tests looking for "Abandon session" fail.

**Fix:** Add `ConnectivityProvider` to the test widget setup:
```dart
await tester.pumpWidget(
  Provider<AppDatabase>.value(
    value: db,
    child: ChangeNotifierProvider<SessionProvider>.value(
      value: sessionProvider,
      child: ChangeNotifierProvider(
        create: (_) => ConnectivityProvider(),  // ADD THIS
        child: ChangeNotifierProvider(
          create: (context) => EquipmentProvider(context.read<AppDatabase>())..loadEquipment(),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PlottingScreen(),
          ),
        ),
      ),
    ),
  ),
);
```

**Files:**
- `test/integration/plotting_flow_test.dart` - Add ConnectivityProvider to all test setups

---

## P1: Menu Scrolling Issue

**Status:** Not started
**Problem:** Menu scrolling on home screen has issues - reported by user.

**Files:**
- `lib/screens/home_screen.dart`

**Needs investigation:** What specific scrolling issue? Janky? Doesn't scroll? Wrong scroll physics?

---

## P1: Arrows Not Dropping (Plotting Issue)

**Status:** Not started
**Problem:** Arrows not dropping when plotting on target - reported by user.

**Files:**
- `lib/screens/plotting_screen.dart`
- `lib/widgets/target_face.dart`

**Needs investigation:** Is it touch detection? Visual feedback? Database not saving?

---

## P1: Volume Input Interface Saves

**Status:** Not started
**Problem:** Volume input interface not saving properly - reported by user.

**Files:**
- `lib/screens/volume_import_screen.dart`
- `lib/db/database.dart` (volume tables)

**Needs investigation:** What's not saving? Manual entry? CSV import? Both?

---

## P1: Inter-Device Data Push

**Status:** Not started
**Problem:** Need to sync data between devices (phone, tablet, web).

**Files:**
- `lib/services/firestore_sync_service.dart`

**Implementation needed:**
- Push local data to Firestore
- Pull remote data to local
- Conflict resolution strategy
- User authentication link

---

## P1: Selfie Camera

**Status:** Not started
**Problem:** Selfie/front camera feature needed or broken.

**Files:**
- `lib/screens/delayed_camera_native.dart`
- `lib/screens/delayed_camera_web.dart`

**Needs investigation:** Is it camera switching? Front camera not available? Mirror mode?

---

## P1: Breathing Cues Visibility

**Status:** Not started
**Problem:** Breathing cues not visible enough during training.

**Files:**
- `lib/screens/breath_training/paced_breathing_screen.dart`
- `lib/screens/breath_training/patrick_breath_screen.dart`
- `lib/screens/breath_training/breath_hold_screen.dart`

**Needs investigation:** Text too small? Low contrast? Need larger visual indicator?

---

## P1: Haptic Feedback / Beeps

**Status:** Not started
**Problem:** Haptic feedback and audio beeps not working or need improvement.

**Files:**
- `lib/services/beep_service.dart`
- `lib/providers/bow_training_provider.dart`
- `lib/screens/breath_training/*.dart`

**Needs investigation:** Not triggering? Wrong timing? Need user settings? Web vs native differences?

---

## P1: Exhale Test Structure Edit

**Status:** Not started
**Problem:** Need to edit/improve the exhale test structure in breath training.

**Files:**
- `lib/screens/breath_training/breath_hold_screen.dart`
- `lib/providers/breath_training_provider.dart`

**Needs investigation:** What structure changes needed? Different phases? Timing adjustments?

---

## P1: Equipment Log Details

**Status:** Not started
**Problem:** Equipment log needs more detail/features.

**Files:**
- `lib/screens/equipment_screen.dart`
- `lib/screens/bow_form_screen.dart`
- `lib/providers/equipment_provider.dart`

**Needs investigation:** What details missing? Arrow counts? Maintenance logs? Usage history?

---

## P2: Timer Pause When App Backgrounds

**Status:** ✅ FIXED (January 2026)
**Problem:** Bow training timer keeps running when app goes to background, ruining training sessions.

**Files changed:**
- `lib/providers/bow_training_provider.dart` - Added `WidgetsBindingObserver` mixin, auto-pauses on background
- `lib/screens/bow_training_screen.dart` - Shows subtle "Paused (app backgrounded)" message, removed old dialog

**Behavior:**
- Timer auto-pauses when app goes to background
- Stays paused when user returns (no auto-resume)
- Shows subtle message explaining why it's paused
- User taps play to resume manually

---

## P2: Linecutter Auto-Zoom

**Status:** ✅ FIXED (January 2026)

**What was implemented:**
- **Snap zoom:** Instant activation when arrow preview gets within 4% of a ring boundary (removed 300ms delay)
- **Enlarged zoom window:** Grows from 120px to 160px in linecutter mode
- **Glowing boundary highlight:** Nearest ring boundary glows green with blur effect
- **"Line cutter?" prompt:** Larger text (14px) with shadow, positioned below zoom window
- **Thicker border:** 5px green border with glow shadow in linecutter mode
- **Haptic feedback:** Medium impact when entering linecutter mode

**Files modified:**
- `lib/widgets/target_face.dart` - All changes in this file:
  - Added `_linecutterWindowSize = 160.0` constant
  - Removed timer-based activation, now instant
  - Added `_BoundaryHighlightPainter` class for glowing ring
  - Updated `_ZoomWindow` with larger border, glow shadow, bigger label

**How it works:**
1. User drags arrow near ring boundary (within 4% of radius)
2. Linecutter mode activates instantly with haptic feedback
3. Zoom window enlarges and border glows green
4. Nearest ring boundary highlighted with green glow
5. "Line cutter?" prompt appears prominently
6. Moving away from boundary snaps back to normal mode

---

## P2: Kit Details Auto-Prompt on Top 20% Score

**Status:** Not started
**Problem:** When an archer achieves a score in their top 20% historically, prompt them to save their current kit configuration - that setup is clearly working well.

**Trigger Logic:**
```dart
// After session completes with score:
final allScores = await db.getAllSessionScores();
final threshold = calculatePercentile(allScores, 80); // top 20%
if (currentScore >= threshold) {
  showKitSavePrompt();
}
```

**Implementation Steps:**

1. **Add percentile calculation utility**
   - File: `lib/utils/statistics.dart` (new)
   - Function to calculate nth percentile from score list
   - Handle edge cases: <5 sessions = skip prompt

2. **Expand Kit Details model** (also needed for tuning)
   - Current `Bows.settings` is JSON - needs structure
   - Add fields to track:
     - Sight settings (marks by distance)
     - Stabilizer setup (lengths, weights)
     - String details (material, strand count)
     - Limb bolts/poundage
     - Clicker position
     - Arrow rest position

3. **Create Kit Snapshot table**
   - `KitSnapshots`: id, bowId, quiverId, snapshotDate, sessionId, score, settings JSON
   - Links high score to exact configuration that produced it

4. **Add prompt after session completion**
   - File: `lib/screens/session_complete_screen.dart` (or wherever scores finalize)
   - Check if score in top 20%
   - Show bottom sheet: "Great score! Save your current kit setup?"
   - Pre-fill from current default bow/quiver settings

**Files:**
- `lib/db/database.dart` - New table, migration
- `lib/providers/equipment_provider.dart` - Kit snapshot methods
- `lib/screens/session_complete_screen.dart` - Prompt logic
- `lib/utils/statistics.dart` - Percentile calculation

---

## P2: Kit Tuning Framework

**Status:** Not started
**Problem:** Need structured way to log and track bow tuning - different process for compound vs recurve.

**Bow Type Split:**
- **Recurve:** Paper tune, bare shaft, walk-back, nock point, tiller, brace height, centershot, plunger
- **Compound:** Paper tune, bare shaft, French tune, cam timing, yoke tuning, rest position, peep height

**Implementation Steps:**

1. **Create TuningSession table**
   - `TuningSessions`: id, bowId, date, bowType, tuningType, results JSON, notes
   - `tuningType`: 'paper', 'bare_shaft', 'walk_back', 'french', etc.

2. **Add Tuning Checklist screen**
   - File: `lib/screens/tuning_checklist_screen.dart` (new)
   - Detect bow type from selected bow
   - Show appropriate checklist:
     ```
     RECURVE TUNING CHECKLIST
     [ ] Brace height: _____ inches
     [ ] Nock point: _____ above square
     [ ] Tiller: _____ (positive/even/negative)
     [ ] Centershot: _____ mm from riser
     [ ] Plunger tension: _____ (soft/medium/stiff)
     [ ] Paper tune result: _____ (tear direction)
     [ ] Bare shaft result: _____ (stiff/weak/good)
     ```

3. **Paper Tune Logger**
   - Capture tear direction (up/down/left/right/clean)
   - Capture tear size (small/medium/large)
   - Suggest fixes based on tear pattern
   - Store history of attempts

4. **Tuning History view**
   - Show timeline of tuning sessions
   - Display what was adjusted and results
   - Highlight when group patterns improved after tuning

5. **Link tuning to group analysis**
   - File: `lib/utils/group_analysis.dart`
   - Detect consistent bias (e.g., "groups always 15mm left")
   - Suggest: "Consider centershot adjustment"

**Files:**
- `lib/db/database.dart` - New table
- `lib/screens/tuning_checklist_screen.dart` - Main UI
- `lib/screens/tuning_history_screen.dart` - History view
- `lib/models/tuning_session.dart` - Data model
- `lib/utils/tuning_suggestions.dart` - Auto-suggestions from tears/groups

---

## P2: Arrow Shaft Tracking & Analysis

**Status:** Not started
**Problem:** Need to track individual arrow performance. Two parts:
1. **Specs** (in kit details): spine, length, point weight, fletching - lives with quiver/shaft
2. **Shot tracking** (in scoring): which numbered arrow made each shot - analyze grouping by arrow

**Implementation Steps:**

### Part A: Arrow Specifications (Kit Details)

1. **Expand Shafts table**
   - Current fields: id, quiverId, number, notes, retiredAt
   - Add: spine, lengthInches, pointWeight, fletchingType, fletchingColor, nockColor
   - File: `lib/db/database.dart` - migration

2. **Arrow Spec Entry UI**
   - File: `lib/screens/shaft_detail_screen.dart` (new or expand existing)
   - Form fields for all specs
   - Batch entry option (all arrows same spec, just different numbers)

### Part B: Shot Tracking (Scoring Data)

3. **Add shaftId to Arrows table**
   - Current Arrows table has coordinates but no shaft reference
   - Add nullable `shaftId` column
   - File: `lib/db/database.dart` - migration

4. **Shaft selector in plotting UI**
   - File: `lib/widgets/target_face.dart` or `lib/screens/plotting_screen.dart`
   - Quick picker showing arrow numbers (1-12 chips)
   - Auto-advance to next number after plotting
   - Or: tap plotted arrow to assign number retroactively

5. **Per-Shaft Analysis**
   - File: `lib/utils/shaft_analysis.dart` (new)
   - Calculate per arrow:
     - Average position (is arrow #3 always left?)
     - Group spread (is arrow #7 inconsistent?)
     - Score distribution
   - Detect outliers: "Arrow #5 groups 40% wider than others"

6. **Shaft Analysis UI**
   - File: `lib/screens/shaft_analysis_screen.dart` (new)
   - Show each arrow's performance stats
   - Heatmap overlay option (color by arrow number)
   - Recommendations: "Consider retiring arrow #5 - inconsistent grouping"

7. **Overlap likelihood calculation**
   - Based on group spread and arrow count
   - Calculate probability of robin-hoods/overlaps
   - Show warning when group is tight: "High overlap risk at this group size"

**Files:**
- `lib/db/database.dart` - Schema changes
- `lib/screens/shaft_detail_screen.dart` - Spec entry
- `lib/screens/plotting_screen.dart` - Shaft picker
- `lib/utils/shaft_analysis.dart` - Analysis logic
- `lib/screens/shaft_analysis_screen.dart` - Results UI

---

## Future Features (Captured Ideas)

### Clicks-Per-Ring Training Exercise
User-defined exercise to learn sight adjustment:
1. Shoot and plot centered group at distance
2. Move sight known amount (e.g., 100 clicks / 5 turns)
3. Re-plot group, measure rings moved to X center
4. Calculate clicks/ring ratio
5. Store as athlete data point

### 252 Scheme Progression Tracker
Club progression system:
- Track scores on 36-arrow imperial rounds
- Badge when 252+ achieved at distance
- Visual progression through distances (20→30→40→50→60→80→100 yards)

### Group Visualization Enhancements
- Spread ellipse showing group shape
- Arrow trails by end (color coded)
- Group size in ring notation (e.g., "9.2 group")

### Score Sanity Checks
- Flag perfect 720/720 as "verify this?"
- Flag huge handicap jumps between sessions
- Validate score possible for round type

---

## Domain Knowledge Reference

### Scoring Systems
- **10-zone (WA/Metric):** X, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0
- **5-zone (Imperial):** 9 (gold), 7 (red), 5 (blue), 3 (black), 1 (white), 0 (miss)

### Group Size Language
Use ring notation, not mm:
- Elite at 70m: sub-9 group
- Good club at 70m: mostly red (7-8)
- Decimal notation: "9.5 group" = spread covers half the 9 ring

### 252 Scheme
- 36 arrows, 5-zone scoring
- Need 252+ (avg 7/red) to progress to next distance
- Distances: 20, 30, 40, 50, 60, 80, 100 yards

---

*Last updated: January 2026*
