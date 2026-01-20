# Testing Roadmap: Ship a Reliable App

**For:** Patrick Huston
**Goal:** No more data vanishing. No more lottery bugs.
**Created:** 2026-01-19

---

## The Honest Assessment

The codebase **doubled** since the last roadmap was written. Tests didn't keep up.

| Metric | When Last Roadmap Written | Now | Gap |
|--------|---------------------------|-----|-----|
| Code lines | ~53,400 | ~116,500 | +118% |
| Services | 5 | 20 | +15 untested |
| Providers | 5 | 13 | +8 untested |
| Utils | 8 | 18 | +10 untested |
| Tests | ~1,350 | 2,269 | +68% (should be +118%) |

**Result:** Core foundation is solid, but the new features ship bugs.

---

## Current Coverage (Honest)

### Services: 11/20 tested (55%)

| Status | Service | Risk Level | Notes |
|--------|---------|------------|-------|
| ✅ | auth_service | - | Tested |
| ✅ | beep_service | - | Tested |
| ✅ | breath_training_service | - | Tested |
| ✅ | import_service | - | Tested |
| ✅ | scan_frame_service | - | Tested |
| ✅ | scan_motion_service | - | Tested |
| ✅ | sync_service | - | Tested |
| ✅ | stripe_service | - | Tested |
| ✅ | classification_service | - | Tested |
| ❌ | **xp_calculation_service** | HIGH | XP/levels could break |
| ✅ | training_session_service | - | Tested |
| ❌ | **vision_api_service** | MEDIUM | Auto-plot failures |
| ❌ | **scorecard_export_service** | MEDIUM | Export bugs |
| ✅ | weather_service | - | Tested |
| ❌ | membership_card_service | LOW | Card generation |
| ❌ | signature_service | LOW | Signature capture |
| ❌ | chiptune_generator | LOW | Audio fun feature |
| ❌ | chiptune_service | LOW | Audio fun feature |
| ❌ | vibration_service | LOW | Haptics |
| ❌ | sample_data_seeder | LOW | Dev-only |

### Providers: 8/13 tested (62%)

| Status | Provider | Risk Level | Notes |
|--------|----------|------------|-------|
| ✅ | active_sessions_provider | - | Tested |
| ✅ | bow_training_provider | - | Tested |
| ✅ | breath_training_provider | - | Tested |
| ✅ | entitlement_provider | - | Tested |
| ✅ | equipment_provider | - | Tested |
| ✅ | session_provider | - | Tested |
| ✅ | user_profile_provider | - | Tested |
| ✅ | classification_provider | - | Tested |
| ❌ | **sight_marks_provider** | HIGH | Sight mark CRUD |
| ❌ | **auto_plot_provider** | MEDIUM | Auto-plot state |
| ❌ | **skills_provider** | MEDIUM | Skills tracking |
| ❌ | connectivity_provider | LOW | Online/offline display |
| ❌ | spider_graph_provider | LOW | Graph display |

### Utils: 10/18 tested (56%)

| Status | Util | Risk Level | Notes |
|--------|------|------------|-------|
| ✅ | handicap_calculator | - | Tested |
| ✅ | performance_profile | - | Tested |
| ✅ | smart_zoom | - | Tested |
| ✅ | statistics | - | Tested |
| ✅ | target_coordinate_system | - | Tested |
| ✅ | unique_id | - | Tested |
| ✅ | volume_calculator | - | Tested |
| ❌ | **sight_mark_calculator** | HIGH | Sight mark math |
| ❌ | **round_matcher** | HIGH | Round type detection |
| ❌ | **shaft_analysis** | MEDIUM | Shaft wear analysis |
| ✅ | tuning_suggestions | - | Tested |
| ✅ | undo_manager | - | Tested |
| ✅ | undo_action | - | Tested |
| ❌ | error_handler | LOW | Error formatting |
| ❌ | measurement_guides | LOW | UI guides |
| ❌ | sample_data_generator | LOW | Dev-only |
| ❌ | web_url_helper | LOW | Web URL handling |
| ❌ | web_url_helper_stub | LOW | Stub for non-web |

---

## Phase 1: Data Integrity (CRITICAL)

**Goal:** Data never vanishes. What you enter stays entered.

### 1.1 Sync Service Tests
**File:** `lib/services/sync_service.dart`
**Test file:** `test/services/sync_service_test.dart`
**Why:** This is THE bug factory. Data syncs wrong = data lost.

