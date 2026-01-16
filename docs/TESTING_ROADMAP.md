# Testing Strategy: Reliable App for Training

**For:** Patrick Huston
**Purpose:** Ensure the app works correctly every time you use it
**Last Updated:** 2026-01-16

---

## Current Status

**Test Lines:** ~25,600 | **Production Lines:** ~53,400 | **Ratio:** 1:2.1 ✅
**Target Ratio:** 1:3 (industry standard for mobile apps) — **EXCEEDED**
**Tests:** 1,348 passing | **Test Files:** 36

---

## Coverage Summary

| Category | Files | Tested | Coverage | Notes |
|----------|-------|--------|----------|-------|
| Models | 2 | 2 | **100%** ✅ | Core math verified |
| Utils | 8 | 7 | **88%** ✅ | sample_data_generator excluded (dev-only) |
| Providers | 5 | 5 | **100%** ✅ | All state management covered |
| Services | 5 | 5 | **100%** ✅ | All services fully tested |
| Database | 3 | 3 | **100%** ✅ | Full CRUD + integrity tests |
| Widgets | 11 | 8 | **73%** ✅ | All critical widgets tested |
| Integration | - | 4 | **100%** ✅ | Full flow tests added |

---

## Critical Gaps — ALL RESOLVED ✅

### Gap 1: Database Operations - ~~CRITICAL~~ RESOLVED ✅
**File:** `lib/db/database.dart`
**Status:** Fully tested in `test/db/database_test.dart`

**Tests Implemented:**
- [x] CRUD operations for sessions (create, read, update, delete)
- [x] CRUD operations for arrows with coordinate validation
- [x] CRUD operations for equipment (bows, quivers, shafts)
- [x] Query methods (getSessionsByDate, getArrowsForEnd, etc.)
- [x] Data integrity (foreign key relationships, cascade deletes)
- [x] Edge cases (empty results, null handling, concurrent access)

**Completion:** 2026-01-16 | **Tests Added:** 89

---

### Gap 2: CSV Import Parsing - ~~HIGH~~ RESOLVED ✅
**Files:** `lib/services/import_service.dart` (extracted from screens)
**Status:** Fully tested in `test/services/import_service_test.dart`

**Tests Implemented:**
- [x] Valid CSV parsing (happy path)
- [x] Malformed CSV handling (missing columns, extra columns)
- [x] Date format variations (ISO, US, UK formats)
- [x] Score validation (valid values only)
- [x] Empty file handling
- [x] Large file handling
- [x] Duplicate detection
- [x] Error reporting with line numbers

**Completion:** 2026-01-16 | **Tests Added:** 67

---

### Gap 3: Breath Training Service - ~~MEDIUM~~ RESOLVED ✅
**File:** `lib/services/breath_training_service.dart`
**Status:** Fully tested in `test/services/breath_training_service_test.dart`

**Tests Implemented:**
- [x] Session state transitions (start, pause, resume, complete, cancel)
- [x] Timer accuracy with fake async
- [x] Phase progression logic (inhale → hold → exhale)
- [x] Session completion detection
- [x] Persistence integration

**Completion:** 2026-01-16 | **Tests Added:** 45

---

### Gap 4: Chart Widgets - ~~MEDIUM~~ RESOLVED ✅
**Files:** `volume_chart.dart`, `handicap_chart.dart`, `group_centre_widget.dart`
**Status:** Fully tested in `test/widgets/` directory

**Tests Implemented:**
- [x] Data transformation logic (not rendering)
- [x] Edge cases (empty data, single point, negative values)
- [x] Axis scaling calculations
- [x] Group centre position calculations
- [x] Sight click display values
- [x] Date range filtering
- [x] Period selector functionality

**Completion:** 2026-01-16 | **Tests Added:** 78

---

## Step-by-Step Action Plan

### Phase A: Database Tests (Week 1-2)
**Priority:** CRITICAL | **Owner:** Claude

#### Step A1: Create database test infrastructure
```
File: test/db/database_test.dart
- Set up in-memory test database
- Create test fixtures for sessions, arrows, equipment
- Helper methods for common test patterns
```

#### Step A2: Test session operations
```
Tests to write:
1. createSession() - creates with valid data
2. createSession() - generates unique ID
3. getSession() - retrieves by ID
4. getSession() - returns null for missing ID
5. updateSession() - updates existing
6. deleteSession() - removes and cascades to arrows
7. getAllSessions() - returns all, ordered by date
8. getSessionsByDateRange() - filters correctly
```

#### Step A3: Test arrow operations
```
Tests to write:
1. createArrow() - creates with valid coordinates
2. createArrow() - validates score range (0-10)
3. getArrowsForSession() - returns correct arrows
4. getArrowsForEnd() - filters by end number
5. updateArrow() - updates position and score
6. deleteArrow() - removes single arrow
7. deleteArrowsForSession() - bulk delete
```

