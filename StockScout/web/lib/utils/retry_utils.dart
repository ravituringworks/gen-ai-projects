import 'dart:async';
import 'dart:math';

/// Configuration for retry behavior
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

/// Retry a function with exponential backoff
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation,
  RetryConfig config,
) async {
  Exception? lastException;
  Duration delay = config.baseDelay;

  for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
    try {
      final result = await operation();
      if (attempt > 1) {
        print('Operation succeeded on attempt $attempt');
      }
      return result;
    } catch (e) {
      print('Operation failed on attempt $attempt: $e');
      lastException = e is Exception ? e : Exception(e.toString());

      if (attempt < config.maxAttempts) {
        print('Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        
        // Calculate next delay with exponential backoff
        final nextDelayMs = (delay.inMilliseconds * config.backoffMultiplier).round();
        delay = Duration(
          milliseconds: min(nextDelayMs, config.maxDelay.inMilliseconds),
        );
      }
    }
  }

  throw lastException ?? Exception('All retry attempts failed');
}

/// Circuit breaker states
enum CircuitState {
  closed,   // Normal operation
  open,     // Circuit is open, rejecting calls
  halfOpen, // Testing if service has recovered
}

/// Configuration for circuit breaker
class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration recoveryTimeout;
  final int successThreshold; // For half-open state

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(seconds: 60),
    this.successThreshold = 3,
  });
}

/// Circuit breaker implementation
class CircuitBreaker {
  final CircuitBreakerConfig _config;
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;

  CircuitBreaker(this._config);

  /// Execute an operation with circuit breaker protection
  Future<T> call<T>(Future<T> Function() operation) async {
    if (!_shouldAttemptCall()) {
      throw Exception('Circuit breaker is open');
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptCall() {
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) >= _config.recoveryTimeout) {
          print('Circuit breaker transitioning to half-open');
          _state = CircuitState.halfOpen;
          _successCount = 0;
          return true;
        }
        return false;
      case CircuitState.halfOpen:
        return true;
    }
  }

  void _onSuccess() {
    switch (_state) {
      case CircuitState.closed:
        _failureCount = 0;
        break;
      case CircuitState.halfOpen:
        _successCount++;
        if (_successCount >= _config.successThreshold) {
          print('Circuit breaker closing after successful recovery');
          _state = CircuitState.closed;
          _failureCount = 0;
          _successCount = 0;
          _lastFailureTime = null;
        }
        break;
      case CircuitState.open:
        // Should not happen
        break;
    }
  }

  void _onFailure() {
    switch (_state) {
      case CircuitState.closed:
        _failureCount++;
        if (_failureCount >= _config.failureThreshold) {
          print('Circuit breaker opening due to $_failureCount failures');
          _state = CircuitState.open;
          _lastFailureTime = DateTime.now();
        }
        break;
      case CircuitState.halfOpen:
        print('Circuit breaker reopening due to failure during recovery');
        _state = CircuitState.open;
        _failureCount++;
        _successCount = 0;
        _lastFailureTime = DateTime.now();
        break;
      case CircuitState.open:
        _lastFailureTime = DateTime.now();
        break;
    }
  }

  CircuitState get state => _state;
  int get failureCount => _failureCount;
}

/// Simple cache entry
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Simple in-memory cache
class Cache<K, V> {
  final Duration _defaultTtl;
  final Map<K, _CacheEntry<V>> _store = {};

  Cache(this._defaultTtl);

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

  void set(K key, V value, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? _defaultTtl);
    _store[key] = _CacheEntry(value, expiresAt);
  }

  void remove(K key) {
    _store.remove(key);
  }

  void clear() {
    _store.clear();
  }

  int get size => _store.length;

  void cleanupExpired() {
    final now = DateTime.now();
    _store.removeWhere((key, entry) => entry.expiresAt.isBefore(now));
  }
}