```
Tests to write:
1. syncToCloud() - uploads local changes correctly
2. syncFromCloud() - downloads remote changes correctly
3. conflictResolution() - local wins when offline edits conflict
4. partialSync() - handles interrupted sync gracefully
5. offlineQueue() - queues changes when offline
6. retryLogic() - retries failed syncs
7. dataIntegrity() - synced data matches original exactly
8. deletionSync() - deletes propagate correctly
9. concurrentSync() - multiple devices don't corrupt
10. networkFailure() - graceful degradation on network loss
```

**Estimated tests:** 40-50

### 1.2 User Profile Provider Tests
**File:** `lib/providers/user_profile_provider.dart`
**Test file:** `test/providers/user_profile_provider_test.dart`
**Why:** User's identity and settings. Corruption = bad experience.

```
Tests to write:
1. loadProfile() - loads from database correctly
2. updateProfile() - persists changes
3. createProfile() - new user flow works
4. validateProfile() - rejects invalid data
5. profileMigration() - handles schema changes
6. defaultValues() - sensible defaults for missing fields
```

**Estimated tests:** 20-25

### 1.3 Training Session Service Tests
**File:** `lib/services/training_session_service.dart`
**Test file:** `test/services/training_session_service_test.dart`
**Why:** Training data is valuable. Loss = frustrated user.

```
Tests to write:
1. startSession() - creates session correctly
2. recordSet() - records training sets
3. completeSession() - finalizes and persists
4. resumeSession() - resumes incomplete sessions
5. cancelSession() - cleanup without corruption
6. sessionStatistics() - calculates correctly
```

**Estimated tests:** 25-30

---

## Phase 2: Money & Access (CRITICAL)

**Goal:** Paying users get access. Non-paying users hit paywall. No exceptions.

### 2.1 Stripe Service Tests
**File:** `lib/services/stripe_service.dart`
**Test file:** `test/services/stripe_service_test.dart`
**Why:** Payment bugs = lost revenue or angry customers.

```
Tests to write:
1. createSubscription() - initiates payment flow
2. verifySubscription() - checks subscription status correctly
3. cancelSubscription() - cancellation flow works
4. webhookHandling() - processes Stripe webhooks
5. graceperiod() - 72hr grace period works
6. expirationHandling() - expired subs lock correctly
7. priceIdMapping() - correct prices for tiers
8. errorRecovery() - handles Stripe API failures
```

**Estimated tests:** 30-35

### 2.2 Entitlement Provider Tests
**File:** `lib/providers/entitlement_provider.dart`
**Test file:** `test/providers/entitlement_provider_test.dart`
**Why:** This gates features. Wrong = free access or locked out paying users.

```
Tests to write:
1. checkEntitlement() - returns correct access level
2. baseSubscription() - base features unlock at £2/month
3. autoPlotSubscription() - auto-plot unlocks at £7.20/month
4. gracePeriod() - 72hr grace after expiry
5. readOnlyMode() - correct behavior after grace
6. featureGating() - each feature checks correctly
7. subscriptionUpgrade() - upgrade path works
8. subscriptionDowngrade() - downgrade path works
9. offlineEntitlement() - works without network
10. entitlementRefresh() - refreshes on app open
```

**Estimated tests:** 35-40

---

## Phase 3: Core Features (HIGH)

**Goal:** Main features work correctly every time.

### 3.1 Classification Service Tests
**File:** `lib/services/classification_service.dart`
**Test file:** `test/services/classification_service_test.dart`

```
Tests to write:
1. calculateClassification() - correct classification for scores
2. bowstyleClassification() - different bow types handled
3. ageGroupClassification() - age groups applied correctly
4. genderClassification() - gender categories correct
5. roundTypeClassification() - indoor/outdoor/field
6. progressTracking() - tracks toward next classification
7. historicalClassification() - past classifications preserved
```

**Estimated tests:** 30-35

### 3.2 Classification Provider Tests
**File:** `lib/providers/classification_provider.dart`
**Test file:** `test/providers/classification_provider_test.dart`

```
Tests to write:
1. loadClassifications() - loads from database
2. currentClassification() - returns current correctly
3. classificationHistory() - returns history
4. nextClassificationTarget() - calculates next goal
5. classificationNotifications() - notifies on achievement
```

**Estimated tests:** 20-25

### 3.3 Sight Marks Provider Tests
**File:** `lib/providers/sight_marks_provider.dart`
**Test file:** `test/providers/sight_marks_provider_test.dart`

```
Tests to write:
1. addSightMark() - creates new sight mark
2. updateSightMark() - updates existing
3. deleteSightMark() - removes correctly
4. getSightMarkForDistance() - returns correct mark
5. interpolateSightMark() - calculates between known marks
6. sightMarkHistory() - tracks changes over time
7. bowSpecificMarks() - different marks per bow
```

