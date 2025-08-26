import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/screens/dashboard_screen.dart';
import 'package:stock_research_platform/models/stock.dart';


void main() {
  group('Dashboard Widget Tests', () {
    testWidgets('Dashboard screen loads with proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );
      
      // Wait for any async operations to complete
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify basic UI elements are present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should find connection status indicator
      expect(find.textContaining('Connection'), findsWidgets);
    });

    testWidgets('Connection alert displays when server is down', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // Should show connection error since no actual server in test
      expect(find.textContaining('Failed to connect'), findsWidgets);
    });

    testWidgets('Top stocks section renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Should find top stocks related UI elements
      expect(find.textContaining('Top'), findsWidgets);
    });

    testWidgets('Agent status section is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Should find agent status related UI
      expect(find.textContaining('Agent'), findsWidgets);
    });

    testWidgets('Refresh functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Look for refresh button and tap it
      final refreshFinder = find.byIcon(Icons.refresh);
      if (refreshFinder.evaluate().isNotEmpty) {
        await tester.tap(refreshFinder);
        await tester.pumpAndSettle();
      }
      
      // App should still be functional after refresh attempt
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}