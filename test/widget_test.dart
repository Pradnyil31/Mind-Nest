// This is a basic test file.
// Add widget tests for your screens here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mindnest/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Build our app with ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MindNestApp()));

    // Verify the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  // Add more widget tests here as you develop features
  // Example:
  // testWidgets('Welcome screen shows app name', (WidgetTester tester) async {
  //   await tester.pumpWidget(ProviderScope(child: MaterialApp(home: WelcomeScreen())));
  //   expect(find.text('MindNest'), findsOneWidget);
  // });
}