**Estimated tests:** 25-30

### 3.4 Sight Mark Calculator Tests
**File:** `lib/utils/sight_mark_calculator.dart`
**Test file:** `test/utils/sight_mark_calculator_test.dart`

```
Tests to write:
1. calculateSightMark() - basic calculation correct
2. interpolation() - between known distances
3. extrapolation() - beyond known distances
4. clickConversion() - sight clicks to distance
5. unitConversion() - metric/imperial handling
6. edgeCases() - zero, negative, extreme values
```

**Estimated tests:** 20-25

### 3.5 XP Calculation Service Tests
**File:** `lib/services/xp_calculation_service.dart`
**Test file:** `test/services/xp_calculation_service_test.dart`

```
Tests to write:
1. calculateXP() - correct XP for actions
2. levelCalculation() - XP to level conversion
3. levelUpDetection() - detects level boundaries
4. xpMultipliers() - streak/bonus multipliers work
5. xpHistory() - tracks XP gains
6. leaderboardXP() - XP for leaderboard purposes
```

**Estimated tests:** 25-30

### 3.6 Round Matcher Tests
**File:** `lib/utils/round_matcher.dart`
**Test file:** `test/utils/round_matcher_test.dart`

```
Tests to write:
1. matchRound() - identifies round from arrow count/scores
2. ambiguousRounds() - handles similar rounds
3. partialRounds() - incomplete round detection
4. customRounds() - user-defined rounds
5. indoorVsOutdoor() - distinguishes correctly
6. fieldRounds() - field archery rounds
```

**Estimated tests:** 20-25

---

## Phase 4: Secondary Features (MEDIUM)

### 4.1 Auto-Plot Provider Tests
**File:** `lib/providers/auto_plot_provider.dart`
**Test file:** `test/providers/auto_plot_provider_test.dart`
**Estimated tests:** 20-25

### 4.2 Vision API Service Tests
**File:** `lib/services/vision_api_service.dart`
**Test file:** `test/services/vision_api_service_test.dart`
**Estimated tests:** 25-30

### 4.3 Skills Provider Tests
**File:** `lib/providers/skills_provider.dart`
**Test file:** `test/providers/skills_provider_test.dart`
**Estimated tests:** 15-20

### 4.4 Shaft Analysis Tests
**File:** `lib/utils/shaft_analysis.dart`
**Test file:** `test/utils/shaft_analysis_test.dart`
**Estimated tests:** 20-25

### 4.5 Tuning Suggestions Tests
**File:** `lib/utils/tuning_suggestions.dart`
**Test file:** `test/utils/tuning_suggestions_test.dart`
**Estimated tests:** 20-25

### 4.6 Undo Manager Tests
**File:** `lib/utils/undo_manager.dart` + `undo_action.dart`
**Test file:** `test/utils/undo_manager_test.dart`
**Estimated tests:** 15-20

### 4.7 Scorecard Export Service Tests
**File:** `lib/services/scorecard_export_service.dart`
**Test file:** `test/services/scorecard_export_service_test.dart`
**Estimated tests:** 20-25

---

## Phase 5: Polish (LOW)

These are lower risk - bugs here are annoying but not data-destroying.

| File | Test File | Est. Tests |
|------|-----------|------------|
| weather_service | weather_service_test | 15-20 |
| membership_card_service | membership_card_service_test | 10-15 |
| signature_service | signature_service_test | 10-15 |
| connectivity_provider | connectivity_provider_test | 10-15 |
| spider_graph_provider | spider_graph_provider_test | 10-15 |
| error_handler | error_handler_test | 10-15 |
| chiptune_service | chiptune_service_test | 10-15 |
| chiptune_generator | chiptune_generator_test | 10-15 |
| vibration_service | vibration_service_test | 5-10 |

---

## Summary: Tests Needed

| Phase | Priority | Files | Est. Tests |
|-------|----------|-------|------------|
| **Phase 1** | CRITICAL | 3 | ~100 |
| **Phase 2** | CRITICAL | 2 | ~70 |
| **Phase 3** | HIGH | 6 | ~150 |
| **Phase 4** | MEDIUM | 7 | ~140 |
| **Phase 5** | LOW | 9 | ~100 |
| **TOTAL** | - | 27 | **~560 new tests** |

**Current:** 1,445 tests
**Target:** ~2,000 tests
**New test-to-code ratio:** Will bring us to industry standard

---

## Implementation Order

### Week 1-2: Stop the Bleeding
1. `sync_service_test.dart` - THE priority
2. `entitlement_provider_test.dart` - Payment access
3. `stripe_service_test.dart` - Payment processing

