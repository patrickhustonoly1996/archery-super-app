# PRD: Ralph Session Tasks

Comprehensive requirements gathered from Patrick. All clarifications complete - implement without asking further questions.

---

## CRITICAL: Codebase Issues Found During Review

These issues MUST be fixed as part of the relevant features, or they will cause UI failures.

### Issue 1: Beeps/Vibrations Default to OFF (Should be ON)
**Location:** `lib/services/breath_training_service.dart` line ~99
**Problem:** `getBeepsEnabled()` returns `false` by default
**Fix:** Change default to `true`
```dart
// WRONG (current):
return prefs.getBool(_beepsEnabledKey) ?? false;
// CORRECT:
return prefs.getBool(_beepsEnabledKey) ?? true;
```

### Issue 2: No Vibration Support Exists
**Location:** All breath training screens
**Problem:** `BeepService` only does audio beeps. No `HapticFeedback` calls at phase transitions.
**Fix:** Add vibration calls alongside beeps:
```dart
if (vibrationsEnabled) {
  HapticFeedback.mediumImpact();
}
```

### Issue 3: Timer Doesn't Pause on App Background (Paced Screens)
**Location:** `lib/screens/breath_training/paced_breathing_screen.dart`, `patrick_breath_screen.dart`
**Problem:** `BreathHoldScreen` has `WidgetsBindingObserver` but the other two screens DON'T
**Fix:** Add `WidgetsBindingObserver` mixin to both screens:
```dart
class _PacedBreathingScreenState extends State<PacedBreathingScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTimer();
    }
  }
}
```

### Issue 4: Volume Import May Fail Silently
**Location:** `lib/screens/volume_import_screen.dart`
**Problem:** No verification that database write succeeded. User thinks import worked.
**Fix:** Add explicit success check and error state:
```dart
try {
  final rowsInserted = await db.insertVolumeData(data);
  if (rowsInserted == 0) {
    throw Exception('No data was saved');
  }
  // Show success
} catch (e) {
  setState(() => _error = 'Import failed: $e');
  // Show error UI, don't pretend it worked
}
```

### Issue 5: Settings Loaded Async Causes UI Flicker
**Location:** All breath training screens `initState`
**Problem:** Settings load async, UI renders with wrong defaults first
**Fix:** Initialize state with sensible defaults, settings update is secondary:
```dart
// Initialize with correct defaults immediately
bool _vibrationsEnabled = true; // Not false!
int _holdDuration = 4;

@override
void initState() {
  super.initState();
  _loadSettings(); // Updates later, but defaults are correct
}
```

### Issue 6: Bow Settings Stored as Pipe-Delimited Text
**Location:** `lib/screens/bow_form_screen.dart` lines 50-68
**Problem:** Settings like `"braceHeight:7.5|tiller:even"` are fragile, no schema
**Impact:** Equipment expansion (PRD 4B) will be painful
**Fix:** When implementing 4B, migrate to proper typed columns OR structured JSON:
```dart
// Option A: Add real columns to Bows table
RealColumn get poundage => real().nullable();
TextColumn get limbModel => text().nullable();

// Option B: Use JSON with schema validation
TextColumn get settingsJson => text().nullable();
// Parse as: Map<String, dynamic> settings = jsonDecode(bow.settingsJson);
```

### Issue 7: Shaft Tracking Preference Not Remembered
**Location:** `lib/screens/session_start_screen.dart` (lines 200-215)
**Problem:** Toggle exists but resets to OFF each new session. Users have to re-enable every time.
**Fix:** Store preference in SharedPreferences, load as default:
```dart
// On session start screen init:
final prefs = await SharedPreferences.getInstance();
_shaftTaggingEnabled = prefs.getBool('shaft_tagging_default') ?? false;

// When user changes toggle:
await prefs.setBool('shaft_tagging_default', value);
setState(() => _shaftTaggingEnabled = value);
```

### Issue 8: Missing nockRotation Column in Arrows Table
**Location:** `lib/db/database.dart` - Arrows table
**Problem:** PRD 4C requires nock rotation tracking but column doesn't exist
**Fix:** Add in migration:
```dart
// In Arrows table definition
TextColumn get nockRotation => text().nullable(); // '12', '4', '8'
```

