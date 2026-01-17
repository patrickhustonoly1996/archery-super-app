# PRD: Archery Super App - Outstanding Fixes & Features

**Version:** 1.0  
**Date:** January 2026  
**Author:** Claude (Build Partner)  
**Status:** Draft

---

## Executive Summary

This PRD covers the remaining P1 and P2 features from the FIXES_NEEDED document that have not yet been implemented. Items marked ✅ FIXED have been excluded. Features requiring investigation are listed separately from those with complete specs ready for implementation.

---

## 1. Features Ready for Implementation

These features have detailed specs and can be built without further investigation.

### 1.1 Kit Details Auto-Prompt on Top 20% Score (P2)

**Problem:** When an archer achieves a score in their top 20% historically, they should be prompted to save their current kit configuration - that setup is clearly working well.

**Trigger Logic:**
- After session completes, calculate 80th percentile of all historical scores
- If current score >= threshold, show prompt
- Skip if <5 total sessions (insufficient data)

**Deliverables:**
1. `lib/utils/statistics.dart` - Percentile calculation utility
2. `lib/models/kit_snapshot.dart` - KitSnapshot model
3. Database migration - New `KitSnapshots` table (id, bowId, quiverId, snapshotDate, sessionId, score, settings JSON)
4. `lib/providers/equipment_provider.dart` - Kit snapshot save/load methods
5. Session complete screen modification - Bottom sheet prompt: "Great score! Save your current kit setup?"

**Acceptance Criteria:**
- [ ] Percentile calculation handles edge cases (empty list, single item)
- [ ] Prompt only shows when score is top 20%
- [ ] Prompt does not show with <5 historical sessions
- [ ] Kit snapshot saves current bow and quiver settings
- [ ] Kit snapshots viewable from equipment screen

---

### 1.2 Kit Tuning Framework (P2)

**Problem:** Need structured way to log and track bow tuning. Different checklists for recurve vs compound.

**Bow Type Checklists:**

| Recurve | Compound |
|---------|----------|
| Brace height | Cam timing |
| Nock point | Yoke tuning |
| Tiller | Rest position |
| Centershot | Peep height |
| Plunger tension | Paper tune |
| Paper tune | Bare shaft |
| Bare shaft | French tune |
| Walk-back | |

**Deliverables:**
1. Database migration - New `TuningSessions` table (id, bowId, date, bowType, tuningType, results JSON, notes)
2. `lib/models/tuning_session.dart` - Data model
3. `lib/screens/tuning_checklist_screen.dart` - Main checklist UI (detects bow type)
4. `lib/screens/tuning_history_screen.dart` - Timeline of tuning sessions
5. `lib/utils/tuning_suggestions.dart` - Auto-suggestions from tear patterns

**Paper Tune Logger Features:**
- Capture tear direction (up/down/left/right/clean)
- Capture tear size (small/medium/large)
- Suggest fixes based on tear pattern
- Store history of attempts

**Acceptance Criteria:**
- [ ] Correct checklist shown based on bow type
- [ ] Paper tune results logged with suggestions
- [ ] Tuning history displays timeline
- [ ] Tuning data persists across sessions

---

### 1.3 Arrow Shaft Tracking & Analysis (P2)

**Problem:** Need to track individual arrow performance for both specs and shot tracking.

**Part A: Arrow Specifications**

Expand Shafts table with:
- spine (int)
- lengthInches (double)
- pointWeight (int, grains)
- fletchingType (string)
- fletchingColor (string)
- nockColor (string)

**Part B: Shot Tracking**

Add `shaftId` (nullable) to Arrows table to link each plotted arrow to a specific shaft.

**Deliverables:**
1. Database migration - Expand Shafts table, add shaftId to Arrows
2. `lib/screens/shaft_detail_screen.dart` - Spec entry form with batch mode
3. Plotting screen modification - Arrow number picker (1-12 chips)
4. `lib/utils/shaft_analysis.dart` - Per-arrow analysis:
   - Average position deviation
   - Group spread per arrow
   - Score distribution
   - Outlier detection
5. `lib/screens/shaft_analysis_screen.dart` - Results UI with recommendations
6. Overlap likelihood calculation - Warning when group tight enough for robin-hoods

