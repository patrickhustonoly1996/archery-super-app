# Archery Super App Testing Roadmap

## Overview

Ship a reliable app - no data loss, no payment bugs. 560 new tests across 27 files. Framework: Flutter with flutter_test and mockito.

## User Stories

### US-001: Sync Service Tests
**As a** developer
**I want** comprehensive tests for sync_service.dart
**So that** data never vanishes when syncing to cloud

#### Acceptance Criteria
- [ ] Create test/services/sync_service_test.dart
- [ ] Test syncToCloud uploads local changes correctly
- [ ] Test syncFromCloud downloads remote changes correctly
- [ ] Test conflictResolution where local wins on offline edits
- [ ] Test partialSync handles interrupted sync gracefully
- [ ] Test offlineQueue queues changes when offline
- [ ] Test retryLogic retries failed syncs
- [ ] Test dataIntegrity synced data matches original
- [ ] Test deletionSync deletes propagate correctly
- [ ] Test networkFailure graceful degradation
- [ ] Run flutter test and verify all pass

### US-002: User Profile Provider Tests
**As a** developer
**I want** comprehensive tests for user_profile_provider.dart
**So that** user identity and settings are never corrupted

#### Acceptance Criteria
- [ ] Create test/providers/user_profile_provider_test.dart
- [ ] Test loadProfile loads from database correctly
- [ ] Test updateProfile persists changes
- [ ] Test createProfile new user flow works
- [ ] Test validateProfile rejects invalid data
- [ ] Test defaultValues sensible defaults for missing fields
- [ ] Run flutter test and verify all pass

### US-003: Training Session Service Tests
**As a** developer
**I want** comprehensive tests for training_session_service.dart
**So that** training data is never lost

#### Acceptance Criteria
- [ ] Create test/services/training_session_service_test.dart
- [ ] Test startSession creates session correctly
- [ ] Test recordSet records training sets
- [ ] Test completeSession finalizes and persists
- [ ] Test resumeSession resumes incomplete sessions
- [ ] Test cancelSession cleanup without corruption
- [ ] Test sessionStatistics calculates correctly
- [ ] Run flutter test and verify all pass

### US-004: Stripe Service Tests
**As a** developer
**I want** comprehensive tests for stripe_service.dart
**So that** payment bugs do not cause lost revenue

#### Acceptance Criteria
- [ ] Create test/services/stripe_service_test.dart
- [ ] Test createSubscription initiates payment flow
- [ ] Test verifySubscription checks status correctly
- [ ] Test cancelSubscription flow works
- [ ] Test gracePeriod 72hr grace period works
- [ ] Test expirationHandling expired subs lock correctly
- [ ] Test priceIdMapping correct prices for tiers
- [ ] Test errorRecovery handles Stripe API failures
- [ ] Run flutter test and verify all pass

### US-005: Entitlement Provider Tests
**As a** developer
**I want** comprehensive tests for entitlement_provider.dart
**So that** paywall logic works correctly

#### Acceptance Criteria
- [ ] Create test/providers/entitlement_provider_test.dart
- [ ] Test checkEntitlement returns correct access level
- [ ] Test baseSubscription features unlock at £2/month
- [ ] Test autoPlotSubscription unlocks at £7.20/month
- [ ] Test gracePeriod 72hr grace after expiry
- [ ] Test readOnlyMode correct behavior after grace
- [ ] Test featureGating each feature checks correctly
- [ ] Test offlineEntitlement works without network
- [ ] Run flutter test and verify all pass

### US-006: Classification Service Tests
**As a** developer
**I want** comprehensive tests for classification_service.dart
**So that** archery classifications are calculated correctly

#### Acceptance Criteria
- [ ] Create test/services/classification_service_test.dart
- [ ] Test calculateClassification correct for scores
- [ ] Test bowstyleClassification different bow types
- [ ] Test ageGroupClassification age groups applied
- [ ] Test genderClassification gender categories
- [ ] Test roundTypeClassification indoor/outdoor/field
- [ ] Test progressTracking tracks toward next classification
- [ ] Run flutter test and verify all pass

### US-007: Classification Provider Tests
**As a** developer
**I want** comprehensive tests for classification_provider.dart
**So that** classification state is managed correctly

#### Acceptance Criteria
- [ ] Create test/providers/classification_provider_test.dart
- [ ] Test loadClassifications loads from database
- [ ] Test currentClassification returns current correctly
- [ ] Test classificationHistory returns history
- [ ] Test nextClassificationTarget calculates next goal
- [ ] Run flutter test and verify all pass

### US-008: Sight Marks Provider Tests
**As a** developer
**I want** comprehensive tests for sight_marks_provider.dart
**So that** sight mark CRUD operations work correctly