### Week 3-4: Core Reliability
4. `user_profile_provider_test.dart`
5. `training_session_service_test.dart`
6. `classification_service_test.dart`

### Week 5-6: Feature Confidence
7. `classification_provider_test.dart`
8. `sight_marks_provider_test.dart`
9. `sight_mark_calculator_test.dart`
10. `xp_calculation_service_test.dart`
11. `round_matcher_test.dart`

### Week 7-8: Complete Coverage
12. All Phase 4 tests
13. All Phase 5 tests

---

## For Developers Helping Out

Each test file follows this structure:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:archery_super_app/path/to/file.dart';

// Generate mocks for dependencies
@GenerateMocks([Database, AuthService, etc])
import 'filename_test.mocks.dart';

void main() {
  group('ClassName', () {
    late ClassName sut;  // System Under Test
    late MockDependency mockDep;

    setUp(() {
      mockDep = MockDependency();
      sut = ClassName(dependency: mockDep);
    });

    group('methodName', () {
      test('does X when Y', () {
        // Arrange
        when(mockDep.something()).thenReturn(value);

        // Act
        final result = sut.methodName();

        // Assert
        expect(result, expectedValue);
        verify(mockDep.something()).called(1);
      });

      test('handles error case Z', () {
        // Test edge cases, errors, empty states
      });
    });
  });
}
```

### Priority Rules for External Developers

1. **Data tests first** - Any test involving save/load/sync
2. **Happy path, then edge cases** - Get the normal flow working
3. **Mock external services** - Don't hit real Stripe/Firebase in tests
4. **One file at a time** - Complete a test file before moving on
5. **Run full suite after each file** - Catch regressions early

### Definition of Done for Each Test File

- [ ] All public methods have at least one test
- [ ] Edge cases covered (null, empty, zero, max values)
- [ ] Error cases covered (network failure, invalid input)
- [ ] All tests pass locally
- [ ] Full `flutter test` passes
- [ ] No flaky tests (run 3x to verify)

---

## Progress Tracker

| Test File | Assigned To | Status | Tests | Date |
|-----------|-------------|--------|-------|------|
| sync_service_test | Claude | ✅ COMPLETE | 47 | 2026-01-19 |
| entitlement_provider_test | Claude | ✅ COMPLETE | 138 | 2026-01-19 |
| stripe_service_test | Claude | ✅ COMPLETE | 92 | 2026-01-19 |
| user_profile_provider_test | Claude | ✅ COMPLETE | 129 | 2026-01-19 |
| training_session_service_test | Claude | ✅ COMPLETE | 36 | 2026-01-19 |
| classification_service_test | Claude | ✅ COMPLETE | 139 | 2026-01-19 |
| classification_provider_test | Claude | ✅ COMPLETE | 242 | 2026-01-19 |
| sight_marks_provider_test | - | NOT STARTED | 0 | - |
| sight_mark_calculator_test | - | NOT STARTED | 0 | - |
| xp_calculation_service_test | - | NOT STARTED | 0 | - |
| round_matcher_test | - | NOT STARTED | 0 | - |
| auto_plot_provider_test | - | NOT STARTED | 0 | - |
| vision_api_service_test | - | NOT STARTED | 0 | - |
| skills_provider_test | - | NOT STARTED | 0 | - |
| shaft_analysis_test | - | NOT STARTED | 0 | - |
| tuning_suggestions_test | Claude | ✅ COMPLETE | 65 | 2026-01-20 |
| undo_manager_test | Claude | ✅ COMPLETE | 29 | 2026-01-20 |
| scorecard_export_service_test | - | NOT STARTED | 0 | - |
| weather_service_test | Claude | ✅ COMPLETE | 111 | 2026-01-20 |
| membership_card_service_test | - | NOT STARTED | 0 | - |
| signature_service_test | - | NOT STARTED | 0 | - |
| connectivity_provider_test | - | NOT STARTED | 0 | - |
| spider_graph_provider_test | - | NOT STARTED | 0 | - |
| error_handler_test | - | NOT STARTED | 0 | - |
| chiptune_service_test | - | NOT STARTED | 0 | - |
| chiptune_generator_test | - | NOT STARTED | 0 | - |
| vibration_service_test | - | NOT STARTED | 0 | - |

---

## The Goal

**Before:** "I hope it works"
**After:** "The tests prove it works"

When all 27 test files are complete:
- ~2,000 tests covering the full app
- Every data path tested
- Every payment path tested
- Every core feature tested
- Developers can contribute without breaking things
- Patrick can ship with confidence

---

*Roadmap created 2026-01-19. Let's make this not a lottery.*
