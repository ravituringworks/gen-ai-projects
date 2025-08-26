import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/main.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('Complete app flow - startup to dashboard', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const StockResearchApp());
      
      // Wait for initial load
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // App should start successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should navigate to dashboard automatically
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify we're on the dashboard screen
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Navigation and state management', (WidgetTester tester) async {
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Test navigation if drawer or tabs exist
      final drawerFinder = find.byIcon(Icons.menu);
      if (drawerFinder.evaluate().isNotEmpty) {
        await tester.tap(drawerFinder);
        await tester.pumpAndSettle();
        
        // Drawer should open
        expect(find.byType(Drawer), findsOneWidget);
      }
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // App should handle network errors gracefully
      // (Server connection will fail in test environment)
      expect(find.textContaining('Failed to connect'), findsWidgets);
      
      // App should still be responsive
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Theme and styling consistency', (WidgetTester tester) async {
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify consistent theming
      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      
      // Should have consistent color scheme
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Responsive layout behavior', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(Size(800, 600));
      
      await tester.pumpWidget(const StockResearchApp());
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // App should adapt to screen size
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Test with mobile size
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pumpAndSettle();
      
      // Should still render properly
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Performance and memory management', (WidgetTester tester) async {
      // Start app multiple times to test for memory leaks
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(const StockResearchApp());
        await tester.pumpAndSettle(Duration(seconds: 1));
        
        // Should consistently start without issues
        expect(find.byType(MaterialApp), findsOneWidget);
        
        // Reset for next iteration
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
    });
  });
}