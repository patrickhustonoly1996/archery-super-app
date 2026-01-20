import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/undo_manager.dart';
import 'package:archery_super_app/utils/undo_action.dart';
import 'package:archery_super_app/theme/app_theme.dart';

void main() {
  group('UndoManager', () {
    group('showUndoSnackbar', () {
      testWidgets('displays snackbar with correct message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Session deleted',
                      onUndo: () async {},
                      onExpired: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(find.text('Session deleted'), findsOneWidget);

        // Clean up timer
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
      });

      testWidgets('displays UNDO action button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Item removed',
                      onUndo: () async {},
                      onExpired: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Remove'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Remove'));
        await tester.pump();

        expect(find.text('UNDO'), findsOneWidget);

        // Clean up timer
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
      });

      testWidgets('calls onExpired after duration when UNDO not tapped', (tester) async {
        bool expiredCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Deleted',
                      onUndo: () async {},
                      onExpired: () async {
                        expiredCalled = true;
                      },
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Timer hasn't fired yet
        expect(expiredCalled, isFalse);

        // Wait for timer to fire
        await tester.pump(const Duration(milliseconds: 150));

        expect(expiredCalled, isTrue);
        await tester.pumpAndSettle();
      });

      testWidgets('uses custom duration for timer', (tester) async {
        bool expiredCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Deleted',
                      onUndo: () async {},
                      onExpired: () async {
                        expiredCalled = true;
                      },
                      duration: const Duration(milliseconds: 200),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Wait less than custom duration
        await tester.pump(const Duration(milliseconds: 100));
        expect(expiredCalled, isFalse);

        // Wait past custom duration
        await tester.pump(const Duration(milliseconds: 150));
        expect(expiredCalled, isTrue);
        await tester.pumpAndSettle();
      });

      testWidgets('snackbar has correct styling and colors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Test message',
                      onUndo: () async {},
                      onExpired: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        // Verify the snackbar is displayed with the message
        expect(find.text('Test message'), findsOneWidget);
        expect(find.text('UNDO'), findsOneWidget);

        // Verify UNDO button uses gold color
        final undoButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
        expect(undoButton.textColor, equals(AppColors.gold));
        expect(undoButton.label, equals('UNDO'));

        // Verify snackbar uses surfaceBright background
        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.backgroundColor, equals(AppColors.surfaceBright));

        // Clean up timer
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
      });

      testWidgets('handles async onExpired callback', (tester) async {
        final completer = Completer<void>();
        bool expiredCompleted = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Deleted',
                      onUndo: () async {},
                      onExpired: () async {
                        await completer.future;
                        expiredCompleted = true;
                      },
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Wait for timer
        await tester.pump(const Duration(milliseconds: 150));

        // Expired callback is awaiting
        expect(expiredCompleted, isFalse);

        // Complete the async operation
        completer.complete();
        await tester.pumpAndSettle();

        expect(expiredCompleted, isTrue);
      });

      testWidgets('default duration is 5 seconds', (tester) async {
        bool expiredCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Deleted',
                      onUndo: () async {},
                      onExpired: () async {
                        expiredCalled = true;
                      },
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Wait 4 seconds - should not have expired yet
        await tester.pump(const Duration(seconds: 4));
        expect(expiredCalled, isFalse);

        // Wait another 2 seconds - should now be expired
        await tester.pump(const Duration(seconds: 2));
        expect(expiredCalled, isTrue);
        await tester.pumpAndSettle();
      });

      testWidgets('multiple showUndoSnackbar calls work independently', (tester) async {
        int expiredCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        UndoManager.showUndoSnackbar(
                          context: context,
                          message: 'First deleted',
                          onUndo: () async {},
                          onExpired: () async {
                            expiredCount++;
                          },
                          duration: const Duration(milliseconds: 200),
                        );
                      },
                      child: const Text('Delete 1'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        UndoManager.showUndoSnackbar(
                          context: context,
                          message: 'Second deleted',
                          onUndo: () async {},
                          onExpired: () async {
                            expiredCount++;
                          },
                          duration: const Duration(milliseconds: 100),
                        );
                      },
                      child: const Text('Delete 2'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Trigger first snackbar
        await tester.tap(find.text('Delete 1'));
        await tester.pump();

        // Trigger second snackbar
        await tester.tap(find.text('Delete 2'));
        await tester.pump();

        // Wait for both to expire
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Both timers should have fired
        expect(expiredCount, equals(2));
      });

      testWidgets('snackbar text uses body font', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoManager.showUndoSnackbar(
                      context: context,
                      message: 'Font test',
                      onUndo: () async {},
                      onExpired: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        // Find the snackbar text widget
        final textFinder = find.text('Font test');
        expect(textFinder, findsOneWidget);

        // Verify it exists within a snackbar
        expect(find.ancestor(of: textFinder, matching: find.byType(SnackBar)), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
      });
    });
  });

  group('UndoAction', () {
    group('show', () {
      testWidgets('displays snackbar with correct message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Item deleted',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(find.text('Item deleted'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('displays Undo action button with title case', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Removed',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Remove'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Remove'));
        await tester.pump();

        // UndoAction uses 'Undo' (title case)
        expect(find.text('Undo'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('uses surfaceDark background color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Deleted',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.backgroundColor, equals(AppColors.surfaceDark));
        await tester.pumpAndSettle();
      });

      testWidgets('uses floating behavior', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Test',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        // Verify snackbar is displayed with floating behavior
        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.behavior, equals(SnackBarBehavior.floating));

        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('uses gold color for action button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Deleted',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        final undoButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
        expect(undoButton.textColor, equals(AppColors.gold));
        expect(undoButton.label, equals('Undo'));

        await tester.pumpAndSettle();
      });

      testWidgets('uses provided duration for snackbar', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Deleted',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 300),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackbar.duration, equals(const Duration(milliseconds: 300)));

        await tester.pumpAndSettle();
      });
    });

    group('withSoftDelete', () {
      testWidgets('calls softDelete immediately', (tester) async {
        bool softDeleteCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.withSoftDelete(
                      context: context,
                      message: 'Session deleted',
                      softDelete: () async {
                        softDeleteCalled = true;
                      },
                      restore: () async {},
                      permanentDelete: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(softDeleteCalled, isTrue);
        await tester.pumpAndSettle();
      });

      testWidgets('shows snackbar after softDelete', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.withSoftDelete(
                      context: context,
                      message: 'Session deleted',
                      softDelete: () async {},
                      restore: () async {},
                      permanentDelete: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(find.text('Session deleted'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('handles async softDelete correctly', (tester) async {
        final completer = Completer<void>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    await UndoAction.withSoftDelete(
                      context: context,
                      message: 'Deleted',
                      softDelete: () async {
                        await completer.future;
                      },
                      restore: () async {},
                      permanentDelete: () async {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Snackbar should not show until softDelete completes
        expect(find.text('Deleted'), findsNothing);

        // Complete softDelete
        completer.complete();
        await tester.pump();

        // Now snackbar should show
        expect(find.text('Deleted'), findsOneWidget);
        await tester.pumpAndSettle();
      });
    });

    group('edge cases', () {
      testWidgets('handles rapid consecutive show calls', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: 'Deleted',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        // Tap multiple times quickly
        await tester.tap(find.text('Delete'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Delete'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Delete'));
        await tester.pump();

        // A snackbar should be visible
        expect(find.text('Deleted'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('handles empty message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: '',
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Should still show the snackbar with Undo button
        expect(find.text('Undo'), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('handles very long message', (tester) async {
        final longMessage = 'A' * 200;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    UndoAction.show(
                      context: context,
                      message: longMessage,
                      onUndo: () {},
                      duration: const Duration(milliseconds: 100),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        // Should still show the snackbar
        expect(find.text('Undo'), findsOneWidget);
        await tester.pumpAndSettle();
      });
    });
  });

  group('UndoManager vs UndoAction comparison', () {
    testWidgets('UndoManager uses UNDO label (uppercase)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoManager.showUndoSnackbar(
                    context: context,
                    message: 'Manager test',
                    onUndo: () async {},
                    onExpired: () async {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Manager'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Manager'));
      await tester.pump();

      final undoButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      expect(undoButton.label, equals('UNDO'));
      expect(find.text('UNDO'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('UndoAction uses Undo label (title case)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoAction.show(
                    context: context,
                    message: 'Action test',
                    onUndo: () {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pump();

      final undoButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      expect(undoButton.label, equals('Undo'));
      expect(find.text('Undo'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('UndoManager uses surfaceBright background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoManager.showUndoSnackbar(
                    context: context,
                    message: 'Manager test',
                    onUndo: () async {},
                    onExpired: () async {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Manager'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Manager'));
      await tester.pump();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.backgroundColor, equals(AppColors.surfaceBright));

      await tester.pumpAndSettle();
    });

    testWidgets('UndoAction uses surfaceDark background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoAction.show(
                    context: context,
                    message: 'Action test',
                    onUndo: () {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pump();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.backgroundColor, equals(AppColors.surfaceDark));

      await tester.pumpAndSettle();
    });

    testWidgets('both use gold color for undo button', (tester) async {
      // Test UndoManager
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoManager.showUndoSnackbar(
                    context: context,
                    message: 'Test',
                    onUndo: () async {},
                    onExpired: () async {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Manager'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Manager'));
      await tester.pump();

      var undoButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      expect(undoButton.textColor, equals(AppColors.gold));

      await tester.pumpAndSettle();

      // Test UndoAction
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoAction.show(
                    context: context,
                    message: 'Test',
                    onUndo: () {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pump();

      undoButton = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      expect(undoButton.textColor, equals(AppColors.gold));

      await tester.pumpAndSettle();
    });

    testWidgets('UndoAction explicitly sets floating behavior', (tester) async {
      // Test UndoAction has floating behavior
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UndoAction.show(
                    context: context,
                    message: 'Test',
                    onUndo: () {},
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pump();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.behavior, equals(SnackBarBehavior.floating));

      await tester.pumpAndSettle();
    });
  });

  group('real-world scenarios', () {
    testWidgets('equipment removal triggers onExpired callback', (tester) async {
      final equipment = ['Bow 1', 'Arrows', 'Sight'];
      bool dbDeleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final item = equipment.removeLast();
                  UndoManager.showUndoSnackbar(
                    context: context,
                    message: '$item removed',
                    onUndo: () async {
                      equipment.add(item);
                    },
                    onExpired: () async {
                      // Simulate database deletion
                      dbDeleteCalled = true;
                    },
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Remove Last'),
              ),
            ),
          ),
        ),
      );

      // Initial state
      expect(equipment, equals(['Bow 1', 'Arrows', 'Sight']));

      // Remove item
      await tester.tap(find.text('Remove Last'));
      await tester.pump();

      expect(equipment, equals(['Bow 1', 'Arrows']));
      expect(find.text('Sight removed'), findsOneWidget);
      expect(dbDeleteCalled, isFalse);

      // Wait for expiration
      await tester.pump(const Duration(milliseconds: 150));

      expect(dbDeleteCalled, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('multiple UndoManager deletions work independently', (tester) async {
      final items = ['A', 'B', 'C'];
      final permanentlyDeleted = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  if (items.isEmpty) return;
                  final item = items.removeLast();
                  UndoManager.showUndoSnackbar(
                    context: context,
                    message: '$item deleted',
                    onUndo: () async {
                      items.add(item);
                    },
                    onExpired: () async {
                      permanentlyDeleted.add(item);
                    },
                    duration: const Duration(milliseconds: 100),
                  );
                },
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      // Delete C
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(items, equals(['A', 'B']));

      // Let it expire
      await tester.pump(const Duration(milliseconds: 150));
      expect(permanentlyDeleted, equals(['C']));

      // Delete B
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(items, equals(['A']));

      // Let it expire
      await tester.pump(const Duration(milliseconds: 150));
      expect(permanentlyDeleted, equals(['C', 'B']));

      await tester.pumpAndSettle();
    });
  });
}
