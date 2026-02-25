import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SunSunGardenApp());

    // Verify that the app title is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
