use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use anyhow::Result;

#[derive(Debug, Clone, PartialEq)]
pub enum CircuitState {
    Closed,    // Normal operation
    Open,      // Circuit is open, rejecting calls
    HalfOpen,  // Testing if service has recovered
}

#[derive(Clone, Debug)]
pub struct CircuitBreakerConfig {
    pub failure_threshold: u32,
    pub recovery_timeout: Duration,
    pub success_threshold: u32, // For half-open state
}

impl Default for CircuitBreakerConfig {
    fn default() -> Self {
        Self {
            failure_threshold: 5,
            recovery_timeout: Duration::from_secs(60),
            success_threshold: 3,
        }
    }
}

#[derive(Debug)]
struct CircuitBreakerState {
    state: CircuitState,
    failure_count: u32,
    success_count: u32,
    last_failure_time: Option<Instant>,
}

pub struct CircuitBreaker {
    config: CircuitBreakerConfig,
    state: Arc<Mutex<CircuitBreakerState>>,
}

impl CircuitBreaker {
    pub fn new(config: CircuitBreakerConfig) -> Self {
        Self {
            config,
            state: Arc::new(Mutex::new(CircuitBreakerState {
                state: CircuitState::Closed,
                failure_count: 0,
                success_count: 0,
                last_failure_time: None,
            })),
        }
    }

    pub async fn call<T, F, Fut>(&self, operation: F) -> Result<T>
    where
        F: FnOnce() -> Fut,
        Fut: std::future::Future<Output = Result<T>>,
    {
        // Check if we should attempt the call
        if !self.should_attempt_call() {
            return Err(anyhow::anyhow!("Circuit breaker is open"));
        }

        // Execute the operation
        match operation().await {
            Ok(result) => {
                self.on_success();
                Ok(result)
            }
            Err(err) => {
                self.on_failure();
                Err(err)
            }
        }
    }

    fn should_attempt_call(&self) -> bool {
        let mut state = self.state.lock().unwrap();
        
        match state.state {
            CircuitState::Closed => true,
            CircuitState::Open => {
                if let Some(last_failure) = state.last_failure_time {
                    if last_failure.elapsed() >= self.config.recovery_timeout {
                        log::info!("Circuit breaker transitioning to half-open");
                        state.state = CircuitState::HalfOpen;
                        state.success_count = 0;
                        true
                    } else {
                        false
                    }
                } else {
                    false
                }
            }
            CircuitState::HalfOpen => true,
        }
    }

    fn on_success(&self) {
        let mut state = self.state.lock().unwrap();
        
        match state.state {
            CircuitState::Closed => {
                state.failure_count = 0;
            }
            CircuitState::HalfOpen => {
                state.success_count += 1;
                if state.success_count >= self.config.success_threshold {
                    log::info!("Circuit breaker closing after successful recovery");
                    state.state = CircuitState::Closed;
                    state.failure_count = 0;
                    state.success_count = 0;
                    state.last_failure_time = None;
                }
            }
            CircuitState::Open => {} // Should not happen
        }
    }

    fn on_failure(&self) {
        let mut state = self.state.lock().unwrap();
        
        match state.state {
            CircuitState::Closed => {
                state.failure_count += 1;
                if state.failure_count >= self.config.failure_threshold {
                    log::warn!("Circuit breaker opening due to {} failures", state.failure_count);
                    state.state = CircuitState::Open;
                    state.last_failure_time = Some(Instant::now());
                }
            }
            CircuitState::HalfOpen => {
                log::warn!("Circuit breaker reopening due to failure during recovery");
                state.state = CircuitState::Open;
                state.failure_count += 1;
                state.success_count = 0;
                state.last_failure_time = Some(Instant::now());
            }
            CircuitState::Open => {
                state.last_failure_time = Some(Instant::now());
            }
        }
    }

    pub fn get_state(&self) -> CircuitState {
        self.state.lock().unwrap().state.clone()
    }

    pub fn get_failure_count(&self) -> u32 {
        self.state.lock().unwrap().failure_count
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::time::sleep;

    #[tokio::test]
    async fn test_circuit_breaker_closed_state() {
        let config = CircuitBreakerConfig::default();
        let breaker = CircuitBreaker::new(config);
        
        let result = breaker.call(|| async { Ok::<i32, anyhow::Error>(42) }).await;
        assert_eq!(result.unwrap(), 42);
        assert_eq!(breaker.get_state(), CircuitState::Closed);
    }

    #[tokio::test]
    async fn test_circuit_breaker_opens_after_failures() {
        let config = CircuitBreakerConfig {
            failure_threshold: 2,
            recovery_timeout: Duration::from_secs(1),
            success_threshold: 1,
        };
        let breaker = CircuitBreaker::new(config);
        
        // First failure
        let _ = breaker.call(|| async { Err::<i32, anyhow::Error>(anyhow::anyhow!("Fail")) }).await;
        assert_eq!(breaker.get_state(), CircuitState::Closed);
        
        // Second failure - should open circuit
        let _ = breaker.call(|| async { Err::<i32, anyhow::Error>(anyhow::anyhow!("Fail")) }).await;
        assert_eq!(breaker.get_state(), CircuitState::Open);
        
        // Next call should be rejected
        let result = breaker.call(|| async { Ok::<i32, anyhow::Error>(42) }).await;
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Circuit breaker is open"));
    }

    #[tokio::test]
    async fn test_circuit_breaker_recovery() {
        let config = CircuitBreakerConfig {
            failure_threshold: 1,
            recovery_timeout: Duration::from_millis(10),
            success_threshold: 1,
        };
        let breaker = CircuitBreaker::new(config);
        
        // Cause failure to open circuit
        let _ = breaker.call(|| async { Err::<i32, anyhow::Error>(anyhow::anyhow!("Fail")) }).await;
        assert_eq!(breaker.get_state(), CircuitState::Open);
        
        // Wait for recovery timeout
        sleep(Duration::from_millis(20)).await;
        
        // Should transition to half-open and allow successful call
        let result = breaker.call(|| async { Ok::<i32, anyhow::Error>(42) }).await;
        assert_eq!(result.unwrap(), 42);
        assert_eq!(breaker.get_state(), CircuitState::Closed);
    }
}