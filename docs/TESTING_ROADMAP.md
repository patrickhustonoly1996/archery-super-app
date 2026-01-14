# Testing Strategy: Reliable App for Training

**For:** Patrick Huston
**Purpose:** Ensure the app works correctly every time you use it
**Last Updated:** 2026-01-14

---

## The Point

Your app handles archery data - arrow positions, scores, training logs. If the math is wrong, your analysis is wrong. If data gets corrupted, training history is lost.

**Tests verify the app does what it should.** Every time code changes, tests re-check everything still works.

Think of it like this: You wouldn't trust a sight setting without verifying it. Tests are verification for code.

---

## What's Protected by Tests

### Currently Verified

| What | Why It Matters | Status |
|------|----------------|--------|
| Arrow position math | Plotting accuracy, group analysis | Verified |
| Score calculations | Ring boundaries, X-ring detection | Verified |
| Group spread analysis | Training feedback, sight adjustments | Verified |
| Target face rendering | Arrows appear where they should | Verified |
| Coordinate conversions | Different face sizes work correctly | Verified |
| Rolling average display | Quick feedback during sessions | Verified |

### Not Yet Verified

| What | Risk Without Tests | Priority |
|------|-------------------|----------|
| Volume EMA calculations | Training load analysis could be wrong | High |
| Handicap calculations | Progress tracking could be inaccurate | High |
| Database save/load | Training logs could be lost | High |
| Session state management | Session flow could break | Medium |
| Score imports | Historical data could fail | Medium |
| Timer accuracy | Bow training timing could drift | Medium |
| Charts rendering | Visual data could display wrong | Low |

---

## How Claude Uses This

When Claude makes changes:

1. **Before changes:** Runs existing tests to confirm baseline
2. **After changes:** Runs tests again to catch any breaks
3. **New features:** Adds tests for new functionality

Claude reports: "All tests passing" or "X tests failed - here's what broke"

---

## When Tests Fail

If Claude reports test failures, it means:

- **Something broke** that was working before, OR
- **A test assumption changed** (intentional change needs test update)

Either way, don't deploy until resolved. Failed tests = potential problems for users.

---

## The Math Tests

Arrow positioning is critical. Here's what's verified:

### Coordinate System
- 40cm, 60cm, 80cm, 122cm face sizes all calculate correctly
- Millimeter positions convert to screen pixels accurately
- Legacy data (old format) still displays correctly

### Scoring
- Ring boundaries use 0.001mm tolerance (like a line-cutter decision)
- X-ring detection works at all face sizes
- Miss detection beyond face edge

### Group Analysis
- Center calculation from multiple arrows
- Mean spread and max spread
- Sight click recommendations (horizontal and vertical)
- Standard deviation for consistency tracking

---

## Quality Levels

| Level | What It Means | Current State |
|-------|---------------|---------------|
| Green | All tests pass, safe to use | Target |
| Yellow | Some tests skipped, use with caution | Acceptable short-term |
| Red | Tests failing, do not deploy | Block deployment |

---

## For Future Claude Sessions

**When adding features:**
```
Add tests that verify:
1. The feature works with typical inputs
2. Edge cases don't crash (empty, zero, maximum values)
3. The feature still works after changes elsewhere
```

**When fixing bugs:**
```
1. Write a test that reproduces the bug (should fail)
2. Fix the bug
3. Test now passes (and stays passing forever)
```

---

## Test Commands

These run automatically, but if you want to check manually:

```bash
# Run all tests (takes about 30 seconds)
flutter test

# Run just the math tests
flutter test test/models/

# See each test result
flutter test --reporter=expanded
```

---

## Complete Testing Roadmap

### Phase 1: Core Math (COMPLETE)

| Component | File | Tests | Status |
|-----------|------|-------|--------|
| Arrow coordinates | `models/arrow_coordinate.dart` | ~30 | Done |
| Group analysis | `models/group_analysis.dart` | ~20 | Done |
| Coordinate system | `utils/target_coordinate_system.dart` | ~35 | Done |
| Ring scoring | (in coordinate system) | ~15 | Done |

### Phase 2: Calculation Utilities (HIGH PRIORITY)

| Component | File | Why Critical | Status |
|-----------|------|--------------|--------|
| Volume calculator | `utils/volume_calculator.dart` | Training load EMAs (7/28/90 day) | TODO |
| Handicap calculator | `utils/handicap_calculator.dart` | Progress tracking accuracy | TODO |
| Performance profile | `utils/performance_profile.dart` | Radar chart data | TODO |
| Smart zoom | `utils/smart_zoom.dart` | Auto-zoom logic | TODO |

### Phase 3: Widget Tests (MEDIUM PRIORITY)

| Component | File | Status |
|-----------|------|--------|
| Target face | `widgets/target_face.dart` | Done |
| Rolling average | `widgets/rolling_average_widget.dart` | Done |
| Scorecard | `widgets/scorecard_widget.dart` | TODO |
| Volume chart | `widgets/volume_chart.dart` | TODO |
| Handicap chart | `widgets/handicap_chart.dart` | TODO |
| Radar chart | `widgets/radar_chart.dart` | TODO |
| Group centre | `widgets/group_centre_widget.dart` | TODO |
| Breathing visualizer | `widgets/breathing_visualizer.dart` | TODO |
| Shaft selector | `widgets/shaft_selector_bottom_sheet.dart` | TODO |

### Phase 4: Database & Services (HIGH PRIORITY)

