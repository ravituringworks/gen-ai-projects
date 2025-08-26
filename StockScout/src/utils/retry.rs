use std::time::Duration;
use tokio::time::sleep;
use anyhow::Result;

#[derive(Clone, Debug)]
pub struct RetryConfig {
    pub max_attempts: u32,
    pub base_delay: Duration,
    pub max_delay: Duration,
    pub backoff_multiplier: f64,
}

impl Default for RetryConfig {
    fn default() -> Self {
        Self {
            max_attempts: 3,
            base_delay: Duration::from_millis(100),
            max_delay: Duration::from_secs(30),
            backoff_multiplier: 2.0,
        }
    }
}

pub async fn retry_with_backoff<T, F, Fut>(
    config: &RetryConfig,
    operation: F,
) -> Result<T>
where
    F: Fn() -> Fut,
    Fut: std::future::Future<Output = Result<T>>,
{
    let mut last_error = None;
    let mut delay = config.base_delay;

    for attempt in 1..=config.max_attempts {
        match operation().await {
            Ok(result) => {
                if attempt > 1 {
                    log::info!("Operation succeeded on attempt {}", attempt);
                }
                return Ok(result);
            }
            Err(err) => {
                log::warn!("Operation failed on attempt {}: {}", attempt, err);
                last_error = Some(err);

                if attempt < config.max_attempts {
                    log::info!("Retrying in {:?}...", delay);
                    sleep(delay).await;
                    delay = std::cmp::min(
                        Duration::from_millis((delay.as_millis() as f64 * config.backoff_multiplier) as u64),
                        config.max_delay,
                    );
                }
            }
        }
    }

    Err(last_error.unwrap())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::{Arc, Mutex};

    #[tokio::test]
    async fn test_retry_success_on_first_attempt() {
        let config = RetryConfig::default();
        let result = retry_with_backoff(&config, || async { Ok::<i32, anyhow::Error>(42) }).await;
        assert_eq!(result.unwrap(), 42);
    }

    #[tokio::test]
    async fn test_retry_success_on_second_attempt() {
        let config = RetryConfig::default();
        let attempt_count = Arc::new(Mutex::new(0));
        
        let result = retry_with_backoff(&config, || {
            let count = attempt_count.clone();
            async move {
                let mut attempts = count.lock().unwrap();
                *attempts += 1;
                if *attempts == 1 {
                    Err(anyhow::anyhow!("First attempt fails"))
                } else {
                    Ok(42)
                }
            }
        }).await;
        
        assert_eq!(result.unwrap(), 42);
        assert_eq!(*attempt_count.lock().unwrap(), 2);
    }

    #[tokio::test]
    async fn test_retry_all_attempts_fail() {
        let config = RetryConfig {
            max_attempts: 2,
            base_delay: Duration::from_millis(1),
            ..Default::default()
        };
        
        let attempt_count = Arc::new(Mutex::new(0));
        let result = retry_with_backoff(&config, || {
            let count = attempt_count.clone();
            async move {
                let mut attempts = count.lock().unwrap();
                *attempts += 1;
                Err::<i32, anyhow::Error>(anyhow::anyhow!("Always fails"))
            }
        }).await;
        
        assert!(result.is_err());
        assert_eq!(*attempt_count.lock().unwrap(), 2);
    }
}