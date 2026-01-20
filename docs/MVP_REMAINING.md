# MVP - Remaining Work

Updated 2026-01-17. Core MVP complete. Below are optional enhancements and deferred items.

---

## Optional Enhancement

### Color arrows by end
- Pass end info to TargetFace widget
- Render arrows with different colors based on end number
- Add preference toggle

---

## Post-MVP (Defer)

- Clicks-per-ring wizard
- 252 scheme tracker
- OLY training system upgrade

---

## Routines Builder UI

**Status:** Backend ready, UI missing

**What exists:**
- `CustomBowSession` model in `lib/providers/bow_training_provider.dart` (lines 89-128)
- `CustomExercise` model (lines 132-164)
- Provider methods: `saveCustomSession()`, `deleteCustomSession()`, `startSavedSession()`
- `availableExerciseTypes` getter returns list of exercise types from DB
- `customSessions` getter returns saved routines

**What's needed:**
A `RoutineBuilderScreen` that lets users:
1. Name the routine
2. Add exercises from `availableExerciseTypes` (e.g., Static Reversals, Dynamic Holds)
3. Configure each exercise: reps, hold seconds, rest seconds
4. Reorder exercises (drag & drop)
5. Preview total duration
6. Save → calls `provider.saveCustomSession(CustomBowSession(...))`
7. Manage saved routines (edit/delete from list)

**Entry point:** Add "Create Routine" button in `BowTrainingHomeScreen` alongside "Custom Timer"

**Exercise types available:** Query via `BowTrainingProvider.availableExerciseTypes` - includes exercise name, description, default intensity
