import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/main.dart';

void main() {
  group('Main App Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const StockResearchApp());
      
      // Wait for initial load
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // App should start successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has proper theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 1));
      
      // Verify MaterialApp configuration
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'Multi-Agent Stock Research Platform');
      expect(app.theme, isNotNull);
    });

    testWidgets('App renders scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Should have basic scaffold structure
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('App handles different screen sizes', (WidgetTester tester) async {
      // Test mobile size
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 1));
      
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Test tablet size
      await tester.binding.setSurfaceSize(Size(768, 1024));
      await tester.pumpAndSettle();
      
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Reset size
      await tester.binding.setSurfaceSize(Size(800, 600));
    });
  });
}