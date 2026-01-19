# Archery Super App Testing Roadmap

Ship a reliable app - no data loss, no payment bugs. 560 new tests across 27 files.

## Context

- Framework: Flutter with flutter_test and mockito
- Run tests: `flutter test`
- Run single: `flutter test test/services/sync_service_test.dart`
- Generate mocks: `dart run build_runner build --delete-conflicting-outputs`
- Current tests: 1445
- Target tests: 2000
- Repo: archery_super_app_v1
- Branch: main

## Rules

1. Data tests first - any test involving save/load/sync
2. Mock external services - don't hit real Stripe/Firebase
3. Run flutter test after each file to verify
4. Update status to complete when done
5. All public methods need at least one test
6. Cover edge cases: null, empty, zero, max values

## Tasks

### Task 1.1: Sync Service Tests [critical]
Create test/services/sync_service_test.dart - THE data loss fix. Source: lib/services/sync_service.dart. Tests: syncToCloud, syncFromCloud, conflictResolution, partialSync, offlineQueue, retryLogic, dataIntegrity, deletionSync, concurrentSync, networkFailure. Estimate: 45 tests.

### Task 1.2: User Profile Provider Tests [critical]
Create test/providers/user_profile_provider_test.dart - User identity and settings. Source: lib/providers/user_profile_provider.dart. Tests: loadProfile, updateProfile, createProfile, validateProfile, profileMigration, defaultValues. Estimate: 25 tests.

### Task 1.3: Training Session Service Tests [critical]
Create test/services/training_session_service_test.dart - Training data loss prevention. Source: lib/services/training_session_service.dart. Tests: startSession, recordSet, completeSession, resumeSession, cancelSession, sessionStatistics. Estimate: 30 tests.

### Task 2.1: Stripe Service Tests [critical]
Create test/services/stripe_service_test.dart - Payment bugs = lost revenue. Source: lib/services/stripe_service.dart. Tests: createSubscription, verifySubscription, cancelSubscription, webhookHandling, gracePeriod, expirationHandling, priceIdMapping, errorRecovery. Estimate: 35 tests.

### Task 2.2: Entitlement Provider Tests [critical]
Create test/providers/entitlement_provider_test.dart - Paywall logic. Source: lib/providers/entitlement_provider.dart. Tests: checkEntitlement, baseSubscription, autoPlotSubscription, gracePeriod, readOnlyMode, featureGating, subscriptionUpgrade, subscriptionDowngrade, offlineEntitlement, entitlementRefresh. Estimate: 40 tests.

### Task 3.1: Classification Service Tests [high]
Create test/services/classification_service_test.dart - Archery classification calculations. Source: lib/services/classification_service.dart. Tests: calculateClassification, bowstyleClassification, ageGroupClassification, genderClassification, roundTypeClassification, progressTracking, historicalClassification. Estimate: 35 tests.

### Task 3.2: Classification Provider Tests [high]
Create test/providers/classification_provider_test.dart - Classification state management. Source: lib/providers/classification_provider.dart. Tests: loadClassifications, currentClassification, classificationHistory, nextClassificationTarget, classificationNotifications. Estimate: 25 tests.

### Task 3.3: Sight Marks Provider Tests [high]
Create test/providers/sight_marks_provider_test.dart - Sight mark CRUD. Source: lib/providers/sight_marks_provider.dart. Tests: addSightMark, updateSightMark, deleteSightMark, getSightMarkForDistance, interpolateSightMark, sightMarkHistory, bowSpecificMarks. Estimate: 30 tests.

### Task 3.4: Sight Mark Calculator Tests [high]
Create test/utils/sight_mark_calculator_test.dart - Sight mark math. Source: lib/utils/sight_mark_calculator.dart. Tests: calculateSightMark, interpolation, extrapolation, clickConversion, unitConversion, edgeCases. Estimate: 25 tests.

### Task 3.5: XP Calculation Service Tests [high]
Create test/services/xp_calculation_service_test.dart - Gamification XP system. Source: lib/services/xp_calculation_service.dart. Tests: calculateXP, levelCalculation, levelUpDetection, xpMultipliers, xpHistory, leaderboardXP. Estimate: 30 tests.

### Task 3.6: Round Matcher Tests [high]
Create test/utils/round_matcher_test.dart - Round type detection. Source: lib/utils/round_matcher.dart. Tests: matchRound, ambiguousRounds, partialRounds, customRounds, indoorVsOutdoor, fieldRounds. Estimate: 25 tests.

