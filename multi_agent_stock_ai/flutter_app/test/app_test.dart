import 'package:flutter_test/flutter_test.dart';
import 'package:multi_agent_stock_ai/ui/app.dart';

void main() {
  testWidgets('App renders with tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MultiAgentStockApp());
    expect(find.text('Top 100 Stocks'), findsOneWidget);
  });
}
