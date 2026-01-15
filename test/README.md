# Archery Super App - Test Suite

## Overview

This test suite provides comprehensive coverage for the Archery Super App codebase. Tests are organized by component type and follow professional testing standards.

## Test Structure

```
test/
├── README.md                  # This file
├── test_helpers.dart          # Shared test utilities and factories
├── widget_test.dart           # Basic app widget test
│
├── models/
│   ├── arrow_coordinate_test.dart    # Arrow coordinate math
│   └── group_analysis_test.dart      # Group clustering analysis
│
├── utils/
│   ├── target_coordinate_system_test.dart  # Coordinate transformations
│   ├── volume_calculator_test.dart         # EMA and volume metrics
│   ├── handicap_calculator_test.dart       # Archery GB handicap tables
│   ├── smart_zoom_test.dart                # Adaptive zoom calculations
│   └── performance_profile_test.dart       # Performance metrics
│
├── providers/
│   ├── session_provider_test.dart        # Scoring session logic
│   ├── bow_training_provider_test.dart   # Bow training timer logic
│   ├── breath_training_provider_test.dart # Breathing exercise logic
│   └── equipment_provider_test.dart      # Equipment management logic
│
└── widgets/
    ├── target_face_test.dart           # Target rendering
    └── rolling_average_widget_test.dart # EMA display widget
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/utils/handicap_calculator_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Tests in Watch Mode (for development)
```bash
flutter test --watch
```

## Test Categories

### 1. Model Tests (`test/models/`)
Tests for data models and their calculations:
- Arrow coordinate conversions (mm ↔ normalized ↔ pixels)
- Score calculations from coordinates
- Group analysis and clustering

### 2. Utility Tests (`test/utils/`)
Tests for standalone utility functions:
- **VolumeCalculator**: EMA calculations for training volume
- **HandicapCalculator**: Archery GB handicap table lookups
- **SmartZoom**: Adaptive zoom factor calculations
- **PerformanceProfile**: Accuracy, consistency, grouping metrics

### 3. Provider Tests (`test/providers/`)
Tests for state management logic:
- Session scoring calculations
- Timer phase transitions
- Equipment ID generation
- Progression algorithms

### 4. Widget Tests (`test/widgets/`)
Tests for UI component behavior:
- Target face rendering
- Arrow marker positioning
- Interactive touch handling

## Test Helpers

The `test_helpers.dart` file provides:

### Arrow Factories
```dart
// Create arrow with mm coordinates (preferred)
createFakeArrow(id: 'a1', xMm: 50, yMm: 30, score: 9)

// Create arrow with normalized coordinates (legacy)
createFakeArrowNormalized(id: 'a1', x: 0.25, y: 0.15, score: 9)

// Create arrow group for testing spread
createArrowGroup(count: 12, spreadMm: 20, baseScore: 10)
```

### Volume Data Factories
```dart
// Create realistic training volume data
createVolumeData(days: 30, baseArrows: 100)

// Create steady volume (constant arrows/day)
createSteadyVolumeData(days: 10, arrowsPerDay: 100)

// Create ramp-up pattern
createRampUpVolumeData(days: 20, startArrows: 50, endArrows: 150)
```

### Session Factories
```dart
createFakeSession(id: 's1', roundTypeId: 'wa_18m')
createFakeRoundType(id: 'wa_18m', name: 'WA 18m')
createFakeEnd(id: 'e1', sessionId: 's1', endNumber: 1)
```

## Writing New Tests

### Test Naming Convention
```dart
group('ClassName', () {
  group('methodName', () {
    test('does X when Y', () {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Required Test Categories
For each source file, include tests for:
1. **Happy Path**: Normal operation with valid inputs
2. **Edge Cases**: Boundary values, limits, empty inputs
3. **Error Handling**: Invalid inputs, null handling
4. **State Transitions**: For stateful components

### Example Test Structure
```dart
group('VolumeCalculator', () {
  group('calculateEMA', () {
    test('returns 0.0 for empty data', () {
      final result = VolumeCalculator.calculateEMA(data: [], period: 7);
      expect(result, equals(0.0));
    });

    test('uses correct multiplier for period 7', () {
      // multiplier = 2 / (7 + 1) = 0.25
      final data = [DailyVolume(date: DateTime.now(), arrowCount: 200)];
      final result = VolumeCalculator.calculateEMA(
        data: data,
        period: 7,
        previousEMA: 100.0,
      );
      expect(result, closeTo(125.0, 0.1)); // 200*0.25 + 100*0.75
    });
  });
});
```

## Critical Tests

These tests should NEVER be skipped:

1. **Arrow Coordinate Math** - Ensures plotting accuracy
2. **Score Calculations** - Ring boundary detection
3. **Group Analysis** - Spread and center calculations
4. **Coordinate Conversions** - mm ↔ pixels ↔ normalized

## Continuous Integration

Before committing:
1. Run `flutter test`
2. Ensure all tests pass
3. If adding features, add corresponding tests
4. If fixing bugs, add regression tests

## Coverage Goals

- **Models**: 90%+ coverage
- **Utils**: 90%+ coverage
- **Providers**: 80%+ coverage (logic only, mocked DB)
- **Widgets**: 70%+ coverage

## Known Limitations

- Provider tests that require database interaction need mock setup
- Some widget tests require `WidgetTester` for interactive features
- Performance tests may have timing variations on different machines