### Task 4.1: Auto-Plot Provider Tests [medium]
Create test/providers/auto_plot_provider_test.dart - Auto-plot state. Source: lib/providers/auto_plot_provider.dart. Tests: startAutoPlot, processFrame, detectArrows, confirmPlot, cancelAutoPlot, quotaTracking. Estimate: 25 tests.

### Task 4.2: Vision API Service Tests [medium]
Create test/services/vision_api_service_test.dart - Auto-plot AI. Source: lib/services/vision_api_service.dart. Tests: analyzeImage, parseResponse, errorHandling, rateLimiting, imagePreprocessing, coordinateMapping. Estimate: 30 tests.

### Task 4.3: Skills Provider Tests [medium]
Create test/providers/skills_provider_test.dart - Skills tracking. Source: lib/providers/skills_provider.dart. Tests: loadSkills, updateSkill, skillProgress, skillCategories, skillRecommendations. Estimate: 20 tests.

### Task 4.4: Shaft Analysis Tests [medium]
Create test/utils/shaft_analysis_test.dart - Shaft wear analysis. Source: lib/utils/shaft_analysis.dart. Tests: analyzeShaft, shotCount, wearIndicators, replacementSuggestion, shaftComparison. Estimate: 25 tests.

### Task 4.5: Tuning Suggestions Tests [medium]
Create test/utils/tuning_suggestions_test.dart - Tuning advice. Source: lib/utils/tuning_suggestions.dart. Tests: analyzeTuning, suggestAdjustments, prioritizeSuggestions, tuningHistory, patternRecognition. Estimate: 25 tests.

### Task 4.6: Undo Manager Tests [medium]
Create test/utils/undo_manager_test.dart - Undo/redo. Source: lib/utils/undo_manager.dart. Tests: pushAction, undo, redo, clearHistory, maxStackSize, actionTypes. Estimate: 20 tests.

### Task 4.7: Scorecard Export Service Tests [medium]
Create test/services/scorecard_export_service_test.dart - Export functionality. Source: lib/services/scorecard_export_service.dart. Tests: exportToPdf, exportToCsv, exportToImage, formatScores, includeMetadata, errorHandling. Estimate: 25 tests.

### Task 5.1: Weather Service Tests [low]
Create test/services/weather_service_test.dart - Weather API. Source: lib/services/weather_service.dart. Tests: fetchWeather, parseResponse, cacheWeather, offlineHandling. Estimate: 20 tests.

### Task 5.2: Membership Card Service Tests [low]
Create test/services/membership_card_service_test.dart - Card generation. Source: lib/services/membership_card_service.dart. Tests: generateCard, validateMembership, cardData. Estimate: 15 tests.

### Task 5.3: Signature Service Tests [low]
Create test/services/signature_service_test.dart - Signature capture. Source: lib/services/signature_service.dart. Tests: captureSignature, saveSignature, loadSignature. Estimate: 15 tests.

### Task 5.4: Connectivity Provider Tests [low]
Create test/providers/connectivity_provider_test.dart - Online/offline. Source: lib/providers/connectivity_provider.dart. Tests: checkConnectivity, onConnectivityChange, offlineMode. Estimate: 15 tests.

### Task 5.5: Spider Graph Provider Tests [low]
Create test/providers/spider_graph_provider_test.dart - Graph display. Source: lib/providers/spider_graph_provider.dart. Tests: loadGraphData, calculateAxes, normalizeData. Estimate: 15 tests.

### Task 5.6: Error Handler Tests [low]
Create test/utils/error_handler_test.dart - Error formatting. Source: lib/utils/error_handler.dart. Tests: handleError, formatMessage, logError. Estimate: 15 tests.

### Task 5.7: Chiptune Service Tests [low]
Create test/services/chiptune_service_test.dart - Audio playback. Source: lib/services/chiptune_service.dart. Tests: playSound, stopSound, volumeControl. Estimate: 15 tests.

### Task 5.8: Chiptune Generator Tests [low]
Create test/services/chiptune_generator_test.dart - Audio generation. Source: lib/services/chiptune_generator.dart. Tests: generateTone, waveformTypes, frequencyRange. Estimate: 15 tests.

### Task 5.9: Vibration Service Tests [low]
Create test/services/vibration_service_test.dart - Haptics. Source: lib/services/vibration_service.dart. Tests: vibrate, vibratePattern, checkSupport. Estimate: 10 tests.
