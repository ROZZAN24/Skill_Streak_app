// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this import
import 'package:skillstreakapp/main.dart';

void main() {
  group('App Initialization Tests', () {
    testWidgets('App builds without crashing', (WidgetTester tester) async {
      // Build app and ensure it doesn't throw
      await tester.pumpWidget(const TalentRecognitionApp());
      await tester.pumpAndSettle();
      
      // Basic validation
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const TalentRecognitionApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Beyond Academics');
    });

    testWidgets('App has ProviderScope for state management', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const TalentRecognitionApp());
      
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    testWidgets('Debug banner is hidden', (WidgetTester tester) async {
      await tester.pumpWidget(const TalentRecognitionApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('Theme is properly configured', (WidgetTester tester) async {
      await tester.pumpWidget(const TalentRecognitionApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });
  });
}