#### Step A4: Test equipment operations
```
Tests to write:
1. CRUD for bows (create, read, update, delete)
2. CRUD for quivers
3. CRUD for shafts
4. Equipment relationships (quiver -> shafts)
5. Active equipment selection
```

#### Step A5: Test data integrity
```
Tests to write:
1. Foreign key constraints work
2. Cascade deletes work
3. No orphaned records
4. Concurrent access handling
```

---

### Phase B: Import Tests (Week 2-3)
**Priority:** HIGH | **Owner:** Claude

#### Step B1: Extract parsing logic
```
Current state: Parsing embedded in screen widgets
Action: Extract to testable service class
File: lib/services/import_service.dart
```

#### Step B2: Create import test file
```
File: test/services/import_service_test.dart
```

#### Step B3: Test CSV parsing
```
Tests to write:
1. parseScoresCsv() - valid file parses correctly
2. parseScoresCsv() - handles different date formats
3. parseScoresCsv() - validates score values
4. parseScoresCsv() - reports row-level errors
5. parseScoresCsv() - handles missing optional columns
6. parseScoresCsv() - rejects missing required columns
7. parseScoresCsv() - handles UTF-8 BOM
8. parseScoresCsv() - handles Windows line endings
```

#### Step B4: Test volume import
```
Tests to write:
1. parseVolumeCsv() - valid file parses correctly
2. parseVolumeCsv() - validates arrow counts
3. parseVolumeCsv() - handles date variations
4. parseVolumeCsv() - reports errors with line numbers
```

#### Step B5: Test error handling
```
Tests to write:
1. Empty file returns helpful error
2. Binary file rejected gracefully
3. Extremely large file handled (or rejected with message)
4. Partial success reports what worked and what failed
```

---

### Phase C: Breath Training Service (Week 3)
**Priority:** MEDIUM | **Owner:** Claude

#### Step C1: Create test file
```
File: test/services/breath_training_service_test.dart
```

#### Step C2: Test session lifecycle
```
Tests to write:
1. startSession() - initializes state correctly
2. pauseSession() - pauses timer
3. resumeSession() - resumes from paused state
4. completeSession() - calculates final stats
5. cancelSession() - cleans up state
```

#### Step C3: Test breath hold logic
```
Tests to write:
1. Hold timer increments correctly
2. Personal best detection
3. Recovery phase timing
4. Session statistics calculation
```

#### Step C4: Test paced breathing logic
```
Tests to write:
1. Phase transitions (inhale -> hold -> exhale)
2. Configurable phase durations
3. Cycle counting
4. Audio cue timing
```

---

### Phase D: Chart Widget Tests (Week 4)
**Priority:** MEDIUM | **Owner:** Claude

#### Step D1: Test volume chart calculations
```
File: test/widgets/volume_chart_test.dart
Tests to write:
1. EMA line calculations match volume_calculator
2. Empty data renders without crash
3. Single data point handled
4. Date range filtering works
5. Y-axis scaling appropriate for data range
```

#### Step D2: Test handicap chart calculations
```
File: test/widgets/handicap_chart_test.dart
Tests to write:
1. Handicap points plotted correctly
2. Trend line calculation
3. Empty data handled
4. Date filtering works
```

#### Step D3: Test group centre widget
```
File: test/widgets/group_centre_widget_test.dart
Tests to write:
1. Centre position calculated correctly
2. Sight click values display correctly
3. Direction indicators (L/R, U/D) correct
4. Zero adjustment case handled
5. Large adjustment warning
```

---

### Phase E: Screen Integration Tests (Week 5+)
**Priority:** LOW | **Owner:** Claude (when time permits)

#### Step E1: Plotting flow test
```
File: test/integration/plotting_flow_test.dart
Tests:
1. Start session -> Plot arrows -> View scores -> Complete
2. Resume incomplete session
3. Delete arrow during session
```

#### Step E2: Import flow test
```
File: test/integration/import_flow_test.dart
Tests:
1. Select file -> Preview -> Confirm -> View imported
2. Cancel mid-import
3. Handle import errors
```

#### Step E3: Training flow tests
```
Files: bow_training_flow_test.dart, breath_training_flow_test.dart
Tests:
1. Select exercise -> Run -> Complete -> View log
2. Pause and resume
3. Cancel mid-session
```

---

## Test Writing Guidelines for Claude

### Before Writing Tests
1. Run `flutter test` to verify baseline
2. Read the source file thoroughly
3. Identify: inputs, outputs, side effects, edge cases

### Test Structure
```dart
group('FeatureName', () {
  // Setup
  late MyClass sut; // System Under Test

  setUp(() {
    sut = MyClass();
  });

  test('does X when Y', () {
    // Arrange
    final input = ...;

    // Act
    final result = sut.method(input);

    // Assert
    expect(result, expectedValue);
  });

  test('handles edge case Z', () {
    // Test empty, null, zero, max values
  });
});
```

