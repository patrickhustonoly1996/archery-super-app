import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/error_handler.dart';
import 'package:archery_super_app/theme/app_theme.dart';

void main() {
  group('ErrorHandlerResult', () {
    group('success factory', () {
      test('creates result with success=true and data', () {
        final result = ErrorHandlerResult.success(42);

        expect(result.success, isTrue);
        expect(result.data, equals(42));
        expect(result.error, isNull);
      });

      test('handles null data', () {
        final result = ErrorHandlerResult<String?>.success(null);

        expect(result.success, isTrue);
        expect(result.data, isNull);
        expect(result.error, isNull);
      });

      test('handles string data', () {
        final result = ErrorHandlerResult.success('test value');

        expect(result.success, isTrue);
        expect(result.data, equals('test value'));
      });

      test('handles complex object data', () {
        final map = {'key': 'value', 'count': 5};
        final result = ErrorHandlerResult.success(map);

        expect(result.success, isTrue);
        expect(result.data, equals(map));
        expect(result.data!['key'], equals('value'));
      });

      test('handles list data', () {
        final list = [1, 2, 3, 4, 5];
        final result = ErrorHandlerResult.success(list);

        expect(result.success, isTrue);
        expect(result.data, equals(list));
        expect(result.data!.length, equals(5));
      });
    });

    group('failure factory', () {
      test('creates result with success=false and error message', () {
        final result = ErrorHandlerResult<int>.failure('Something went wrong');

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, equals('Something went wrong'));
      });

      test('handles empty error message', () {
        final result = ErrorHandlerResult<String>.failure('');

        expect(result.success, isFalse);
        expect(result.error, equals(''));
      });

      test('handles long error message', () {
        final longError = 'Error: ' + 'A' * 500;
        final result = ErrorHandlerResult<void>.failure(longError);

        expect(result.success, isFalse);
        expect(result.error, equals(longError));
      });

      test('handles error with special characters', () {
        final error = 'Error: "quotes" and \n newlines';
        final result = ErrorHandlerResult<void>.failure(error);

        expect(result.success, isFalse);
        expect(result.error, equals(error));
      });
    });

    group('type safety', () {
      test('maintains type parameter for success', () {
        final intResult = ErrorHandlerResult.success(42);
        final stringResult = ErrorHandlerResult.success('hello');

        expect(intResult.data.runtimeType, equals(int));
        expect(stringResult.data.runtimeType, equals(String));
      });

      test('failure result has null data regardless of type', () {
        final intResult = ErrorHandlerResult<int>.failure('error');
        final stringResult = ErrorHandlerResult<String>.failure('error');

        expect(intResult.data, isNull);
        expect(stringResult.data, isNull);
      });
    });
  });

  group('ErrorHandler', () {
    group('run', () {
      testWidgets('returns success result when action succeeds', (tester) async {
        late ErrorHandlerResult<int> result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await ErrorHandler.run(
                      context,
                      () async => 42,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(result.success, isTrue);
        expect(result.data, equals(42));
        expect(result.error, isNull);
      });

      testWidgets('returns failure result when action throws', (tester) async {
        late ErrorHandlerResult<int> result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await ErrorHandler.run(
                      context,
                      () async => throw Exception('Test error'),
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, contains('Test error'));
      });

      testWidgets('shows success message when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => 'done',
                      successMessage: 'Operation completed',
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        expect(find.text('Operation completed'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('shows error message with Retry button when action fails', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('Network failed'),
                      errorMessage: 'Failed to save',
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        expect(find.textContaining('Failed to save'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('error snackbar has red background', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('Error'),
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.backgroundColor, equals(Colors.red.shade900));
        await tester.pumpAndSettle();
      });

      testWidgets('error snackbar Retry button uses gold color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('Error'),
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        final retryButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
        expect(retryButton.textColor, equals(AppColors.gold));
        expect(retryButton.label, equals('Retry'));
        await tester.pumpAndSettle();
      });

      testWidgets('success snackbar uses surfaceDark background', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => 'done',
                      successMessage: 'Saved!',
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.backgroundColor, equals(AppColors.surfaceDark));
        await tester.pumpAndSettle();
      });

      testWidgets('success snackbar uses floating behavior', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => 'done',
                      successMessage: 'Success!',
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.behavior, equals(SnackBarBehavior.floating));
        await tester.pumpAndSettle();
      });

      testWidgets('shows loading dialog when showLoading is true', (tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () => completer.future,
                      showLoading: true,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        // Loading indicator should be visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the action
        completer.complete('done');
        await tester.pumpAndSettle();

        // Loading indicator should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('loading indicator uses gold color', (tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () => completer.future,
                      showLoading: true,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.color, equals(AppColors.gold));

        completer.complete('done');
        await tester.pumpAndSettle();
      });

      testWidgets('hides loading dialog when action fails', (tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () => completer.future,
                      showLoading: true,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Fail the action
        completer.completeError(Exception('Network error'));
        await tester.pumpAndSettle();

        // Loading should be hidden and error should be shown
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Network error'), findsOneWidget);
      });

      testWidgets('does not show loading when showLoading is false', (tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () => completer.future,
                      showLoading: false,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        // No loading indicator
        expect(find.byType(CircularProgressIndicator), findsNothing);

        completer.complete('done');
        await tester.pumpAndSettle();
      });

      testWidgets('does not show success message when null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => 'done',
                      successMessage: null,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        // No snackbar should be shown
        expect(find.byType(SnackBar), findsNothing);
        await tester.pumpAndSettle();
      });

      testWidgets('shows raw error when errorMessage is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('Raw error message'),
                      errorMessage: null,
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        expect(find.textContaining('Raw error message'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('error snackbar truncates long messages', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('A' * 500),
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        // Snackbar should show (message might be truncated visually)
        expect(find.byType(SnackBar), findsOneWidget);

        // Verify maxLines is set to 2
        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        final textWidget = snackbar.content as Text;
        expect(textWidget.maxLines, equals(2));
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));

        await tester.pumpAndSettle();
      });

      testWidgets('custom onRetry callback is passed to snackbar action', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('Error'),
                      onRetry: () {
                        // This callback should be assigned to the snackbar action
                      },
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        // Verify retry button exists with correct styling
        expect(find.text('Retry'), findsOneWidget);
        final snackBarAction = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
        expect(snackBarAction.label, equals('Retry'));
        // The onPressed callback is configured
        expect(snackBarAction.onPressed, isNotNull);

        await tester.pumpAndSettle();
      });

      testWidgets('handles async action correctly', (tester) async {
        late ErrorHandlerResult<String> result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await ErrorHandler.run(
                      context,
                      () async {
                        await Future.delayed(const Duration(milliseconds: 10));
                        return 'async result';
                      },
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(result.success, isTrue);
        expect(result.data, equals('async result'));
      });

      testWidgets('handles void return type', (tester) async {
        late ErrorHandlerResult<void> result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await ErrorHandler.run<void>(
                      context,
                      () async {
                        // Do something without returning a value
                      },
                      successMessage: 'Done',
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        expect(result.success, isTrue);
        expect(find.text('Done'), findsOneWidget);
        await tester.pumpAndSettle();
      });
    });

    group('runSilent', () {
      test('returns result when action succeeds', () async {
        final result = await ErrorHandler.runSilent(
          () async => 'success value',
        );

        expect(result, equals('success value'));
      });

      test('rethrows when action fails', () async {
        expect(
          () => ErrorHandler.runSilent(
            () async => throw Exception('Silent error'),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('includes custom error message in logs', () async {
        // This test verifies the method signature works with errorMessage
        // The actual logging is to debugPrint which we can't easily capture
        try {
          await ErrorHandler.runSilent(
            () async => throw Exception('DB error'),
            errorMessage: 'Database operation failed',
          );
        } catch (_) {
          // Expected to throw
        }
        // If we get here without other errors, the method signature is correct
      });

      test('handles int return type', () async {
        final result = await ErrorHandler.runSilent<int>(
          () async => 42,
        );

        expect(result, equals(42));
      });

      test('handles list return type', () async {
        final result = await ErrorHandler.runSilent<List<String>>(
          () async => ['a', 'b', 'c'],
        );

        expect(result, equals(['a', 'b', 'c']));
      });

      test('handles delayed async operation', () async {
        final result = await ErrorHandler.runSilent(
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'delayed';
          },
        );

        expect(result, equals('delayed'));
      });

      test('propagates the exact exception type', () async {
        try {
          await ErrorHandler.runSilent(
            () async => throw ArgumentError('bad arg'),
          );
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect((e as ArgumentError).message, equals('bad arg'));
        }
      });

      test('propagates custom exception types', () async {
        try {
          await ErrorHandler.runSilent(
            () async => throw FormatException('bad format'),
          );
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<FormatException>());
        }
      });
    });

    group('error message formatting', () {
      testWidgets('appends exception to custom error message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await ErrorHandler.run(
                      context,
                      () async => throw Exception('timeout'),
                      errorMessage: 'Save failed',
                    );
                  },
                  child: const Text('Run'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pump();

        // Should show "Save failed: Exception: timeout"
        expect(find.textContaining('Save failed'), findsOneWidget);
        expect(find.textContaining('timeout'), findsOneWidget);
        await tester.pumpAndSettle();
      });
    });
  });

  group('real-world scenarios', () {
    testWidgets('saving session with success message', (tester) async {
      bool sessionSaved = false;
      late ErrorHandlerResult<void> result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ErrorHandler.run<void>(
                    context,
                    () async {
                      await Future.delayed(const Duration(milliseconds: 10));
                      sessionSaved = true;
                    },
                    successMessage: 'Session saved',
                    errorMessage: 'Failed to save session',
                  );
                },
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(sessionSaved, isTrue);
      expect(result.success, isTrue);
      expect(find.text('Session saved'), findsOneWidget);
    });

    testWidgets('network operation with loading indicator', (tester) async {
      final completer = Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await ErrorHandler.run(
                    context,
                    () => completer.future,
                    showLoading: true,
                    errorMessage: 'Sync failed',
                  );
                },
                child: const Text('Sync'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sync'));
      await tester.pump();

      // Loading should be shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate network failure
      completer.completeError(Exception('No internet'));
      await tester.pumpAndSettle();

      // Error should be shown with retry
      expect(find.textContaining('Sync failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('database operation with silent error handling', (tester) async {
      // runSilent is used for background operations
      // This test verifies it works for typical DB operations

      int? userId;
      Exception? caughtError;

      try {
        userId = await ErrorHandler.runSilent<int>(
          () async => 123,
          errorMessage: 'Failed to fetch user',
        );
      } catch (e) {
        caughtError = e as Exception;
      }

      expect(userId, equals(123));
      expect(caughtError, isNull);
    });

    testWidgets('multiple sequential operations', (tester) async {
      final results = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  // First operation
                  final r1 = await ErrorHandler.run(
                    context,
                    () async => 'step1',
                  );
                  results.add(r1.success);

                  // Second operation
                  final r2 = await ErrorHandler.run(
                    context,
                    () async => 'step2',
                  );
                  results.add(r2.success);

                  // Third operation that fails
                  final r3 = await ErrorHandler.run(
                    context,
                    () async => throw Exception('step3 failed'),
                  );
                  results.add(r3.success);
                },
                child: const Text('Run All'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run All'));
      await tester.pumpAndSettle();

      expect(results, equals([true, true, false]));
    });

    testWidgets('equipment deletion shows error and retry option', (tester) async {
      int deleteAttempts = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await ErrorHandler.run<void>(
                    context,
                    () async {
                      deleteAttempts++;
                      throw Exception('Network error');
                    },
                    errorMessage: 'Delete failed',
                  );
                },
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      // First attempt fails
      await tester.tap(find.text('Delete'));
      await tester.pump();

      // Error message and retry button should be visible
      expect(find.textContaining('Delete failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(deleteAttempts, equals(1));

      // Verify snackbar action exists and has correct label
      final snackBarAction = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      expect(snackBarAction.label, equals('Retry'));
      expect(snackBarAction.textColor, equals(AppColors.gold));

      await tester.pumpAndSettle();
    });
  });

  group('edge cases', () {
    testWidgets('handles rapid consecutive calls', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  // Don't await - simulate rapid fire
                  ErrorHandler.run(
                    context,
                    () async {
                      callCount++;
                      return callCount;
                    },
                  );
                },
                child: const Text('Run'),
              ),
            ),
          ),
        ),
      );

      // Rapidly tap multiple times
      await tester.tap(find.text('Run'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.text('Run'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(callCount, equals(3));
    });

    testWidgets('handles empty success message gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await ErrorHandler.run(
                    context,
                    () async => 'done',
                    successMessage: '',
                  );
                },
                child: const Text('Run'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pump();

      // Empty message snackbar should still show
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pumpAndSettle();
    });

    test('runSilent handles synchronous exceptions', () async {
      expect(
        () => ErrorHandler.runSilent(
          () => throw StateError('sync error'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('handles null action result', (tester) async {
      late ErrorHandlerResult<String?> result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ErrorHandler.run<String?>(
                    context,
                    () async => null,
                    successMessage: 'Got null',
                  );
                },
                child: const Text('Run'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pump();

      expect(result.success, isTrue);
      expect(result.data, isNull);
      expect(find.text('Got null'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('error snackbar duration is 5 seconds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await ErrorHandler.run(
                    context,
                    () async => throw Exception('Error'),
                  );
                },
                child: const Text('Run'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pump();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.duration, equals(const Duration(seconds: 5)));
      await tester.pumpAndSettle();
    });

    testWidgets('success snackbar duration is 2 seconds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await ErrorHandler.run(
                    context,
                    () async => 'done',
                    successMessage: 'Success!',
                  );
                },
                child: const Text('Run'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pump();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.duration, equals(const Duration(seconds: 2)));
      await tester.pumpAndSettle();
    });
  });
}
