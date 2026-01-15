# Fixes Needed

Tracked issues from investigation sessions. Each section has enough detail to implement without re-investigation.

---

## Branches To Merge

These branches have useful features that should be merged into main. They're from older sessions so expect merge conflicts - resolve carefully.

### handicap-graph (KEEP)
**Branch:** `origin/claude/archery-handicap-graph-ySjH2`
**What it adds:**
- Time filters: 1m, 3m, 6m, 9m, 12m, 2y, 5y, custom date range
- Milestone markers on graph (PBs, classifications)
- New `Milestones` database table

### volume-upload (KEEP)
**Branch:** `origin/claude/arrow-volume-upload-NJ9nO`
**What it adds:**
- Dedicated upload screen with better UX
- Column mapping for CSV imports
- Paste data support
- Preview before import

### arrow-specs (KEEP)
**Branch:** `origin/claude/bow-equipment-specs-NadxK`
**What it adds:**
- Comprehensive arrow specifications for quivers
- Equipment detail tracking

### sessions-memory (KEEP)
**Branch:** `origin/claude/add-training-intro-screen-VkAap`
**What it adds:**
- Session memory (remembers last session type)
- Favorites system
- Custom session builder

**Note:** When merging, keep schema version 6+ and add new tables/migrations incrementally.

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

**Status:** Not started
**Problem:** York, Bristol, Warwick, Albion etc use 5-zone scoring (9-7-5-3-1 by color) but app only supports 10-zone.

**Current Code:**
- `lib/db/round_types_seed.dart` - Rounds defined but no `scoringType` field
- `lib/theme/app_theme.dart:295-313` - `scoreFromDistanceMm()` hardcoded to return ring number

**Implementation Steps:**

1. Add `scoringType` column to RoundTypes table
   - File: `lib/db/database.dart`
   - Values: `'10-zone'` (default), `'5-zone'`
   - Requires database migration

2. Update round_types_seed.dart
   - Add `scoringType: '5-zone'` to all `agb_imperial` category rounds
   - File: `lib/db/round_types_seed.dart:177-515`

3. Modify scoring function
   - File: `lib/theme/app_theme.dart:295`
   - Add parameter: `String scoringType = '10-zone'`
   - For 5-zone, map rings to scores:
     ```dart
     if (scoringType == '5-zone') {
       // Gold (X/10/9) → 9
       if (ring >= 9) return 9;
       // Red (8/7) → 7
       if (ring >= 7) return 7;
       // Blue (6/5) → 5
       if (ring >= 5) return 5;
       // Black (4/3) → 3
       if (ring >= 3) return 3;
       // White (2/1) → 1
       if (ring >= 1) return 1;
       return 0;
     }
     ```

4. Pass scoring type through plotting flow
   - `PlottingScreen` → `InteractiveTargetFace` → scoring calculation
   - Or: look up round's scoring type when calculating score

5. Update tests
   - Add 5-zone scoring tests to `test/utils/handicap_calculator_test.dart`
   - Test boundary cases (ring 9 vs 8, ring 7 vs 6, etc.)

**Visual stays the same** - still show all 10 rings on target face. Only the numbers change.

---

## P2: Volume Graph Visibility

**Status:** Not started
**Issues:**
- Hard to see with red light glasses (night mode)
- Needs time period selector (week/month/year/all)
- Needs date/title visibility on graph

**Files likely involved:**
- `lib/widgets/volume_chart.dart`
- `lib/screens/` - wherever volume graph is displayed

**Implementation:**
- Increase contrast/line thickness
- Add gold accent color for better visibility on dark
- Add dropdown/segmented control for time period
- Add axis labels and title

---

## P2: Timer Pause When App Backgrounds

**Status:** Not started (from code review doc)
**Problem:** Bow training timer keeps running when app goes to background, ruining training sessions.

**Files:**
- `lib/providers/bow_training_provider.dart`

**Fix:**
- Listen to `AppLifecycleState` changes
- Pause timer on `paused`/`inactive`
- Resume on `resumed`

---

## P2: Linecutter Auto-Zoom

**Status:** Not started
**Problem:** When plotting an arrow near a ring boundary (linecutter), the user needs precision to decide which ring it's in. Currently no automatic zoom assistance.

**Desired Behavior:**
- Detect when arrow preview is near a ring boundary (within ~1-2% of ring width)
- Auto-zoom to that area for precision placement
- Visual indicator showing which ring boundary is nearby
- Possibly: snap-to-boundary option with manual override

**Files likely involved:**
- `lib/widgets/target_face.dart` - zoom window rendering
- `lib/utils/target_coordinate_system.dart` - has `nearestBoundary()` detection already
- `lib/utils/smart_zoom.dart` - zoom calculations

**Existing code to build on:**
```dart
// In target_coordinate_system.dart:178-210
nearestBoundary(coord, thresholdPercent: 1.5)
// Returns {ring, distanceMm} if near a boundary
```

**Implementation idea:**
1. During drag, check if preview position is near boundary
2. If yes, increase zoom level and center on that boundary region
3. Show visual cue (highlight the boundary line)
4. On release, use precise position for scoring

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