| Component | File | Why Critical | Status |
|-----------|------|--------------|--------|
| Database operations | `db/database.dart` | Data persistence | TODO |
| Round types seed | `db/round_types_seed.dart` | Scoring rules | TODO |
| OLY training seed | `db/oly_training_seed.dart` | Training presets | TODO |
| Auth service | `services/auth_service.dart` | Login/logout | TODO |
| Firestore sync | `services/firestore_sync_service.dart` | Cloud backup | TODO |
| Breath training service | `services/breath_training_service.dart` | Session logic | TODO |
| Beep service | `services/beep_service.dart` | Audio timing | TODO |

### Phase 5: State Management (MEDIUM PRIORITY)

| Component | File | What It Manages | Status |
|-----------|------|-----------------|--------|
| Session provider | `providers/session_provider.dart` | Current session state | TODO |
| Bow training provider | `providers/bow_training_provider.dart` | Timer & preset state | TODO |
| Breath training provider | `providers/breath_training_provider.dart` | Breath session state | TODO |
| Equipment provider | `providers/equipment_provider.dart` | Bow/arrow selection | TODO |
| Active sessions provider | `providers/active_sessions_provider.dart` | Session tracking | TODO |

### Phase 6: Screen Tests (LOW PRIORITY)

| Screen | File | Status |
|--------|------|--------|
| Plotting | `screens/plotting_screen.dart` | TODO |
| Bow training home | `screens/bow_training_home_screen.dart` | TODO |
| Bow training | `screens/bow_training_screen.dart` | TODO |
| Bow training library | `screens/bow_training_library_screen.dart` | TODO |
| Breath training home | `screens/breath_training/breath_training_home_screen.dart` | TODO |
| Paced breathing | `screens/breath_training/paced_breathing_screen.dart` | TODO |
| Breath hold | `screens/breath_training/breath_hold_screen.dart` | TODO |
| Patrick breath | `screens/breath_training/patrick_breath_screen.dart` | TODO |
| History | `screens/history_screen.dart` | TODO |
| Session detail | `screens/session_detail_screen.dart` | TODO |
| Session complete | `screens/session_complete_screen.dart` | TODO |
| Session start | `screens/session_start_screen.dart` | TODO |
| Equipment | `screens/equipment_screen.dart` | TODO |
| Bow form | `screens/bow_form_screen.dart` | TODO |
| Quiver form | `screens/quiver_form_screen.dart` | TODO |
| Shaft management | `screens/shaft_management_screen.dart` | TODO |
| Import | `screens/import_screen.dart` | TODO |
| Volume import | `screens/volume_import_screen.dart` | TODO |
| Statistics | `screens/statistics_screen.dart` | TODO |
| Scores graph | `screens/scores_graph_screen.dart` | TODO |
| Performance profile | `screens/performance_profile_screen.dart` | TODO |
| Delayed camera | `screens/delayed_camera_screen.dart` | TODO |
| Login | `screens/login_screen.dart` | TODO |
| Home | `screens/home_screen.dart` | TODO |

### Phase 7: Integration Tests (FUTURE)

| Flow | What It Tests | Status |
|------|---------------|--------|
| Full plotting session | Touch → Plot → Save → Display | TODO |
| Score import | File → Parse → Validate → Store | TODO |
| Bow training cycle | Start → Timer → Complete → Log | TODO |
| Breath training cycle | Select → Run → Complete → Log | TODO |
| Session lifecycle | Start → Record → End → Review | TODO |
| Equipment setup | Add bow → Add arrows → Select | TODO |

### Phase 8: Golden Tests (FUTURE)

Visual regression tests for:
- Target face appearance at different sizes
- Chart rendering consistency
- Theme/color accuracy

---

## Priority Summary

**Test these first (calculations users rely on):**
1. Volume calculator (EMA math)
2. Handicap calculator (progress tracking)
3. Database operations (data safety)

**Test these next (core features):**
4. Session provider (session flow)
5. Bow training provider (timer accuracy)
6. Scorecard widget (score display)

**Test later (visual/UI):**
7. Charts and visualizations
8. Screen layouts
9. Golden tests

---

## Current Coverage

| Category | Total Files | Tested | Coverage |
|----------|-------------|--------|----------|
| Models | 2 | 2 | 100% |
| Utils | 7 | 1 | 14% |
| Widgets | 10 | 2 | 20% |
| Providers | 5 | 0 | 0% |
| Services | 4 | 0 | 0% |
| Database | 3 | 0 | 0% |
| Screens | 20+ | 0 | 0% |

**Overall:** Core math is solid. Calculation utilities and data layer need attention.

---

## What Good Looks Like

A healthy test suite:
- **Runs fast** (<60 seconds for full suite)
- **Catches real problems** (not just theoretical edge cases)
- **Doesn't break randomly** (stable, predictable)
- **Grows with features** (new code = new tests)

Current status: ~100 tests across 6 test files, covering core math and widgets.

---

## Summary

| Question | Answer |
|----------|--------|
| Do I need to write tests? | No - Claude handles this |
| Do I need to run tests? | No - Claude runs them automatically |
| What do I do if tests fail? | Ask Claude to investigate and fix |
| How do I know the app is reliable? | Claude reports test status after changes |
| What if I want to check myself? | Run `flutter test` in terminal |

Tests exist so you can trust the numbers in your app. The math for arrow positions, group spreads, and scores has been verified thousands of times by automated tests.

---

*Tests maintained by Claude Code. Core math verified by automated checks.*