### Issue 9: Form Error Handling Inconsistent
**Location:** `BowFormScreen`, `QuiverFormScreen`
**Problem:** Only show loading spinner, no error states displayed
**Fix:** Follow `SessionDetailScreen` pattern - add error state with retry:
```dart
String? _error;

// In build:
if (_error != null) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.error, color: AppColors.gold),
        Text(_error!),
        ElevatedButton(onPressed: _retry, child: Text('Retry')),
      ],
    ),
  );
}
```

### Issue 10: Smart Zoom Can Return < 2x Before Clamping
**Location:** `lib/utils/smart_zoom.dart`
**Problem:** Calculation can produce values < 2.0 that need clamping
**Verify:** Ensure `minZoom = 2.0` is enforced at calculation time, not just display time

---

## Reference Implementations (Follow These Patterns)

| Pattern | Reference File | Use For |
|---------|----------------|---------|
| Loading/Error/Empty states | `SessionDetailScreen` | All new screens |
| Bottom sheet popups | `ShaftSelectorBottomSheet` in `plotting_screen.dart` | Shaft picker, settings |
| Form with validation | `BowFormScreen` | Equipment forms |
| Timer with app lifecycle | `BreathHoldScreen` | All timed features |
| Provider state management | `SessionProvider` | New providers |
| Database migrations | `database.dart` migration switch | Schema changes |

---

## RALPH PROMPT (Copy this block)

```
Work through all tasks in docs/PRD_RALPH_SESSION.md in priority order. Requirements are fully specified - implement without asking questions. Run `flutter test` before and after each feature. Commit after each completed feature.

Priority order:
1. Quick fixes (splash logo, default zoom)
2. Bug fixes (volume save, vibrations)
3. UI improvements (breathing cues)
4. Feature additions (exhale test, equipment, shaft tracking)
5. Major features (sync, tuning, clicks-per-ring)

Read the full PRD before starting. Each section has implementation details.
```

---

## Priority 1: Quick Fixes

### 1A. Splash Screen Logo
**Status:** Not started
**Problem:** Wrong image on splash screen

