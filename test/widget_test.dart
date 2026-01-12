import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/main.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ArcherySuperApp());
    await tester.pumpAndSettle();
    // Just verify the app builds without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
