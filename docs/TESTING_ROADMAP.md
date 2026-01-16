# Testing Strategy: Reliable App for Training

**For:** Patrick Huston
**Purpose:** Ensure the app works correctly every time you use it
**Last Updated:** 2026-01-16

---

## Current Status

**Test Lines:** ~11,000 | **Production Lines:** ~47,000 | **Ratio:** 1:4.2
**Target Ratio:** 1:3 (industry standard for mobile apps)
**Tests:** 694 passing | **Test Files:** 28

---

## Coverage Summary

| Category | Files | Tested | Coverage | Notes |
|----------|-------|--------|----------|-------|
| Models | 2 | 2 | **100%** | Core math verified |
| Utils | 8 | 7 | **88%** | Missing: sample_data_generator |
| Providers | 5 | 5 | **100%** | All state management covered |
| Services | 4 | 3 | **75%** | Missing: breath_training_service |
| Database | 3 | 2 | **67%** | Missing: database.dart operations |
| Widgets | 11 | 5 | **45%** | Charts and UI need work |
| Screens | 27 | 0 | **0%** | Integration tests needed |

---

## Critical Gaps (Must Fix)

### Gap 1: Database Operations - CRITICAL
**File:** `lib/db/database.dart`
**Risk:** Data loss, corruption, query failures
**Why Critical:** All user data flows through this - sessions, arrows, equipment

**Tests Needed:**
- [ ] CRUD operations for sessions
- [ ] CRUD operations for arrows
- [ ] CRUD operations for equipment (bows, quivers, shafts)
- [ ] Query methods (getSessionsByDate, getArrowsForEnd, etc.)
- [ ] Data integrity (foreign key relationships)
- [ ] Edge cases (empty results, null handling)

**Estimated Tests:** 40-50
**Estimated Lines:** ~1,500

---

### Gap 2: CSV Import Parsing - HIGH
**Files:** `lib/screens/import_screen.dart`, `lib/screens/volume_import_screen.dart`
**Risk:** Silent failures, corrupted imports (P0 issue in CODE_REVIEW)
**Why Critical:** Users trust imported historical data

**Tests Needed:**
- [ ] Valid CSV parsing (happy path)
- [ ] Malformed CSV handling (missing columns, extra columns)
- [ ] Date format variations
- [ ] Score validation (valid values only)
- [ ] Empty file handling
- [ ] Large file handling
- [ ] Duplicate detection
- [ ] Error reporting (not silent failures!)

**Estimated Tests:** 25-30
**Estimated Lines:** ~800

---

### Gap 3: Breath Training Service - MEDIUM
**File:** `lib/services/breath_training_service.dart`
**Risk:** Incorrect session logic, timing issues
**Why:** Used for breath hold and paced breathing features

**Tests Needed:**
- [ ] Session state transitions
- [ ] Timer accuracy
- [ ] Phase progression logic
- [ ] Session completion detection
- [ ] Persistence integration

**Estimated Tests:** 15-20
**Estimated Lines:** ~500

---

### Gap 4: Chart Widgets - MEDIUM
**Files:** `volume_chart.dart`, `handicap_chart.dart`, `group_centre_widget.dart`
**Risk:** Incorrect visual feedback, misleading data
**Why:** Training decisions based on chart data

**Tests Needed:**
- [ ] Data transformation logic (not rendering)
- [ ] Edge cases (empty data, single point, negative values)
- [ ] Axis scaling calculations
- [ ] Group centre position calculations
- [ ] Sight click display values

**Estimated Tests:** 20-25
**Estimated Lines:** ~600

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
| A1: DB Infrastructure | TODO | - | - |
| A2: Session Operations | TODO | - | - |
| A3: Arrow Operations | TODO | - | - |
| A4: Equipment Operations | TODO | - | - |
| A5: Data Integrity | TODO | - | - |
| B1: Extract Import Logic | TODO | - | - |
| B2-B5: Import Tests | TODO | - | - |
| C1-C4: Breath Service | TODO | - | - |
| D1-D3: Chart Widgets | TODO | - | - |
| E1-E3: Integration | TODO | - | - |

---

## Summary for Patrick

**What's well tested:** Math, scoring, coordinates, state management, auth
**What needs tests:** Database operations, CSV imports, breath training service, charts

**Next steps for Claude:**
1. Start with Phase A (database tests) - highest risk area
2. Extract import logic and add tests (fixes silent failure bug)
3. Add breath training service tests
4. Add chart calculation tests

**Your role:** None required. Claude handles test writing. You'll see "X tests passing" in session summaries.

---

*Tests maintained by Claude Code. Updated 2026-01-16.*