**Requirements:**
- Display the app icon (launcher icon)
- Below icon: text "built by HUSTON ARCHERY"
- Use `AppFonts.pixel` (VT323) for the text
- Gold (#FFD700) text on dark background

**Files:**
- `lib/main.dart` or splash screen widget
- Android: `android/app/src/main/res/drawable/launch_background.xml`
- iOS: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
- Web: `web/index.html` splash section

---

### 1B. Default 2x Zoom for Plotting
**Status:** Not started
**Problem:** Target opens at 1x zoom, should be 2x by default

**Requirements:**
- Target face loads at 2x zoom when plotting screen opens
- Smart auto-zoom still works (adjusts based on group spread)
- Auto-zoom should never go below 2x
- Pinch-to-zoom must remain functional (already implemented)

**Implementation:**
```dart
// In target_face.dart or plotting_screen.dart
double _currentZoom = 2.0; // Changed from 1.0

// In SmartZoom calculation
double calculateZoomFactor(...) {
  final calculated = ...; // existing logic
  return max(calculated, 2.0); // Floor at 2x
}
```

**Files:**
- `lib/widgets/target_face.dart`
- `lib/utils/smart_zoom.dart`

---

## Priority 2: Bug Fixes

### 2A. Volume Manual Entry Not Saving
**Status:** Not started
**Problem:** Manually entered arrow volume data doesn't persist

**Investigation needed:**
- Check `lib/screens/volume_import_screen.dart` for save logic
- Verify database write in `lib/db/database.dart`
- Check if form validation prevents save
- Test: Enter data, close screen, reopen - is data there?

**Files:**
- `lib/screens/volume_import_screen.dart`
- `lib/db/database.dart` (volume tables)
- `lib/providers/` - check for volume provider

---

### 2B. Vibrations Not Triggering
**Status:** Not started
**Problem:** Haptic feedback not working in breath training

**Requirements:**
- Vibrations ON by default when starting any breath training session
- Add toggle to turn vibrations OFF (remember preference)
- Label as "Vibrations" not "Haptics" (accessibility)
- Should trigger at phase transitions (inhale→hold→exhale)

**Implementation:**
```dart
// In breath training provider or settings
bool vibrationsEnabled = true; // Default ON

// At phase transitions
if (vibrationsEnabled) {
  HapticFeedback.mediumImpact();
}
```

**Files:**
- `lib/services/beep_service.dart` - Add vibration support
- `lib/providers/breath_training_provider.dart` - Trigger vibrations
- `lib/screens/breath_training/*.dart` - Add toggle UI
- Store preference in SharedPreferences or database

---

## Priority 3: UI Improvements

### 3A. Breathing Cues Visibility (Web)
**Status:** Not started
**Problem:** On web browser, breathing cues hidden at bottom, not prominent enough

**Requirements:**
- Cues must be prominent and centered, not at bottom
- Consider subtle movement/animation to draw attention
- Must work across all screen sizes (responsive)
- Test specifically in web browser

**Implementation approach:**
- Move breathing indicator to center of screen
- Increase size significantly for web
- Add subtle pulsing/floating animation
- Use MediaQuery to detect web and adjust layout

**Files:**
- `lib/screens/breath_training/paced_breathing_screen.dart`
- `lib/screens/breath_training/breath_hold_screen.dart`
- `lib/screens/breath_training/patrick_breath_screen.dart`

---

## Priority 4: Feature Additions

### 4A. Exhale Test Redesign
**Status:** Not started
**Problem:** Current exhale test structure needs complete redesign

**New Flow:**
```
1. [2 PACED BREATHS]
   - Inhale (guided)
   - Exhale (guided)
   - Inhale (guided)
   - Exhale (guided)

2. [EXHALE TEST]
   - Inhale (guided, flows naturally)
   - Exhale starts being counted (timer runs)
   - User taps/clicks when exhale finished
   - Record exhale duration

3. [RECOVERY BREATHS]
   - Normal paced breathing to recover
   - Number of recovery breaths TBD (suggest 2-3)

4. [REPEAT]
   - Back to step 2 for next exhale test
   - Continue until user stops session

5. [SIDE PANEL - Always Visible]
   - Running record of exhale times this session
   - Personal best exhale time (all time)
   - Current session best
   - Visual comparison (bar chart or list)
```

**UI Layout:**
```
+---------------------------+-------------+
|                           |   SESSION   |
|    BREATHING VISUAL       |   RECORD    |
|    (center, prominent)    |             |
|                           |  12.3s      |
|    "EXHALE"               |  11.8s      |
|    [  14.2s  ]            |  14.2s *    |
|                           |             |
|    [ TAP WHEN DONE ]      |  PB: 15.1s  |
|                           |             |
+---------------------------+-------------+
```

**Files:**
- `lib/screens/breath_training/breath_hold_screen.dart` - Major rewrite
- `lib/providers/breath_training_provider.dart` - New state machine
- `lib/db/database.dart` - Store exhale records and PB

---

### 4B. Equipment Log Expansion
**Status:** Not started
**Problem:** Equipment details insufficient

**Required Fields by Category:**

**Bow Details (expand existing):**
- Poundage (current draw weight)
- Limb model/brand
- Date of purchase
- Riser model/brand

**Stabilizer Setup (new section):**
- Long rod length (inches)
- Long rod weight (oz)
- Side rod length (inches)
- Side rod weight (oz)
- V-bar mount type
- V-bar angle horizontal (degrees)
- V-bar angle vertical (degrees)
- Damper model
- Damper positions

**Arrow Details (expand Shafts table):**
- Spine (e.g., 350, 400, 500)
- Arrow length (inches, to 1/8")
- Total arrow weight (grains)
- Point weight (grains)
- Nock type/brand
- Fletching type (spin wing, plastic vanes, feathers)
- Fletching offset angle (degrees)
- Fletching color (for identification)

**Tracking:**
- Arrow shot count per bow/quiver
- Date of purchase for all items

**Database Migration:**
```sql
-- Expand Bows table
ALTER TABLE bows ADD COLUMN poundage REAL;
ALTER TABLE bows ADD COLUMN limb_model TEXT;
ALTER TABLE bows ADD COLUMN purchase_date TEXT;
ALTER TABLE bows ADD COLUMN riser_model TEXT;

-- New Stabilizers table
CREATE TABLE stabilizers (
  id TEXT PRIMARY KEY,
  bow_id TEXT REFERENCES bows(id),
  long_rod_length REAL,
  long_rod_weight REAL,
  side_rod_length REAL,
  side_rod_weight REAL,
  vbar_mount TEXT,
  vbar_angle_h REAL,
  vbar_angle_v REAL,
  damper_model TEXT,
  damper_positions TEXT,
  updated_at TEXT
);

-- Expand Shafts table
ALTER TABLE shafts ADD COLUMN spine INTEGER;
ALTER TABLE shafts ADD COLUMN length_inches REAL;
ALTER TABLE shafts ADD COLUMN total_weight_grains REAL;
ALTER TABLE shafts ADD COLUMN point_weight_grains INTEGER;
ALTER TABLE shafts ADD COLUMN nock_type TEXT;
ALTER TABLE shafts ADD COLUMN fletch_type TEXT;
ALTER TABLE shafts ADD COLUMN fletch_offset_degrees REAL;
ALTER TABLE shafts ADD COLUMN fletch_color TEXT;
ALTER TABLE shafts ADD COLUMN purchase_date TEXT;

-- Shot counting
ALTER TABLE bows ADD COLUMN shot_count INTEGER DEFAULT 0;
```

**Files:**
- `lib/db/database.dart` - Schema expansion + migration
- `lib/screens/equipment_screen.dart` - Display new fields
- `lib/screens/bow_form_screen.dart` - Edit forms
- New: `lib/screens/shaft_detail_screen.dart` - Arrow spec entry
- New: `lib/screens/stabilizer_form_screen.dart` - Stabilizer setup

---

### 4C. Arrow Shaft Tracking in Plotting
**Status:** PARTIALLY IMPLEMENTED - needs enhancement

**What Already Exists:**
- `shaftTaggingEnabled` column in Sessions table
- Toggle in `session_start_screen.dart` (lines 200-215)
- `ShaftSelectorBottomSheet` widget shows arrow numbers 1-12
- `plotting_screen.dart` shows bottom sheet when enabled (line 108-121)
- Shaft number stored via `shaftNumber` in Arrows table

**What's Missing:**

1. **Remember preference setting**
   - Currently toggle resets each session
   - Need: Store user preference in SharedPreferences
   - Auto-enable for users who previously used it

2. **Nock Rotation Selection (LOW PRIORITY - truly optional)**
   - Add small icon to bottom of `ShaftSelectorBottomSheet`
   - Visual: rear view of arrow (circle with 3 triangular fletches)
   - Tap a fletch to select that rotation, or tap "?" to skip
   - Most users will ignore this - it's for tuning nerds only

   ```
        ▲          <- 12 o'clock fletch (tap to select)
       /?\
      /   \
     ◄  ●  ►      <- 4 and 8 o'clock fletches
      \   /        ● = nock/shaft center
       \ /         ? = tap center to skip
   ```

   - Appears as small tappable graphic, not prominent buttons
   - If skipped, nock_rotation stays NULL (most common case)

3. **Database Column for Nock Rotation (only if implementing #2)**
   - Add `nock_rotation` column to Arrows table (nullable TEXT: '12', '4', '8')
   - Migration required
   - NULL = not tracked (default, most arrows)

4. **Highlight Used Arrows This End**
   - In `ShaftSelectorBottomSheet`, dim/mark arrows already used this end
   - Prevents confusion about which arrows still to plot

**Enhanced Bottom Sheet UI:**
```
+---------------------------+
|  SELECT ARROW             |
|                           |
|  [1] [2] [3] [4]          |   <- Already plotted = dimmed
|  [5] [6] [7] [8]          |
|  [9][10][11][12]          |
|                           |
|  [SKIP]                   |
|                           |
|  - - - - - - - - - - - -  |   <- Subtle divider
|                           |
|  Nock?    ▲               |   <- LOW PRIORITY
|          ◄●►              |   <- Small tappable arrow rear view
|           ?               |   <- Tap ? or center to skip
+---------------------------+
```
Note: Nock rotation graphic is small and unobtrusive. Most users ignore it.

**Analysis Features (NEW SCREEN):**
- Per-shaft statistics: average position, spread
- Detect outliers: "Arrow #5 groups 40% wider"
- Nock rotation analysis if enough data

**Files to Modify:**
- `lib/widgets/shaft_selector_bottom_sheet.dart` - Add nock rotation, highlight used
- `lib/db/database.dart` - Add nockRotation column + migration
- `lib/screens/plotting_screen.dart` - Pass used arrow numbers to bottom sheet

**New Files:**
- `lib/screens/shaft_analysis_screen.dart` - Analysis UI
- `lib/utils/shaft_analysis.dart` - Statistics calculations

---

## Priority 5: Major Features

### 5A. Inter-Device Data Sync
**Status:** Not started
**Problem:** Data doesn't sync between phone, tablet, and web

**Requirements:**
- Sync across all three: phone, tablet, web browser
- Uses Firebase/Firestore (existing setup)
- Conflict resolution: MERGE BOTH (keep all data from both devices)

**Merge Strategy:**
```dart
// When pulling remote data:
for (final remoteRecord in remoteData) {
  final localRecord = await db.findById(remoteRecord.id);
  if (localRecord == null) {
    // New record from remote - insert
    await db.insert(remoteRecord);
  } else if (remoteRecord.updatedAt > localRecord.updatedAt) {
    // Remote is newer - update local
    await db.update(remoteRecord);
  }
  // If local is newer, keep local (will push to remote)
}

// When pushing local data:
for (final localRecord in localChanges) {
  await firestore.upsert(localRecord); // Firestore handles merge
}
```

**No data loss policy:**
- Never delete based on remote
- If IDs conflict but content differs, keep both (generate new ID for one)
- Log all sync operations for debugging

**Files:**
- `lib/services/firestore_sync_service.dart` - Main sync logic
- Add sync trigger: manual button + periodic background
- Show sync status indicator in UI

---

### 5B. Kit Tuning Framework
**Status:** Not started
**Problem:** No structured way to log and track bow tuning

**Requirements:**

1. **Bow Type Detection:**
   - Read `bowType` from selected bow
   - Show appropriate checklist for Recurve vs Compound

2. **Recurve Tuning Checklist:**
   ```
   RECURVE TUNING

   [ ] Brace height: [____] inches
   [ ] Nock point: [____] above square
   [ ] Tiller: ( ) Positive  ( ) Even  ( ) Negative
   [ ] Centershot: [____] mm from riser
   [ ] Plunger: ( ) Soft  ( ) Medium  ( ) Stiff

   PAPER TUNE RESULT:
   Tear direction: [Up][Down][Left][Right][Clean]
   Tear size: ( ) None  ( ) Small  ( ) Medium  ( ) Large

   BARE SHAFT RESULT:
   ( ) Stiff  ( ) Weak  ( ) Good

   Notes: [________________]
   ```

3. **Compound Tuning Checklist:**
   ```
   COMPOUND TUNING

   [ ] Cam timing: ( ) In sync  ( ) Top early  ( ) Bottom early
   [ ] Rest position: [____] mm
   [ ] Peep height: [____] inches
   [ ] D-loop length: [____] inches

   PAPER TUNE RESULT:
   Tear direction: [Up][Down][Left][Right][Clean]
   Tear size: ( ) None  ( ) Small  ( ) Medium  ( ) Large

   FRENCH TUNE RESULT:
   ( ) Left  ( ) Right  ( ) Good

   Notes: [________________]
   ```

4. **Paper Tune Logger (Description Only):**
   - NO photo capture
   - Select tear direction from options
   - Select tear size from options
   - Auto-suggest fixes based on pattern

5. **Tuning History:**
   - Timeline view of all tuning sessions
   - Show what was adjusted and results
   - Link to scoring sessions to see if groups improved

**Database:**
```sql
CREATE TABLE tuning_sessions (
  id TEXT PRIMARY KEY,
  bow_id TEXT REFERENCES bows(id),
  date TEXT NOT NULL,
  bow_type TEXT NOT NULL,
  brace_height REAL,
  nock_point REAL,
  tiller TEXT,
  centershot REAL,
  plunger TEXT,
  paper_tear_direction TEXT,
  paper_tear_size TEXT,
  bare_shaft_result TEXT,
  cam_timing TEXT,
  rest_position REAL,
  peep_height REAL,
  french_tune_result TEXT,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**Files:**
- `lib/db/database.dart` - New table
- New: `lib/screens/tuning_checklist_screen.dart`
- New: `lib/screens/tuning_history_screen.dart`
- New: `lib/models/tuning_session.dart`
- New: `lib/utils/tuning_suggestions.dart` - Auto-suggestions from tear patterns

---

### 5C. Clicks-Per-Ring Wizard
**Status:** Not started
**Problem:** No tool to calculate sight adjustment per ring

**Requirements:**
- Guided wizard (not free-form)
- User must achieve centered group before proceeding
- "Centered" threshold based on user's handicap
- POSSIBLY PREMIUM FEATURE (check entitlement)

**Wizard Flow:**
```
STEP 1: SELECT DISTANCE
"What distance are you tuning?"
[20m] [30m] [50m] [70m] [Custom: ___]

STEP 2: SHOOT BASELINE GROUP
"Shoot a group and plot it on the target."
[TARGET FACE FOR PLOTTING]

"Your group center is X rings from center."
[Based on handicap, you need to be within Y rings to proceed]

[NOT CENTERED - ADJUST AND RETRY]
or
[CENTERED - CONTINUE]

STEP 3: ADJUST SIGHT
"Move your sight a known amount."
Clicks moved: [____]  (or Turns: [____])

STEP 4: SHOOT ADJUSTED GROUP
"Shoot another group with the new sight setting."
[TARGET FACE FOR PLOTTING]

STEP 5: RESULTS
"Your group moved [Z] rings."
"Your sight adjustment is [X] clicks per ring at [distance]."

[SAVE TO PROFILE]  [TRY AGAIN]
```

**Centering Threshold by Handicap:**
```dart
double getCenteringThreshold(int handicap) {
  // Elite (handicap < 20): within 0.5 rings
  // Good (handicap 20-40): within 1 ring
  // Intermediate (handicap 40-60): within 1.5 rings
  // Beginner (handicap > 60): within 2 rings
  if (handicap < 20) return 0.5;
  if (handicap < 40) return 1.0;
  if (handicap < 60) return 1.5;
  return 2.0;
}
```

**Premium Check:**
```dart
if (isPremiumFeature('clicks_per_ring')) {
  if (!userHasEntitlement()) {
    showPremiumUpsell();
    return;
  }
}
```

**Files:**
- New: `lib/screens/clicks_per_ring_wizard.dart`
- New: `lib/models/sight_calibration.dart`
- `lib/db/database.dart` - Store calibration data per distance
- Check entitlement service for premium gate

---

### 5D. 252 Scheme Tracker
**Status:** Not started
**Problem:** No tracking for 252 club progression scheme

**Requirements:**
- BOTH: Auto-detect from sessions AND manual entry

**Auto-Detection:**
- When scoring session completes
- Check if round is qualifying (36-arrow imperial, 5-zone)
- If score >= 252, mark distance as achieved
- Prompt: "You scored 264! Mark [30 yards] as achieved?"

**Manual Entry:**
- Dedicated 252 tracker screen
- List all distances: 20, 30, 40, 50, 60, 80, 100 yards
- For each: achieved (yes/no), best score, date achieved
- Can manually mark achieved or enter historical scores

**UI:**
```
252 SCHEME PROGRESS

[X] 20 yards - 278 (12 Jan 2026)
[X] 30 yards - 264 (15 Jan 2026)
[ ] 40 yards - Best: 241
[ ] 50 yards - Not attempted
[ ] 60 yards - Not attempted
[ ] 80 yards - Not attempted
[ ] 100 yards - Not attempted

Progress: 2/7 distances

[+ LOG SCORE]
```

**Database:**
```sql
CREATE TABLE scheme_252 (
  id TEXT PRIMARY KEY,
  distance_yards INTEGER NOT NULL,
  achieved INTEGER DEFAULT 0,
  best_score INTEGER,
  achieved_date TEXT,
  session_id TEXT REFERENCES sessions(id),
  notes TEXT
);
```

**Files:**
- New: `lib/screens/scheme_252_screen.dart`
- `lib/providers/session_provider.dart` - Auto-detect logic
- `lib/db/database.dart` - New table

---

### 5E. Group Visualization Enhancements
**Status:** Not started
**Problem:** Group display could be more informative

**Requirements (ALL THREE):**

1. **Spread Ellipse:**
   - Draw oval showing group shape and orientation
   - Use statistical ellipse (covariance-based)
   - Semi-transparent gold fill
   - Shows if group is round vs elongated

2. **Color by End:**
   - Different color for arrows in each end
   - End 1: Gold, End 2: Cyan, End 3: Magenta, etc.
   - Legend showing which color = which end
   - Helps see consistency across ends

3. **Ring Notation:**
   - Display group size as "9.2 group" format
   - Calculate: average distance from group center, in ring units
   - Show on screen near group display
   - Decimal precision to 0.1

**Implementation:**
```dart
// Spread ellipse using covariance
Matrix2 covariance = calculateCovariance(arrowPositions);
EllipsePainter(center, covariance.eigenvalues, covariance.eigenvectors);

// Ring notation
double groupSizeRings = groupSpreadMm / ringWidthMm;
Text('${groupSizeRings.toStringAsFixed(1)} group');
```

**Toggle Controls:**
- Checkbox or chips to show/hide each visualization
- Remember preferences

**Files:**
- `lib/widgets/group_centre_widget.dart` - Add ellipse, colors
- `lib/widgets/target_face.dart` - Color arrows by end
- `lib/utils/group_analysis.dart` - Ellipse math, ring notation

---

### 5F. Front Camera Default
**Status:** Not started
**Problem:** Camera defaults to rear, should be front (selfie)

**Requirements:**
- Front camera is DEFAULT
- Option to switch to rear camera if desired
- Camera switch button visible in UI

**Files:**
- `lib/screens/delayed_camera_native.dart`
- `lib/screens/delayed_camera_web.dart`

---

## Implementation Order Summary

1. **Session 1 (Quick):**
   - Splash logo fix
   - Default 2x zoom

2. **Session 2 (Bugs):**
   - Volume save fix
   - Vibrations fix

3. **Session 3 (UI):**
   - Breathing cues visibility
   - Front camera default

4. **Session 4 (Features):**
   - Exhale test redesign
   - Equipment log expansion

5. **Session 5 (Features):**
   - Shaft tracking in plotting

6. **Session 6+ (Major):**
   - Inter-device sync
   - Kit tuning framework
   - Clicks-per-ring wizard
   - 252 scheme tracker
   - Group visualization

---

## Quick Reference: Existing vs New

| Feature | Already Exists | Needs Building |
|---------|----------------|----------------|
| **Splash logo** | Splash screen exists | Wrong image, add "built by HUSTON ARCHERY" |
| **2x zoom default** | Pinch zoom, smart zoom, minZoom=2 | Set initial zoom to 2x |
| **Volume save** | Import screen, DB tables | Fix save verification |
| **Vibrations** | BeepService (audio only) | Add HapticFeedback calls |
| **Breathing cues** | All 3 breath screens work | Reposition for web visibility |
| **Front camera** | Camera screens exist | Swap default lens |
| **Exhale test** | PatrickBreathScreen (basic) | Complete redesign with record panel |
| **Equipment log** | Bows, Quivers, Shafts tables | Expand all schemas, add Stabilizers |
| **Shaft tracking** | Toggle, bottom sheet, shaft number storage | Nock rotation, remember pref, analysis |
| **Inter-device sync** | FirestoreSyncService skeleton | Full merge logic, conflict resolution |
| **Kit tuning** | bowType field exists | New TuningSessions table, screens |
| **Clicks-per-ring** | Nothing | Entire wizard from scratch |
| **252 scheme** | 5-zone scoring works | New table, tracking screen |
| **Group viz** | GroupCentreWidget | Ellipse, color by end, ring notation |

## Database Migrations Required

When adding columns/tables, increment schema version and add migration:

```dart
// In database.dart
static const int schemaVersion = X; // Increment from current

// In migration switch:
case X-1:
  // Add new columns/tables here
  await m.addColumn(arrows, arrows.nockRotation);
  // etc.
```

**New Tables Needed:**
- `stabilizers` (for 4B)
- `tuning_sessions` (for 5B)
- `scheme_252` (for 5D)
- `kit_snapshots` (for kit auto-prompt)
- `sight_calibrations` (for 5C)

**Column Additions:**
- `arrows.nock_rotation` TEXT nullable
- `bows.poundage` REAL nullable
- `bows.limb_model` TEXT nullable
- `bows.purchase_date` TEXT nullable
- `shafts.spine` INTEGER nullable
- `shafts.length_inches` REAL nullable
- `shafts.point_weight_grains` INTEGER nullable
- (see full list in 4B)

---

*Generated: January 2026*
*All requirements confirmed with Patrick - implement without further questions*
