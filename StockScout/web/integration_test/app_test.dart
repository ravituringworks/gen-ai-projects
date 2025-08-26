import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stock_research_platform/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Stock Research Platform Integration Tests', () {
    testWidgets('complete app flow test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show either connection success or failure alert
      // Should show connection status
      final serverFinder = find.textContaining('Server');
      final connectionFinder = find.textContaining('Connection');
      expect(serverFinder.evaluate().isNotEmpty || connectionFinder.evaluate().isNotEmpty, isTrue);

      // If connection alert appears, handle it
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      } else if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      // Verify main app bar is visible
      expect(find.text('Multi-Agent Stock Research Platform'), findsOneWidget);

      // Test tab navigation
      await tester.tap(find.text('Top Stocks'));
      await tester.pumpAndSettle();

      // Should show time horizon selector
      expect(find.text('Time Horizon:'), findsOneWidget);

      // Test horizon switching
      await tester.tap(find.text('1 Week'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 Month'));
      await tester.pumpAndSettle();

      // Navigate to Agents tab
      await tester.tap(find.text('Agents'));
      await tester.pumpAndSettle();

      // Navigate to Screening tab
      await tester.tap(find.text('Screening'));
      await tester.pumpAndSettle();

      // Navigate back to Overview
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // Test refresh functionality
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('connection retry functionality', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If connection failed, test retry
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should show some response (either success or another error)
        // Should show connection status
        final serverFinder2 = find.textContaining('Server');
        final connectionFinder2 = find.textContaining('Connection');
        expect(serverFinder2.evaluate().isNotEmpty || connectionFinder2.evaluate().isNotEmpty, isTrue);
      }
    });

    testWidgets('stock data display test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization and handle alerts
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      } else if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      // Navigate to Top Stocks
      await tester.tap(find.text('Top Stocks'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // If stocks are loaded, verify they contain expected data
      final stockCards = find.byType(Card);
      if (stockCards.evaluate().isNotEmpty) {
        // Should find stock symbols in the UI
        expect(
          find.textContaining(RegExp(r'^[A-Z]{1,5}$')), // Stock symbol pattern
          findsAtLeastNWidgets(1)
        );
      }
    });

    testWidgets('agent status display test', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization and handle alerts
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      } else if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      // Navigate to Agents tab
      await tester.tap(find.text('Agents'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show agent information if available
      final agentCards = find.byType(Card);
      if (agentCards.evaluate().isNotEmpty) {
        // Should show agent information
        final agentFinder = find.textContaining('agent');
        final agentFinderCap = find.textContaining('Agent');
        expect(agentFinder.evaluate().isNotEmpty || agentFinderCap.evaluate().isNotEmpty, isTrue);
      }
    });

    testWidgets('responsive design test', (WidgetTester tester) async {
      // Test different screen sizes
      await tester.binding.setSurfaceSize(const Size(360, 640)); // Mobile
      
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Handle any alerts
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      } else if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      // Verify app works on mobile size
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpAndSettle();

      // Should still work
      expect(find.byType(AppBar), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });
}