#### Acceptance Criteria
- [ ] Create test/providers/sight_marks_provider_test.dart
- [ ] Test addSightMark creates new sight mark
- [ ] Test updateSightMark updates existing
- [ ] Test deleteSightMark removes correctly
- [ ] Test getSightMarkForDistance returns correct mark
- [ ] Test interpolateSightMark calculates between marks
- [ ] Test bowSpecificMarks different marks per bow
- [ ] Run flutter test and verify all pass

### US-009: Sight Mark Calculator Tests
**As a** developer
**I want** comprehensive tests for sight_mark_calculator.dart
**So that** sight mark math is accurate

#### Acceptance Criteria
- [ ] Create test/utils/sight_mark_calculator_test.dart
- [ ] Test calculateSightMark basic calculation
- [ ] Test interpolation between known distances
- [ ] Test extrapolation beyond known distances
- [ ] Test clickConversion sight clicks to distance
- [ ] Test unitConversion metric/imperial handling
- [ ] Test edgeCases zero, negative, extreme values
- [ ] Run flutter test and verify all pass

### US-010: XP Calculation Service Tests
**As a** developer
**I want** comprehensive tests for xp_calculation_service.dart
**So that** gamification XP system works correctly

#### Acceptance Criteria
- [ ] Create test/services/xp_calculation_service_test.dart
- [ ] Test calculateXP correct XP for actions
- [ ] Test levelCalculation XP to level conversion
- [ ] Test levelUpDetection detects level boundaries
- [ ] Test xpMultipliers streak/bonus multipliers
- [ ] Test xpHistory tracks XP gains
- [ ] Run flutter test and verify all pass

### US-011: Round Matcher Tests
**As a** developer
**I want** comprehensive tests for round_matcher.dart
**So that** round type detection works correctly

#### Acceptance Criteria
- [ ] Create test/utils/round_matcher_test.dart
- [ ] Test matchRound identifies from arrow count/scores
- [ ] Test ambiguousRounds handles similar rounds
- [ ] Test partialRounds incomplete round detection
- [ ] Test indoorVsOutdoor distinguishes correctly
- [ ] Test fieldRounds field archery rounds
- [ ] Run flutter test and verify all pass

### US-012: Auto-Plot Provider Tests
**As a** developer
**I want** comprehensive tests for auto_plot_provider.dart
**So that** auto-plot state is managed correctly

#### Acceptance Criteria
- [ ] Create test/providers/auto_plot_provider_test.dart
- [ ] Test startAutoPlot initiates scanning
- [ ] Test detectArrows arrow detection state
- [ ] Test confirmPlot confirms detected positions
- [ ] Test cancelAutoPlot cleanup on cancel
- [ ] Test quotaTracking tracks monthly usage
- [ ] Run flutter test and verify all pass

### US-013: Vision API Service Tests
**As a** developer
**I want** comprehensive tests for vision_api_service.dart
**So that** auto-plot AI integration works correctly

#### Acceptance Criteria
- [ ] Create test/services/vision_api_service_test.dart
- [ ] Test analyzeImage sends image for analysis
- [ ] Test parseResponse parses API response
- [ ] Test errorHandling handles API failures
- [ ] Test coordinateMapping maps to target coords
- [ ] Run flutter test and verify all pass

### US-014: Skills Provider Tests
**As a** developer
**I want** comprehensive tests for skills_provider.dart
**So that** skills tracking works correctly

#### Acceptance Criteria
- [ ] Create test/providers/skills_provider_test.dart
- [ ] Test loadSkills loads skill data
- [ ] Test updateSkill updates skill level
- [ ] Test skillProgress calculates progress
- [ ] Run flutter test and verify all pass

### US-015: Shaft Analysis Tests
**As a** developer
**I want** comprehensive tests for shaft_analysis.dart
**So that** shaft wear analysis is accurate

#### Acceptance Criteria
- [ ] Create test/utils/shaft_analysis_test.dart
- [ ] Test analyzeShaft calculates wear metrics
- [ ] Test shotCount tracks shots per shaft
- [ ] Test wearIndicators identifies wear patterns
- [ ] Test replacementSuggestion suggests when to replace
- [ ] Run flutter test and verify all pass

### US-016: Tuning Suggestions Tests
**As a** developer
**I want** comprehensive tests for tuning_suggestions.dart
**So that** tuning advice logic is accurate

#### Acceptance Criteria
- [ ] Create test/utils/tuning_suggestions_test.dart
- [ ] Test analyzeTuning analyzes arrow patterns
- [ ] Test suggestAdjustments recommends changes
- [ ] Test prioritizeSuggestions orders by impact
- [ ] Run flutter test and verify all pass

