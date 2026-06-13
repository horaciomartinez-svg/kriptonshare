import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kriptonshare/main.dart';
import 'package:kriptonshare/core/utils/constants.dart';

void main() {
  group('KRIPTONSHARE App', () {
    testWidgets('App builds without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: KriptonShareApp(),
        ),
      );
      
      // Wait for the router to initialize
      await tester.pumpAndSettle();
      
      // Verify that the app builds without throwing
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('App has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KriptonShareApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'KRIPTONSHARE');
    });
  });
  
  group('Constants', () {
    test('AppConstants has correct values', () {
      expect(AppConstants.aesKeySize, 32);
      expect(AppConstants.aesNonceSize, 12);
      expect(AppConstants.aesTagSize, 16);
      expect(AppConstants.chunkSize, 256 * 1024);
    });
  });
}