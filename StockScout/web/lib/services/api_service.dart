import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/stock.dart';
import '../models/agent_result.dart';
import '../utils/retry_utils.dart';
import 'dart:async';

class ApiService extends ChangeNotifier {
  // Use current host instead of hardcoded localhost
  static String get baseUrl {
    final uri = Uri.base;
    return '${uri.scheme}://${uri.host}:8000/api';
  }
  
  bool _isLoading = false;
  String? _error;
  bool _isRetrying = false;
  int _retryCount = 0;
  
  // Resilience components
  final _retryConfig = const RetryConfig(maxAttempts: 3);
  final _circuitBreaker = CircuitBreaker(const CircuitBreakerConfig());
  final _cache = Cache<String, dynamic>(const Duration(minutes: 5));
  
  // Periodically clean expired cache entries
  void _startCacheCleanup() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      _cache.cleanupExpired();
    });
  }
  
  /// Enhanced retry with progressive backoff and user feedback
  Future<T> _retryWithProgressiveBackoff<T>(
    Future<T> Function() operation, {
    bool silent = false,
  }) async {
    Exception? lastException;
    Duration delay = _retryConfig.baseDelay;

    for (int attempt = 1; attempt <= _retryConfig.maxAttempts; attempt++) {
      try {
        if (!silent && attempt > 1) {
          _setRetrying(true, attempt - 1);
        }
        
        final result = await operation();
        
        if (!silent && attempt > 1) {
          print('Operation succeeded on attempt $attempt');
        }
        
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (!silent && attempt > 1) {
          print('Retry attempt $attempt failed: $e');
        }

        if (attempt < _retryConfig.maxAttempts) {
          if (!silent) {
            print('Retrying in ${delay.inMilliseconds}ms... (${attempt}/${_retryConfig.maxAttempts})');
          }
          
          await Future.delayed(delay);
          
          // Calculate next delay with exponential backoff
          final nextDelayMs = (delay.inMilliseconds * _retryConfig.backoffMultiplier).round();
          delay = Duration(
            milliseconds: (nextDelayMs > _retryConfig.maxDelay.inMilliseconds) 
              ? _retryConfig.maxDelay.inMilliseconds 
              : nextDelayMs,
          );
        }
      }
    }

    throw lastException ?? Exception('All retry attempts failed');
  }
  
  ApiService() {
    _startCacheCleanup();
    print('API Service initialized with baseUrl: $baseUrl');
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRetrying => _isRetrying;
  int get retryCount => _retryCount;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _setRetrying(bool retrying, int count) {
    _isRetrying = retrying;
    _retryCount = count;
    notifyListeners();
  }

  Future<List<Stock>> getAllStocks() async {
    const cacheKey = 'all_stocks';
    
    // Check cache first
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      print('Returning cached stocks data');
      return (cached as List<dynamic>).map((json) => Stock.fromJson(json)).toList();
    }
    
    try {
      _setLoading(true);
      _setError(null);
      _setRetrying(false, 0);

      // Execute with circuit breaker and enhanced retry
      final responseData = await _circuitBreaker.call(() async {
        return await _retryWithProgressiveBackoff(() async {
          final response = await http.get(
            Uri.parse('$baseUrl/stocks'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            return json.decode(response.body);
          } else {
            throw Exception('Server returned status ${response.statusCode}');
          }
        });
      });

      // Cache successful response
      _cache.set(cacheKey, responseData);
      
      final List<dynamic> data = responseData as List<dynamic>;
      _setRetrying(false, 0);
      return data.map((json) => Stock.fromJson(json)).toList();
    } catch (e) {
      _setRetrying(false, 0);
      // Only set error after all retries failed, with a user-friendly message
      _setError('Unable to load stock data. Please check your connection.');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<TopStock>> getTopStocks(String horizon) async {
    const cacheKeyPrefix = 'top_stocks_';
    final cacheKey = '$cacheKeyPrefix$horizon';
    
    // Check cache first
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      print('Returning cached top stocks for $horizon');
      return (cached as List<dynamic>).map((json) => TopStock.fromJson(json)).toList();
    }
    
    try {
      _setLoading(true);
      _setError(null);
      _setRetrying(false, 0);

      // Execute with circuit breaker and enhanced retry
      final responseData = await _circuitBreaker.call(() async {
        return await _retryWithProgressiveBackoff(() async {
          final response = await http.get(
            Uri.parse('$baseUrl/stocks/top/$horizon'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            return json.decode(response.body);
          } else {
            throw Exception('Server returned status ${response.statusCode}');
          }
        });
      });

      // Cache successful response
      final data = responseData as Map<String, dynamic>;
      final List<dynamic> stocksData = data['stocks'] ?? [];
      final stocks = stocksData.map((json) => TopStock.fromJson(json)).toList();
      
      _cache.set(cacheKey, stocksData);
      _setRetrying(false, 0);
      return stocks;
    } catch (e) {
      _setRetrying(false, 0);
      _setError('Unable to load top stocks. Connection issue detected.');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkServerConnection() async {
    const cacheKey = 'server_health';
    
    // Check cache first (short TTL for health checks)
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached as bool;
    }
    
    try {
      // Silent retry for health checks - no UI notification
      final isHealthy = await _circuitBreaker.call(() async {
        return await _retryWithProgressiveBackoff(() async {
          final response = await http.get(
            Uri.parse('$baseUrl/agents/health'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          final success = response.statusCode == 200;
          if (!success) {
            throw Exception('Health check failed with status ${response.statusCode}');
          }
          return success;
        }, silent: true);
      });
      
      // Cache successful health check (short duration)
      _cache.set(cacheKey, isHealthy, ttl: const Duration(seconds: 30));
      return isHealthy;
    } catch (e) {
      // Silent failure for health check - don't spam logs
      return false;
    }
  }

  Future<Map<String, List<TopStock>>> getScreeningResults() async {
    const cacheKey = 'screening_results';
    
    // Check cache first
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      print('Returning cached screening results');
      final cachedData = cached as Map<String, dynamic>;
      final Map<String, List<TopStock>> results = {};
      for (final entry in cachedData.entries) {
        results[entry.key] = (entry.value as List<dynamic>)
            .map((json) => TopStock.fromJson(json))
            .toList();
      }
      return results;
    }
    
    try {
      _setLoading(true);
      _setError(null);
      _setRetrying(false, 0);

      // Execute with circuit breaker and enhanced retry
      final responseData = await _circuitBreaker.call(() async {
        return await _retryWithProgressiveBackoff(() async {
          final response = await http.get(
            Uri.parse('$baseUrl/stocks/screening-results'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            return json.decode(response.body);
          } else {
            throw Exception('Server returned status ${response.statusCode}');
          }
        });
      });

      final Map<String, dynamic> data = responseData as Map<String, dynamic>;
      final Map<String, List<TopStock>> results = {};
      
      for (final entry in data.entries) {
        if (entry.value is Map<String, dynamic>) {
          final stockData = entry.value as Map<String, dynamic>;
          if (stockData['stocks'] is List) {
            final List<dynamic> stocksList = stockData['stocks'];
            results[entry.key] = stocksList
                .map((json) => TopStock.fromJson(json))
                .toList();
          }
        }
      }
      
      // Cache successful response
      final cacheData = <String, dynamic>{};
      for (final entry in results.entries) {
        cacheData[entry.key] = entry.value.map((stock) => stock.toJson()).toList();
      }
      _cache.set(cacheKey, cacheData);
      
      _setRetrying(false, 0);
      return results;
    } catch (e) {
      _setRetrying(false, 0);
      _setError('Unable to load screening results. Connection issue detected.');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  Future<List<AgentStatus>> getAgentStatus() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.get(
        Uri.parse('$baseUrl/agents/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> agents = data['agents'] ?? [];
        return agents.map((json) => AgentStatus.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load agent status: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to fetch agent status: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> triggerScreening() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.post(
        Uri.parse('$baseUrl/agents/trigger-screening'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['status'] == 'success';
      } else {
        throw Exception('Failed to trigger screening: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to trigger screening: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Utility method to check API health
  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agents/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('API health check failed: $e');
      }
      return false;
    }
  }
}