### US-017: Undo Manager Tests
**As a** developer
**I want** comprehensive tests for undo_manager.dart
**So that** undo/redo works correctly

#### Acceptance Criteria
- [ ] Create test/utils/undo_manager_test.dart
- [ ] Test pushAction adds action to stack
- [ ] Test undo reverts last action
- [ ] Test redo reapplies undone action
- [ ] Test clearHistory clears undo stack
- [ ] Test maxStackSize respects stack limit
- [ ] Run flutter test and verify all pass

### US-018: Scorecard Export Service Tests
**As a** developer
**I want** comprehensive tests for scorecard_export_service.dart
**So that** export functionality works correctly

#### Acceptance Criteria
- [ ] Create test/services/scorecard_export_service_test.dart
- [ ] Test exportToPdf generates PDF correctly
- [ ] Test exportToCsv generates CSV correctly
- [ ] Test formatScores formats scores for export
- [ ] Test errorHandling handles export failures
- [ ] Run flutter test and verify all pass

### US-019: Weather Service Tests
**As a** developer
**I want** comprehensive tests for weather_service.dart
**So that** weather API works correctly

#### Acceptance Criteria
- [ ] Create test/services/weather_service_test.dart
- [ ] Test fetchWeather gets current weather
- [ ] Test parseResponse parses API response
- [ ] Test cacheWeather caches results
- [ ] Test offlineHandling works with cache
- [ ] Run flutter test and verify all pass

### US-020: Membership Card Service Tests
**As a** developer
**I want** comprehensive tests for membership_card_service.dart
**So that** card generation works correctly

#### Acceptance Criteria
- [ ] Create test/services/membership_card_service_test.dart
- [ ] Test generateCard creates card image
- [ ] Test validateMembership checks status
- [ ] Run flutter test and verify all pass

### US-021: Signature Service Tests
**As a** developer
**I want** comprehensive tests for signature_service.dart
**So that** signature capture works correctly

#### Acceptance Criteria
- [ ] Create test/services/signature_service_test.dart
- [ ] Test captureSignature captures data
- [ ] Test saveSignature persists signature
- [ ] Test loadSignature retrieves saved
- [ ] Run flutter test and verify all pass

### US-022: Connectivity Provider Tests
**As a** developer
**I want** comprehensive tests for connectivity_provider.dart
**So that** online/offline detection works correctly

#### Acceptance Criteria
- [ ] Create test/providers/connectivity_provider_test.dart
- [ ] Test checkConnectivity detects status
- [ ] Test onConnectivityChange notifies on change
- [ ] Run flutter test and verify all pass

### US-023: Spider Graph Provider Tests
**As a** developer
**I want** comprehensive tests for spider_graph_provider.dart
**So that** graph display works correctly

#### Acceptance Criteria
- [ ] Create test/providers/spider_graph_provider_test.dart
- [ ] Test loadGraphData loads data for graph
- [ ] Test calculateAxes calculates axis values
- [ ] Test normalizeData normalizes for display
- [ ] Run flutter test and verify all pass

### US-024: Error Handler Tests
**As a** developer
**I want** comprehensive tests for error_handler.dart
**So that** error formatting works correctly

#### Acceptance Criteria
- [ ] Create test/utils/error_handler_test.dart
- [ ] Test handleError processes errors correctly
- [ ] Test formatMessage user-friendly messages
- [ ] Run flutter test and verify all pass

### US-025: Chiptune Service Tests
**As a** developer
**I want** comprehensive tests for chiptune_service.dart
**So that** audio playback works correctly

#### Acceptance Criteria
- [ ] Create test/services/chiptune_service_test.dart
- [ ] Test playSound plays audio
- [ ] Test stopSound stops audio
- [ ] Test volumeControl adjusts volume
- [ ] Run flutter test and verify all pass

### US-026: Chiptune Generator Tests
**As a** developer
**I want** comprehensive tests for chiptune_generator.dart
**So that** audio generation works correctly

#### Acceptance Criteria
- [ ] Create test/services/chiptune_generator_test.dart
- [ ] Test generateTone creates audio tone
- [ ] Test waveformTypes different waveforms
- [ ] Run flutter test and verify all pass

### US-027: Vibration Service Tests
**As a** developer
**I want** comprehensive tests for vibration_service.dart
**So that** haptics work correctly

#### Acceptance Criteria
- [ ] Create test/services/vibration_service_test.dart
- [ ] Test vibrate triggers vibration
- [ ] Test vibratePattern vibration patterns
- [ ] Test checkSupport checks device support
- [ ] Run flutter test and verify all pass

## Quality Gates

These commands must pass for every user story:
- `flutter test` - All tests pass
- `dart run build_runner build` - Mocks generate successfully
