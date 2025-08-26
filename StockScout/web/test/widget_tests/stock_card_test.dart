import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/widgets/stock_card.dart';
import 'package:stock_research_platform/models/stock.dart';

void main() {
  group('Stock Card Widget Tests', () {
    late TopStock testStock;

    setUp(() {
      testStock = TopStock(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        exchange: 'NASDAQ',
        price: 175.50,
        marketCap: 2800000000000.0,
        score: 0.92,
        reasoning: 'Strong fundamentals and growth potential',
      );
    });

    testWidgets('Stock card displays all required information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockCard(stock: testStock),
          ),
        ),
      );

      // Verify stock symbol is displayed
      expect(find.text('AAPL'), findsOneWidget);
      
      // Verify company name is displayed
      expect(find.text('Apple Inc.'), findsOneWidget);
      
      // Verify exchange is displayed
      expect(find.text('NASDAQ'), findsOneWidget);
      
      // Verify formatted price is displayed
      expect(find.textContaining('\$175.50'), findsOneWidget);
      
      // Verify formatted score is displayed
      expect(find.textContaining('92.0%'), findsOneWidget);
    });

    testWidgets('Stock card handles null price gracefully', (WidgetTester tester) async {
      final stockWithNullPrice = TopStock(
        symbol: 'TEST',
        name: 'Test Company',
        exchange: 'NYSE',
        price: null,
        marketCap: 1000000000.0,
        score: 0.85,
        reasoning: 'Test reasoning',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockCard(stock: stockWithNullPrice),
          ),
        ),
      );

      // Should display N/A for null price
      expect(find.text('N/A'), findsWidgets);
      expect(find.text('TEST'), findsOneWidget);
    });

    testWidgets('Stock card tap interaction works', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapped = true,
              child: StockCard(stock: testStock),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StockCard));
      expect(tapped, true);
    });

    testWidgets('Stock card displays market cap formatting correctly', (WidgetTester tester) async {
      final stockWithLargeMarketCap = TopStock(
        symbol: 'MSFT',
        name: 'Microsoft Corporation',
        exchange: 'NASDAQ',
        price: 350.0,
        marketCap: 2600000000000.0, // 2.6T
        score: 0.89,
        reasoning: 'Cloud computing leader',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockCard(stock: stockWithLargeMarketCap),
          ),
        ),
      );

      // Should format large market cap as trillions
      expect(find.textContaining('2.6T'), findsOneWidget);
    });
  });
}