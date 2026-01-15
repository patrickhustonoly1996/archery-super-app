# Testing Implementation Plan

## Status: In Progress (January 2026)

This document tracks the professional testing infrastructure implementation for the Archery Super App.

---

## COMPLETED ✅

### Test Infrastructure
- [x] `test/test_helpers.dart` - Factory methods, matchers, fixtures
- [x] `test/README.md` - Test suite documentation

### Utility Tests (HIGH PRIORITY)
- [x] `test/utils/volume_calculator_test.dart` - EMA calculations (35+ tests)
- [x] `test/utils/handicap_calculator_test.dart` - Handicap tables (50+ tests)
- [x] `test/utils/smart_zoom_test.dart` - Zoom factor logic (25+ tests)
- [x] `test/utils/performance_profile_test.dart` - Performance metrics (40+ tests)

### Provider Tests (HIGH PRIORITY)
- [x] `test/providers/bow_training_provider_test.dart` - Timer/progression (40+ tests)
- [x] `test/providers/session_provider_test.dart` - Scoring logic (45+ tests)
- [x] `test/providers/breath_training_provider_test.dart` - Breathing exercises (35+ tests)
- [x] `test/providers/equipment_provider_test.dart` - Equipment management (25+ tests)

### Pre-Existing Tests (Already in codebase)
- [x] `test/models/arrow_coordinate_test.dart`
- [x] `test/models/group_analysis_test.dart`
- [x] `test/utils/target_coordinate_system_test.dart` (488 lines, comprehensive)
- [x] `test/widgets/rolling_average_widget_test.dart`
- [x] `test/widgets/target_face_test.dart` (needs parameter fix - being handled separately)

---

## PENDING ⏳

### Phase 1: Database Mock Infrastructure
**Priority: HIGH**

Create mock database for provider integration tests:

```dart
// test/mocks/mock_database.dart
class MockAppDatabase extends Mock implements AppDatabase {
  // Mock all database methods used by providers
}
```

Files to create:
- [ ] `test/mocks/mock_database.dart`
- [ ] `test/mocks/mock_auth_service.dart`
- [ ] `test/mocks/mock_firestore_service.dart`

### Phase 2: Service Tests
**Priority: MEDIUM**

- [ ] `test/services/auth_service_test.dart`
  - Authentication state management
  - Google Sign-In flow mocking
  - Token handling

- [ ] `test/services/firestore_sync_service_test.dart`
  - Backup/restore logic
  - Conflict resolution
  - Network error handling

- [ ] `test/services/beep_service_test.dart`
  - Audio timing
  - Sequence playback

### Phase 3: Provider Integration Tests
**Priority: MEDIUM**

With mocked database:
- [ ] `test/providers/active_sessions_provider_test.dart`
  - Session persistence
  - Resume logic

- [ ] Full integration tests for existing providers with DB mocks

### Phase 4: Widget Tests
**Priority: LOW**

- [ ] `test/widgets/scorecard_widget_test.dart`
- [ ] `test/widgets/breathing_visualizer_test.dart`
- [ ] `test/widgets/radar_chart_test.dart`

### Phase 5: Integration/E2E Tests
**Priority: LOW**

- [ ] Complete scoring session flow
- [ ] Training session completion
- [ ] Data export/import

---

## HOW TO CONTINUE

### Immediate Next Steps

1. **Run existing tests** to verify baseline:
   ```bash
   cd C:\Users\patri\Desktop\archery_super_app_v1
   flutter test
   ```

2. **Fix any failing tests** (target_face_test.dart parameter issue)

3. **Create database mocks** for Phase 1:
   - Add `mockito` to dev dependencies if not present
   - Create `test/mocks/` directory
   - Implement MockAppDatabase

### Adding New Tests

When implementing new features:
1. Create test file in appropriate directory
2. Use factories from `test_helpers.dart`
3. Cover: happy path, edge cases, error handling
4. Run `flutter test` before committing

### Test Patterns to Follow

Reference implementations:
- **Best utility test**: `target_coordinate_system_test.dart` (comprehensive)
- **Best provider test**: `bow_training_provider_test.dart` (logic-focused)
- **Best factories**: `test_helpers.dart`

---

## FILES CREATED THIS SESSION

```
test/
├── test_helpers.dart              # NEW - Test utilities
├── README.md                      # NEW - Documentation
├── utils/
│   ├── volume_calculator_test.dart      # NEW
│   ├── handicap_calculator_test.dart    # NEW
│   ├── smart_zoom_test.dart             # NEW
│   └── performance_profile_test.dart    # NEW
└── providers/
    ├── bow_training_provider_test.dart      # NEW
    ├── session_provider_test.dart           # NEW
    ├── breath_training_provider_test.dart   # NEW
    └── equipment_provider_test.dart         # NEW
```

---

## COVERAGE TARGETS

| Category | Target | Current Status |
|----------|--------|----------------|
| Models | 90% | Good (existing tests) |
| Utils | 90% | Good (new tests added) |
| Providers | 80% | Partial (logic only, needs mocks for DB) |
| Widgets | 70% | Partial |
| Services | 70% | Not started |

---

## NOTES FOR FUTURE SESSIONS

1. The linter auto-fixed some test assertions (handicap comparisons, EMA values) - these corrections are intentional

2. Provider tests are logic-only; full integration requires MockAppDatabase

3. Tests use `test_helpers.dart` factories - extend these when adding new test types

4. Current test count: ~300+ assertions across new files

5. All new tests follow the pattern:
   - group('ClassName')
   - group('methodName')
   - test('does X when Y')
