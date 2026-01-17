/// Integration tests for app initialization and auth-related behavior.
///
/// Tests the offline-first initialization:
/// - Database lazy initialization
/// - Provider creation without blocking
/// - Timeout handling
///
/// Note: Full auth tests require Firebase mocking which is complex.
/// These tests verify the supporting infrastructure works correctly.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/providers/session_provider.dart';
import 'package:archery_super_app/providers/equipment_provider.dart';
import 'package:archery_super_app/providers/bow_training_provider.dart';
import 'package:archery_super_app/providers/breath_training_provider.dart';
import 'package:archery_super_app/providers/active_sessions_provider.dart';
import 'package:archery_super_app/providers/spider_graph_provider.dart';

void main() {
  // Required for providers that use WidgetsBinding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization Tests', () {
    group('Database Lazy Initialization', () {
      test('database constructor does not block', () async {
        // This test verifies that creating AppDatabase is instant
        // The actual SQLite/WASM connection opens lazily on first query
        final stopwatch = Stopwatch()..start();
        final testDb = AppDatabase.withExecutor(NativeDatabase.memory());
        stopwatch.stop();

        // Database creation should be nearly instant (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        await testDb.close();
      });

      test('first query triggers initialization and seeding', () async {
        final testDb = AppDatabase.withExecutor(NativeDatabase.memory());

        // First query will initialize the database (run migrations, seed data)
        final roundTypes = await testDb.getAllRoundTypes();

        // Should have seeded round types (>50 different round types)
        expect(roundTypes.length, greaterThan(50));

        // Verify specific round types exist
        final wa18 = roundTypes.where((rt) => rt.id == 'wa_18_60').toList();
        expect(wa18, isNotEmpty);
        expect(wa18.first.maxScore, equals(600));

        await testDb.close();
      });

      test('OLY training data is seeded', () async {
        final testDb = AppDatabase.withExecutor(NativeDatabase.memory());

        final templates = await testDb.getAllOlySessionTemplates();
        final exerciseTypes = await testDb.getAllOlyExerciseTypes();

        // Should have OLY training data
        expect(templates, isNotEmpty);
        expect(exerciseTypes, isNotEmpty);

        await testDb.close();
      });
    });

    group('Provider Initialization', () {
      late AppDatabase db;

      setUp(() {
        db = AppDatabase.withExecutor(NativeDatabase.memory());
      });

      tearDown(() async {
        await db.close();
      });

      test('SessionProvider can be created without database queries', () {
        // Provider should be creatable without any async work
        final stopwatch = Stopwatch()..start();
        final provider = SessionProvider(db);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(provider, isNotNull);
      });

      test('EquipmentProvider can be created without loading data', () {
        final provider = EquipmentProvider(db);

        // Provider should be created even though equipment isn't loaded yet
        expect(provider.bows, isEmpty);
        expect(provider.quivers, isEmpty);
      });

      test('EquipmentProvider loadEquipment works async', () async {
        final provider = EquipmentProvider(db);

        await provider.loadEquipment();

        // After loading, should have empty lists (no equipment yet)
        // This verifies loadEquipment completes without error
        expect(provider.bows, isEmpty);
        expect(provider.quivers, isEmpty);
      });

      test('BowTrainingProvider created without loading templates', () {
        final provider = BowTrainingProvider(db);

        // Templates should be empty until explicitly loaded
        expect(provider.sessionTemplates, isEmpty);
        expect(provider.recentLogs, isEmpty);
      });

      test('BreathTrainingProvider created without database', () {
        // BreathTrainingProvider doesn't need the database
        final provider = BreathTrainingProvider();
        expect(provider, isNotNull);
      });

      test('ActiveSessionsProvider created without SharedPreferences', () {
        final provider = ActiveSessionsProvider();
        expect(provider, isNotNull);
      });

      test('SpiderGraphProvider created without loading data', () {
        final provider = SpiderGraphProvider(db);
        expect(provider, isNotNull);
      });
    });

    group('Timeout Behavior', () {
      test('Future.timeout throws TimeoutException', () async {
        // Verify timeout works as expected for our auth flow
        final slowFuture = Future.delayed(
          const Duration(seconds: 5),
          () => 'result',
        );

        expect(
          () async => await slowFuture.timeout(
            const Duration(milliseconds: 100),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('completed Future does not timeout', () async {
        final fastFuture = Future.value('immediate');

        final result = await fastFuture.timeout(
          const Duration(milliseconds: 100),
        );

        expect(result, equals('immediate'));
      });
    });
  });
}
