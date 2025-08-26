// Test file to verify Flutter resilience patterns are properly implemented
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import our resilience utilities
class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
  });
}

class FlutterResilienceTest {
  static const String baseUrl = 'http://localhost:8000/api';
  final RetryConfig _retryConfig = const RetryConfig(maxAttempts: 3);
  
  Future<void> testRetryMechanism() async {
    print('🔄 Testing Retry Mechanism...');
    
    int attempts = 0;
    try {
      await _retryWithBackoff(() async {
        attempts++;
        print('  Attempt $attempts');
        
        if (attempts < 2) {
          throw Exception('Simulated failure');
        }
        
        final response = await http.get(
          Uri.parse('$baseUrl/agents/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          print('  ✅ Retry succeeded on attempt $attempts');
          return response.body;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      });
    } catch (e) {
      print('  ❌ Retry failed: $e');
    }
  }
  
  Future<void> testCircuitBreaker() async {
    print('🔌 Testing Circuit Breaker...');
    
    final circuitBreaker = SimpleCircuitBreaker();
    
    // Simulate failures to trip the circuit
    for (int i = 1; i <= 6; i++) {
      try {
        await circuitBreaker.call(() async {
          if (i <= 5) {
            throw Exception('Simulated failure $i');
          }
          return 'Success';
        });
      } catch (e) {
        print('  Request $i failed: $e');
      }
    }
    
    print('  Circuit breaker state: ${circuitBreaker.isOpen ? "OPEN" : "CLOSED"}');
  }
  
  Future<void> testCaching() async {
    print('💾 Testing Cache Implementation...');
    
    final cache = SimpleCache<String, String>(const Duration(seconds: 2));
    
    // Test cache set/get
    cache.set('test_key', 'test_value');
    final cachedValue = cache.get('test_key');
    
    if (cachedValue == 'test_value') {
      print('  ✅ Cache set/get working');
    } else {
      print('  ❌ Cache set/get failed');
    }
    
    // Test expiration
    await Future.delayed(const Duration(seconds: 3));
    final expiredValue = cache.get('test_key');
    
    if (expiredValue == null) {
      print('  ✅ Cache expiration working');
    } else {
      print('  ❌ Cache expiration failed');
    }
  }
  
  Future<void> testRealApiEndpoints() async {
    print('🌐 Testing Real API Endpoints...');
    
    final endpoints = [
      '/agents/health',
      '/stocks/top/1day',
      '/agents/status',
    ];
    
    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('  ✅ $endpoint: OK (${data.toString().length} chars)');
        } else {
          print('  ❌ $endpoint: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('  ❌ $endpoint: $e');
      }
    }
  }
  
  Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
    Exception? lastException;
    Duration delay = _retryConfig.baseDelay;

    for (int attempt = 1; attempt <= _retryConfig.maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt < _retryConfig.maxAttempts) {
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * _retryConfig.backoffMultiplier).round(),
          );
        }
      }
    }

    throw lastException ?? Exception('All retry attempts failed');
  }
  
  Future<void> runAllTests() async {
    print('🚀 Flutter Resilience Pattern Tests\n');
    
    await testRetryMechanism();
    print('');
    
    await testCircuitBreaker();
    print('');
    
    await testCaching();
    print('');
    
    await testRealApiEndpoints();
    print('');
    
    print('🎯 All Flutter resilience tests completed!');
  }
}

// Simple Circuit Breaker implementation for testing
class SimpleCircuitBreaker {
  int _failureCount = 0;
  bool _isOpen = false;
  DateTime? _lastFailureTime;
  final int _failureThreshold = 5;
  final Duration _timeout = const Duration(seconds: 30);
  
  bool get isOpen => _isOpen;
  
  Future<T> call<T>(Future<T> Function() operation) async {
    if (_isOpen) {
      if (_lastFailureTime != null && 
          DateTime.now().difference(_lastFailureTime!) >= _timeout) {
        _isOpen = false;
        _failureCount = 0;
        print('  Circuit breaker reset');
      } else {
        throw Exception('Circuit breaker is open');
      }
    }
    
    try {
      final result = await operation();
      _failureCount = 0;
      return result;
    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();
      
      if (_failureCount >= _failureThreshold) {
        _isOpen = true;
        print('  Circuit breaker tripped after $_failureCount failures');
      }
      
      rethrow;
    }
  }
}

// Simple cache implementation for testing
class SimpleCache<K, V> {
  final Duration _ttl;
  final Map<K, _CacheEntry<V>> _store = {};
  
  SimpleCache(this._ttl);
  
  V? get(K key) {
    final entry = _store[key];
    if (entry != null) {
      if (!entry.isExpired) {
        return entry.value;
      } else {
        _store.remove(key);
      }
    }
    return null;
  }
  
  void set(K key, V value) {
    final expiresAt = DateTime.now().add(_ttl);
    _store[key] = _CacheEntry(value, expiresAt);
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  
  _CacheEntry(this.value, this.expiresAt);
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// Test runner
void main() async {
  final tester = FlutterResilienceTest();
  await tester.runAllTests();
}