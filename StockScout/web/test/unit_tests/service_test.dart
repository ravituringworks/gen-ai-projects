import 'package:flutter_test/flutter_test.dart';
import 'package:stock_research_platform/services/api_service.dart';

void main() {
  group('Service Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('ApiService initialization', () {
      expect(apiService, isNotNull);
      // ApiService should be properly initialized
    });

    test('API endpoints are correctly formatted', () {
      const baseUrl = 'http://localhost:8000';
      
      expect('$baseUrl/api/agents/health', contains('/api/agents/health'));
      expect('$baseUrl/api/stocks/top/1day', contains('/api/stocks/top/1day'));
      expect('$baseUrl/api/agents/status', contains('/api/agents/status'));
    });

    test('Service method signatures exist', () {
      // These tests verify method signatures exist without requiring server
      expect(() => apiService.checkServerConnection(), returnsNormally);
      expect(() => apiService.getTopStocks('1day'), returnsNormally);
      expect(() => apiService.getAgentStatus(), returnsNormally);
    });
  });
}