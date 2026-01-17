import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/theme/app_theme.dart';

void main() {
  testWidgets('App theme loads correctly', (WidgetTester tester) async {
    // Test the theme independently (doesn't require Firebase)
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: Text('Test'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the app builds with theme
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  // Note: Full app integration tests require Firebase mocking
  // See test/integration/ for more comprehensive integration tests
}
