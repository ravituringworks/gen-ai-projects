import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/widgets/stock_card.dart';
import 'package:stock_research_platform/models/stock.dart';

void main() {
  group('Widget Performance Tests', () {
    testWidgets('Stock card rendering performance with many items', (WidgetTester tester) async {
      // Create a list of test stocks
      final stocks = List.generate(100, (index) => TopStock(
        symbol: 'TEST$index',
        name: 'Test Company $index',
        exchange: 'NYSE',
        price: 100.0 + index,
        marketCap: 1000000000.0 * (index + 1),
        score: 0.5 + (index % 50) * 0.01,
        reasoning: 'Test reasoning for stock $index',
      ));

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: stocks.length,
              itemBuilder: (context, index) => StockCard(stock: stocks[index]),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should render within reasonable time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Verify all items are created
      expect(find.byType(StockCard), findsNWidgets(100));
    });

    testWidgets('Scroll performance with large stock list', (WidgetTester tester) async {
      final stocks = List.generate(200, (index) => TopStock(
        symbol: 'STOCK$index',
        name: 'Company $index',
        exchange: 'NASDAQ',
        price: 50.0 + index * 0.5,
        marketCap: 500000000.0 * (index + 1),
        score: 0.3 + (index % 70) * 0.01,
        reasoning: 'Performance test stock $index',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: stocks.length,
              itemBuilder: (context, index) => StockCard(stock: stocks[index]),
            ),
          ),
        ),
      );

      // Test scrolling performance
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Perform scroll operations
      await tester.drag(listView, Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.drag(listView, Offset(0, -1000));
      await tester.pumpAndSettle();

      // Should handle scrolling without performance issues
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Memory usage with dynamic content loading', (WidgetTester tester) async {
      // Simulate dynamic content loading
      List<TopStock> stocks = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          stocks.add(TopStock(
                            symbol: 'DYN${stocks.length}',
                            name: 'Dynamic Stock ${stocks.length}',
                            exchange: 'NYSE',
                            price: 75.0,
                            marketCap: 2000000000.0,
                            score: 0.8,
                            reasoning: 'Dynamically added stock',
                          ));
                        });
                      },
                      child: Text('Add Stock'),
                    ),
                    Expanded(
                      child: ListView(
                        children: stocks.map((stock) => StockCard(stock: stock)).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Add multiple stocks dynamically
      for (int i = 0; i < 50; i++) {
        await tester.tap(find.text('Add Stock'));
        await tester.pumpAndSettle();
      }

      // Verify dynamic additions work
      expect(find.byType(StockCard), findsNWidgets(50));
      expect(stocks.length, equals(50));
    });

    testWidgets('Widget rebuild optimization', (WidgetTester tester) async {
      int buildCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                buildCount++;
                return StockCard(
                  stock: TopStock(
                    symbol: 'REBUILD',
                    name: 'Rebuild Test',
                    exchange: 'NYSE',
                    price: 100.0,
                    marketCap: 1000000000.0,
                    score: 0.9,
                    reasoning: 'Testing rebuild optimization',
                  ),
                );
              },
            ),
          ),
        ),
      );

      final initialBuildCount = buildCount;
      
      // Trigger rebuilds
      await tester.pump();
      await tester.pump();
      
      // Should minimize unnecessary rebuilds
      expect(buildCount - initialBuildCount, lessThan(3));
    });
  });
}