### Naming Convention
- Test files: `{source_file}_test.dart`
- Test groups: Match class/function names
- Test names: `'does X when Y'` or `'returns X for Y input'`

### What Makes a Good Test
- **Fast:** <100ms per test
- **Isolated:** No dependency on other tests
- **Deterministic:** Same result every time
- **Clear:** Failure message explains what broke

---

## Test Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/db/database_test.dart

# Run with coverage report
flutter test --coverage

# Run tests matching pattern
flutter test --name "database"

# Verbose output
flutter test --reporter=expanded
```

---

## Verification Checklist

After completing each phase, verify:

- [ ] All new tests pass
- [ ] No existing tests broken
- [ ] Test file follows naming convention
- [ ] Edge cases covered (empty, null, boundary values)
- [ ] Error cases covered (invalid input, failures)
- [ ] Tests run in <100ms each
- [ ] No flaky tests (run 3x to verify)

---

## Progress Tracking

| Phase | Status | Tests Added | Date Completed |
|-------|--------|-------------|----------------|
| A1: DB Infrastructure | **DONE** ✅ | 12 | 2026-01-16 |
| A2: Session Operations | **DONE** ✅ | 18 | 2026-01-16 |
| A3: Arrow Operations | **DONE** ✅ | 22 | 2026-01-16 |
| A4: Equipment Operations | **DONE** ✅ | 25 | 2026-01-16 |
| A5: Data Integrity | **DONE** ✅ | 12 | 2026-01-16 |
| B1: Extract Import Logic | **DONE** ✅ | - | 2026-01-16 |
| B2: Import Test File | **DONE** ✅ | 8 | 2026-01-16 |
| B3: CSV Parsing | **DONE** ✅ | 24 | 2026-01-16 |
| B4: Volume Import | **DONE** ✅ | 18 | 2026-01-16 |
| B5: Error Handling | **DONE** ✅ | 17 | 2026-01-16 |
| C1: Breath Test File | **DONE** ✅ | 5 | 2026-01-16 |
| C2: Session Lifecycle | **DONE** ✅ | 15 | 2026-01-16 |
| C3: Breath Hold Logic | **DONE** ✅ | 12 | 2026-01-16 |
| C4: Paced Breathing | **DONE** ✅ | 13 | 2026-01-16 |
| D1: Volume Chart | **DONE** ✅ | 22 | 2026-01-16 |
| D2: Handicap Chart | **DONE** ✅ | 28 | 2026-01-16 |
| D3: Group Centre Widget | **DONE** ✅ | 28 | 2026-01-16 |
| E1: Plotting Flow | **DONE** ✅ | 45 | 2026-01-16 |
| E2: Import Flow | **DONE** ✅ | 38 | 2026-01-16 |
| E3: Bow Training Flow | **DONE** ✅ | 52 | 2026-01-16 |
| E4: Breath Training Flow | **DONE** ✅ | 41 | 2026-01-16 |
| E5: Additional Coverage | **DONE** ✅ | 199 | 2026-01-16 |

---

## PWA Testing

**See:** `docs/PWA_TESTING.md`

PWA-specific issues (iOS Safari standalone mode, service workers, offline) cannot be caught by Flutter unit tests. Manual PWA testing checklist must be run before each web release.

---

## Summary for Patrick

**Testing Status:** ✅ **COMPLETE**

**What's tested:**
- ✅ Math, scoring, coordinates, state management, auth
- ✅ Database operations (full CRUD + integrity)
- ✅ CSV imports (with proper error handling)
- ✅ Breath training service (all session states)
- ✅ Chart widgets (volume, handicap, group centre)
- ✅ Integration flows (plotting, import, training)
- ✅ PWA manual checklist (see `docs/PWA_TESTING.md`)

**Key Achievements:**
- Test count: **694 → 1,348** (+654 tests, 94% increase)
- Test lines: **~11,000 → ~25,600** (+14,600 lines)
- Test ratio: **1:4.2 → 1:2.1** (exceeds 1:3 industry standard)
- All critical gaps resolved
- All phases A1-A5, B1-B5, C1-C4, D1-D3, E1-E5 complete

**Your role:** None required. Test suite is comprehensive and all tests pass.

---

## Completion Summary

**Completion Date:** 2026-01-16
**Final Test Count:** 1,348 tests passing
**Test Files:** 36
**Test Lines:** ~25,600
**Production Lines:** ~53,400
**Test-to-Code Ratio:** 1:2.1 ✅

All testing roadmap phases have been completed successfully.

---

*Tests maintained by Claude Code. Roadmap completed 2026-01-16.*
