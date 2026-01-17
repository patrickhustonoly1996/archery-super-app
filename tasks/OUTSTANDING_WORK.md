# Outstanding Work

**Updated:** 2026-01-17

---

## URGENT: Arrow Plotting Fixes (In Progress)

**Context:** User reported multiple issues with arrow plotting system.

### Issues Reported:
1. **Blurry lines** - Target ring lines look fuzzy on screen
2. **Auto-zoom for linecutter** - Remove this, replace with in/out question
3. **Not auto-advancing** - Stuck after plotting 3 arrows (doesn't auto-move to next end)
4. **Touch position mismatch** - Arrow placement doesn't match where user touches
5. **Low resolution feel** - "placing arrows into low res pixel target"

### What Was Attempted:
The root cause of issues #1-4 is `Transform.scale` in `InteractiveTargetFace`. The target is rendered at 300px then scaled 2x, causing:
- Blurry rasterization
- Coordinate space mismatch (touch vs visual)

**Attempted fix:** Remove `Transform.scale` and render directly at widget size.

**Problem:** Tests started failing after the refactor. The changes are stashed but need careful rework.

### Files Changed (in stash):
- `lib/widgets/target_face.dart` - Main changes
- `lib/screens/plotting_screen.dart` - Added `await` to plotArrow call
- `test/widgets/target_face_test.dart` - Updated for new structure

### How to Resume:
1. The original code works (tests pass)
2. Need to make MINIMAL changes:
   - Keep `Transform.scale` for now (it works)
   - Just add the in/out linecutter dialog
   - Fix the `await` for plotArrow in plotting_screen.dart
3. For blurry lines, try increasing `strokeWidth` from 1 to 1.5-2.0 first
4. Coordinate resolution issue may need separate investigation

### Test Command:
```bash
flutter test test/widgets/target_face_test.dart
```

---

## P1: Needs Investigation

These items need you to describe the issue before they can be fixed.

| # | Issue | File(s) | Notes |
|---|-------|---------|-------|
| 1 | Volume Input Not Saving | `volume_import_screen.dart` | Manual entry? CSV import? Both? |
| 2 | Inter-Device Sync | `firestore_sync_service.dart` | Scope? Conflict resolution? Auth flow? |
| 3 | Breathing Cues Visibility | `breath_training/*.dart` | Text too small? Low contrast? |
| 4 | Equipment Log Details | `equipment_screen.dart` | What details missing? |

---

## Specced: Ready to Build

### Vibrations Feature - ✅ IMPLEMENTED

**Status:** Core implementation complete (2026-01-17)

**What's done:**
- ✅ `lib/services/vibration_service.dart` - Wraps HapticFeedback with toggle (default ON)
- ✅ `lib/services/training_session_service.dart` - Wake lock management
- ✅ All training screens updated to use VibrationService
- ✅ All HapticFeedback calls replaced with service calls
- ✅ Wake lock enabled during training sessions (screen stays on)

**Vibration patterns:**
| Context | Pattern |
|---------|---------|
| Session start | Medium |
| Phase change | Light |
| Round/exercise complete | Heavy |
| Session complete | Double |
| Countdown ticks | Selection |

**Still TODO:**
- Settings UI toggle (currently default ON, no UI to change)

---

## Background Execution (Screen Lock)

**Current approach:** Wake Lock (PWA-compatible)
- Screen stays on during training sessions
- Vibrations + beeps work
- Phone can be face-down on table

**Future (requires native app builds):** True pocket mode
- Phone locked in pocket, still vibrating/beeping
- Needs audio_service + native iOS/Android builds
- For breath hold exercise schemes where phone is in pocket

---

## Future Ideas (Backlog)

### Radar Skill System (RuneScape-style)

**Concept:** Persistent mini radar graph showing archer profile across multiple dimensions. Appears in app bar corner (tappable to expand) and on home menu.

**Potential dimensions:**
- **Bow Fitness** - Oly training progression (1.0-2.5 scale feeds into this)
- **Volume** - Arrows shot / training hours logged
- **Tuning** - Kit checklist completion, tuning knowledge
- **Equipment** - Shaft data completeness, setup documentation
- **Mental** - Focus exercises, breath training, pressure work

**Display ideas:**
- Tiny radar icon in top corner of each page
- Expandable to full detail view on tap
- "Total level" number (sum/average) next to mini radar
- Visual feedback / celebration on level-ups

**Progression:**
- Each skill 1-99 or 1.0-10.0 scale
- XP earned by completing sessions, logging data, using features
- Motivates engagement across all app areas

**Open questions:**
- Snapshot display vs. gamified progression system?
- Which dimensions matter most?
- How prominent should it be?

---

| Feature | Description |
|---------|-------------|
| Clicks-Per-Ring Training | Learn sight adjustment ratios |
| 252 Scheme Tracker | Club progression for imperial rounds |
| Group Visualization | Spread ellipse, arrow trails, ring notation |
| Score Sanity Checks | Flag perfect scores, huge handicap jumps |

---

## Recently Completed

For reference - these are done:

- ✅ Kit Details Auto-Prompt (top 20% score triggers kit save)
- ✅ Kit Tuning Framework (recurve/compound checklists, paper tune logger)
- ✅ Arrow Shaft Tracking & Analysis (specs, shot tracking, analysis)
- ✅ Exhale Test Structure (configurable duration, difficulty levels, progression)
- ✅ Menu Scrolling, Arrows Not Dropping, Selfie Camera
- ✅ Vibrations + Wake Lock (default ON, screen stays on during training)

See `docs/FIXES_NEEDED.md` for full history of all fixes.
