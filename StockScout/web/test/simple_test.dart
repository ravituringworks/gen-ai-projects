import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/models/stock.dart';
import 'package:stock_research_platform/models/agent_result.dart';

void main() {
  group('Stock Model Tests', () {
    test('TopStock fromJson creates valid instance', () {
      final json = {
        'symbol': 'AAPL',
        'name': 'Apple Inc.',
        'exchange': 'NASDAQ',
        'price': 150.0,
        'market_cap': 3000000000000.0,
        'score': 0.95,
        'reasoning': 'Strong fundamentals and growth',
      };

      final stock = TopStock.fromJson(json);

      expect(stock.symbol, 'AAPL');
      expect(stock.name, 'Apple Inc.');
      expect(stock.exchange, 'NASDAQ');
      expect(stock.price, 150.0);
      expect(stock.marketCap, 3000000000000.0);
      expect(stock.score, 0.95);
      expect(stock.reasoning, 'Strong fundamentals and growth');
    });

    test('TopStock handles null values correctly', () {
      final json = {
        'symbol': 'TEST',
        'name': 'Test Company',
        'exchange': 'NYSE',
        'price': null,
        'market_cap': null,
        'score': 0.80,
        'reasoning': 'Test reasoning',
      };

      final stock = TopStock.fromJson(json);

      expect(stock.symbol, 'TEST');
      expect(stock.name, 'Test Company');
      expect(stock.price, null);
      expect(stock.marketCap, null);
      expect(stock.score, 0.80);
    });

    test('TopStock formatted score displays correctly', () {
      final stock = TopStock(
        symbol: 'TEST',
        name: 'Test',
        exchange: 'NYSE',
        score: 0.875,
        reasoning: 'Test',
      );

      expect(stock.formattedScore, '87.5%');
    });
  });

  group('AgentResult Model Tests', () {
    test('AgentResult fromJson creates valid instance', () {
      final json = {
        'id': 'test-id-123',
        'agent_type': 'analysis_agent_1day',
        'stock_symbol': 'NVDA',
        'horizon': '1day',
        'score': 0.92,
        'reasoning': 'Strong AI growth potential',
        'created_at': '2025-08-03T20:45:31.518443537Z',
      };

      final result = AgentResult.fromJson(json);

      expect(result.id, 'test-id-123');
      expect(result.agentType, 'analysis_agent_1day');
      expect(result.stockSymbol, 'NVDA');
      expect(result.horizon, '1day');
      expect(result.score, 0.92);
      expect(result.reasoning, 'Strong AI growth potential');
    });

    test('AgentResult display methods work correctly', () {
      final result = AgentResult(
        id: 'test',
        agentType: 'analysis_agent_1week',
        stockSymbol: 'TSLA',
        horizon: '1week',
        score: 0.88,
        reasoning: 'EV growth',
        createdAt: DateTime.now(),
      );

      expect(result.displayAgentType, '1-Week Analysis');
      expect(result.displayHorizon, '1 Week');
      expect(result.formattedScore, '88.0%');
    });
  });

  group('AgentStatus Model Tests', () {
    test('AgentStatus fromJson creates valid instance', () {
      final json = {
        'agent_type': 'data_agent',
        'status': 'active',
        'last_run': '2025-08-03T20:45:31.518443537Z',
        'total_results': 150,
      };

      final status = AgentStatus.fromJson(json);

      expect(status.agentType, 'data_agent');
      expect(status.status, 'active');
      expect(status.totalResults, 150);
      expect(status.lastRun, isNotNull);
    });

    test('AgentStatus display methods work correctly', () {
      final status = AgentStatus(
        agentType: 'analysis_agent_1month',
        status: 'active',
        totalResults: 75,
      );

      expect(status.displayAgentType, '1-Month Analysis Agent');
      expect(status.statusColor, '#4CAF50'); // Green for active
      expect(status.lastRunDisplay, 'Never');
    });
  });

  group('Data Validation Tests', () {
    test('Score validation ranges', () {
      final validScores = [0.0, 0.5, 1.0, 0.234, 0.999];
      
      for (final score in validScores) {
        expect(score >= 0.0 && score <= 1.0, true,
               reason: 'Score $score should be valid (0.0-1.0)');
      }
    });

    test('Symbol validation patterns', () {
      final validSymbols = ['AAPL', 'NVDA', 'TSLA', 'MSFT', 'GOOGL'];
      
      for (final symbol in validSymbols) {
        expect(symbol.length >= 1 && symbol.length <= 5, true,
               reason: 'Symbol $symbol should be 1-5 characters');
        expect(RegExp(r'^[A-Z]+$').hasMatch(symbol), true,
               reason: 'Symbol $symbol should be uppercase letters only');
      }
    });
  });
}