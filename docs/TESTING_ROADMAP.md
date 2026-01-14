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
| Data saves correctly | Training logs could be lost | High |
| Score imports work | Historical data could fail | Medium |
| Timer accuracy | Bow training timing could drift | Medium |
| Session history | Past sessions could display wrong | Medium |

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

## Priority Testing Roadmap

### Now (Protecting Core Features)
- [x] Arrow coordinate math
- [x] Group analysis calculations
- [x] Target face widget rendering
- [x] Scoring algorithm
- [x] Coordinate system conversions

### Next (Protecting Data)
- [ ] Database save/load operations
- [ ] Session creation and completion
- [ ] Score import validation
- [ ] Historical data display

### Later (Protecting User Flows)
- [ ] Full plotting session: touch to save
- [ ] Bow training: timer accuracy and preset loading
- [ ] Score history: filter and display

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