**Acceptance Criteria:**
- [ ] Arrow specs can be entered individually or batch
- [ ] Shaft picker appears during plotting (optional use)
- [ ] Analysis shows per-arrow performance
- [ ] Outliers identified with retirement suggestions
- [ ] Overlap risk warning displays when appropriate

---

## 2. Features Requiring Investigation

These features are reported but need investigation before specs can be written.

### 2.1 Menu Scrolling Issue (P1)

**Status:** Needs investigation  
**File:** `lib/screens/home_screen.dart`  
**Question:** What specific scrolling issue? Janky? Doesn't scroll? Wrong scroll physics?

**Next Step:** User to describe/demonstrate the issue, then spec can be written.

---

### 2.2 Arrows Not Dropping (P1)

**Status:** Needs investigation  
**Files:** `lib/screens/plotting_screen.dart`, `lib/widgets/target_face.dart`  
**Question:** Is it touch detection? Visual feedback? Database not saving?

**Next Step:** User to describe when arrows don't drop (specific device? specific conditions?), then debug.

---

### 2.3 Volume Input Interface Saves (P1)

**Status:** Needs investigation  
**Files:** `lib/screens/volume_import_screen.dart`, `lib/db/database.dart`  
**Question:** What's not saving? Manual entry? CSV import? Both?

**Next Step:** User to describe failure scenario, then debug.

---

### 2.4 Inter-Device Data Push (P1)

**Status:** Needs investigation  
**File:** `lib/services/firestore_sync_service.dart`  

**High-Level Requirements:**
- Push local data to Firestore
- Pull remote data to local
- Conflict resolution strategy needed
- User authentication linkage

**Next Step:** Determine sync scope (all data? selective?), conflict resolution preference (last-write-wins? manual merge?), auth flow.

---

### 2.5 Selfie Camera (P1)

**Status:** Needs investigation  
**Files:** `lib/screens/delayed_camera_native.dart`, `lib/screens/delayed_camera_web.dart`  
**Question:** Camera switching? Front camera not available? Mirror mode?

**Next Step:** User to describe what's not working.

---

### 2.6 Breathing Cues Visibility (P1)

**Status:** Needs investigation  
**Files:** `lib/screens/breath_training/*.dart`  
**Question:** Text too small? Low contrast? Need larger visual indicator?

**Next Step:** User to describe what's hard to see.

---

### 2.7 Haptic Feedback / Beeps (P1)

**Status:** Needs investigation  
**Files:** `lib/services/beep_service.dart`, `lib/providers/bow_training_provider.dart`  
**Question:** Not triggering? Wrong timing? Web vs native differences?

**Next Step:** User to describe which platform/feature is affected.

---

### 2.8 Exhale Test Structure Edit (P1)

**Status:** Needs investigation  
**Files:** `lib/screens/breath_training/breath_hold_screen.dart`  
**Question:** What structure changes needed? Different phases? Timing adjustments?

**Next Step:** User to describe desired structure.

---

### 2.9 Equipment Log Details (P1)

**Status:** Needs investigation  
**Files:** `lib/screens/equipment_screen.dart`, `lib/screens/bow_form_screen.dart`  
**Question:** What details missing? Arrow counts? Maintenance logs? Usage history?

**Next Step:** User to describe what information they want to track.

---

## 3. Future Features (Backlog)

Captured ideas for future consideration - not yet prioritized.

| Feature | Description |
|---------|-------------|
| Clicks-Per-Ring Training | User-defined exercise to learn sight adjustment ratios |
| 252 Scheme Tracker | Club progression system tracking 36-arrow imperial rounds |
| Group Visualization | Spread ellipse, arrow trails by end, ring notation sizing |
| Score Sanity Checks | Flag perfect scores, huge handicap jumps for verification |

---

## 4. Implementation Priority

**Recommended order for specced features:**

1. **Kit Details Auto-Prompt** (P2) - Quick win, useful immediately
2. **Arrow Shaft Tracking** (P2) - High value for serious training
3. **Kit Tuning Framework** (P2) - Comprehensive but larger scope

**Investigation items** should be addressed as Patrick can provide details on what's broken.

---

## 5. Technical Notes

**Offline-First Requirement:** All features must work without network. Database changes use local SQLite (Drift). Sync features (1.4) handle offline gracefully.

**Design Compliance:**
- Dark base + Gold (#FFD700) primary
- Monospace fonts only (VT323, Share Tech Mono)
- 8px grid, minimal animation

---

*End of PRD*