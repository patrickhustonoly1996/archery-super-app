# OLY Bow Training System Implementation Plan

## Summary

Upgrade the Bow Training feature from simple hold/rest presets to the full OLY Training System with multi-exercise sessions (S1.0 through S2.5), post-session feedback, and progression suggestions.

---

## Current State vs Target

| Feature | Current | Target |
|---------|---------|--------|
| Sessions | 4 simple presets (hold/rest repeated) | 20+ OLY levels (S0.3 - S2.5) |
| Exercises | Single type per session | 6-12 different exercises per session |
| Exercise types | None | 10 types with intensity multipliers |
| Feedback | None | 3-scale (shaking, structure, rest) |
| Progression | Manual | Auto-suggest based on feedback |

---

## Implementation Phases

### Phase 1: Database Schema

**New tables to add in `lib/db/database.dart`:**

1. **ExerciseTypes** - Master list of exercise types with intensity multipliers
2. **SessionTemplates** - OLY session definitions (S1.0 through S2.5)
3. **SessionTemplateExercises** - Exercises within each session template
4. **BowTrainingFeedback** - Post-session feedback for progression
5. **UserTrainingProgress** - Tracks user's level and progression

**Migration:** Schema version 3 → 4, seed all exercise types and session templates.

**Files to modify:**
- `lib/db/database.dart` - Add tables, migration, queries
- Create `lib/db/oly_training_seed.dart` - Hardcoded seed data from CSVs

---

### Phase 2: Provider Extensions

**Extend `lib/providers/bow_training_provider.dart`:**

```dart
// New state for OLY sessions
SessionTemplate? _activeOlySession;
List<SessionTemplateExercise> _exercises = [];
int _currentExerciseIndex = 0;
int _currentRepInExercise = 0;

// Mode detection
bool get isOlySession => _activeOlySession != null;

// New methods
void startOlySession(SessionTemplate template, List<SessionTemplateExercise> exercises);
SessionTemplateExercise? get currentExercise;
int get currentExerciseNumber => _currentExerciseIndex + 1;
int get totalExercises => _exercises.length;
```

**State machine changes in `_advancePhase()`:**
- After completing reps for one exercise, advance to next exercise
- Add `exerciseTransition` phase (1-2 second pause between exercises)
- Track per-exercise completion

**Backward compatibility:** Keep `startSession(BowTrainingPreset)` working for custom presets.

---

### Phase 3: UI Changes

**Modify `lib/screens/bow_training_screen.dart`:**

1. **Session Selection** - Add tabs:
   - "OLY Sessions" - Grouped by level (1.x, 2.x)
   - "My Presets" - Existing simple presets

2. **Active Timer View** - Add:
   - Exercise name display ("Static reversals")
   - Exercise details ("Push arm forward 3x5s")
   - "Exercise 3 of 9" counter
   - Overall session progress bar

3. **Completion View** - Add:
   - 3-scale feedback sliders
   - Progression suggestion display

**New widgets to create:**
- `OlySessionCard` - Displays session with version, duration, focus
- `OlySessionLevelGroup` - Collapsible group of sessions by level
- `ExerciseInfoDisplay` - Current exercise name/details during timer
- `FeedbackSheet` - Three 1-10 sliders for post-session rating

---

### Phase 4: Feedback & Progression

**Progression logic:**
```
// Regress if:
- completionRate < 70%
- any feedback score > 7
- average feedback > 6

// Progress if:
- average feedback < 4
- completionRate >= 100%
- 3+ sessions at current level

// Otherwise: repeat current level
```

---

## File Summary

| File | Changes |
|------|---------|
| `lib/db/database.dart` | Add 5 new tables, migration, CRUD methods |
| `lib/db/oly_training_seed.dart` | NEW - Hardcoded exercise types + all session templates |
| `lib/providers/bow_training_provider.dart` | Add OLY session state, multi-exercise timer logic |
| `lib/screens/bow_training_screen.dart` | Tabbed selection, exercise display, feedback UI |

---

## Verification

1. **Fresh install:** App seeds all 20+ OLY sessions, exercise types load
2. **Migration:** Existing users keep their custom presets, gain OLY sessions
3. **Run S1.5:** Timer steps through 9 exercises with correct timing
4. **Feedback:** After session, 3 sliders work, saves to database
5. **Progression:** Completing S1.5 with good feedback suggests S1.6
6. **Backward compat:** Simple "Beginner (10s hold)" preset still works

---

## Data Sources

- **Exercise types:** `training_spreadsheets/Overview-Exercise list.csv`
- **Session templates:** `training_spreadsheets/S1.0-Session plan.csv` through `S2.5-Session plan.csv`
- **Spec document:** `docs/bow_training_system_spec.md`

---

## Progress Tracking

- [ ] Phase 1: Database schema and seed data
- [ ] Phase 2: Provider extensions
- [ ] Phase 3: UI changes
- [ ] Phase 4: Feedback and progression
- [ ] Build, deploy, and verify
