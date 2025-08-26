use std::collections::HashMap;
use std::hash::Hash;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};


#[derive(Clone, Debug)]
pub struct CacheEntry<T> {
    pub value: T,
    pub expires_at: Instant,
}

impl<T> CacheEntry<T> {
    pub fn new(value: T, ttl: Duration) -> Self {
        Self {
            value,
            expires_at: Instant::now() + ttl,
        }
    }

    pub fn is_expired(&self) -> bool {
        Instant::now() > self.expires_at
    }
}

pub struct Cache<K, V> 
where
    K: Eq + Hash + Clone,
    V: Clone,
{
    store: Arc<Mutex<HashMap<K, CacheEntry<V>>>>,
    default_ttl: Duration,
}

impl<K, V> Cache<K, V>
where
    K: Eq + Hash + Clone,
    V: Clone,
{
    pub fn new(default_ttl: Duration) -> Self {
        Self {
            store: Arc::new(Mutex::new(HashMap::new())),
            default_ttl,
        }
    }

    pub fn get(&self, key: &K) -> Option<V> {
        let mut store = self.store.lock().unwrap();
        
        if let Some(entry) = store.get(key) {
            if !entry.is_expired() {
                return Some(entry.value.clone());
            } else {
                // Remove expired entry
                store.remove(key);
            }
        }
        
        None
    }

    pub fn set(&self, key: K, value: V) {
        self.set_with_ttl(key, value, self.default_ttl);
    }

    pub fn set_with_ttl(&self, key: K, value: V, ttl: Duration) {
        let mut store = self.store.lock().unwrap();
        store.insert(key, CacheEntry::new(value, ttl));
    }

    pub fn remove(&self, key: &K) -> Option<V> {
        let mut store = self.store.lock().unwrap();
        store.remove(key).map(|entry| entry.value)
    }

    pub fn clear(&self) {
        let mut store = self.store.lock().unwrap();
        store.clear();
    }

    pub fn cleanup_expired(&self) {
        let mut store = self.store.lock().unwrap();
        let now = Instant::now();
        store.retain(|_, entry| entry.expires_at > now);
    }

    pub fn size(&self) -> usize {
        let store = self.store.lock().unwrap();
        store.len()
    }

    pub async fn get_or_set<F, Fut>(&self, key: K, fetch_fn: F) -> Result<V, anyhow::Error>
    where
        F: FnOnce() -> Fut,
        Fut: std::future::Future<Output = Result<V, anyhow::Error>>,
    {
        // Try to get from cache first
        if let Some(cached_value) = self.get(&key) {
            return Ok(cached_value);
        }

        // Cache miss - fetch the value
        let value = fetch_fn().await?;
        self.set(key, value.clone());
        Ok(value)
    }
}

// Cache configurations for different data types
#[derive(Clone, Debug)]
pub struct CacheConfig {
    pub stock_data_ttl: Duration,
    pub agent_status_ttl: Duration,
    pub api_response_ttl: Duration,
    pub health_check_ttl: Duration,
}

impl Default for CacheConfig {
    fn default() -> Self {
        Self {
            stock_data_ttl: Duration::from_secs(300),      // 5 minutes
            agent_status_ttl: Duration::from_secs(60),     // 1 minute
            api_response_ttl: Duration::from_secs(180),    // 3 minutes
            health_check_ttl: Duration::from_secs(30),     // 30 seconds
        }
    }
}

// Application-specific cache manager
pub struct AppCache {
    pub stock_cache: Cache<String, Vec<crate::models::Stock>>,
    pub agent_status_cache: Cache<String, Vec<crate::models::AgentStatus>>,
    pub health_cache: Cache<String, bool>,
    config: CacheConfig,
}

impl AppCache {
    pub fn new(config: CacheConfig) -> Self {
        Self {
            stock_cache: Cache::new(config.stock_data_ttl),
            agent_status_cache: Cache::new(config.agent_status_ttl),
            health_cache: Cache::new(config.health_check_ttl),
            config,
        }
    }

    pub fn cleanup_all(&self) {
        self.stock_cache.cleanup_expired();
        self.agent_status_cache.cleanup_expired();
        self.health_cache.cleanup_expired();
    }
}

impl Default for AppCache {
    fn default() -> Self {
        Self::new(CacheConfig::default())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::time::sleep;

    #[test]
    fn test_cache_set_and_get() {
        let cache = Cache::new(Duration::from_secs(1));
        cache.set("key1".to_string(), 42);
        
        assert_eq!(cache.get(&"key1".to_string()), Some(42));
        assert_eq!(cache.get(&"key2".to_string()), None);
    }

    #[tokio::test]
    async fn test_cache_expiration() {
        let cache = Cache::new(Duration::from_millis(10));
        cache.set("key1".to_string(), 42);
        
        assert_eq!(cache.get(&"key1".to_string()), Some(42));
        
        sleep(Duration::from_millis(15)).await;
        assert_eq!(cache.get(&"key1".to_string()), None);
    }

    #[tokio::test]
    async fn test_get_or_set() {
        let cache = Cache::new(Duration::from_secs(1));
        
        // First call should fetch and cache
        let result1 = cache.get_or_set("key1".to_string(), || async {
            Ok::<i32, anyhow::Error>(42)
        }).await;
        assert_eq!(result1.unwrap(), 42);
        
        // Second call should return cached value
        let result2 = cache.get_or_set("key1".to_string(), || async {
            Ok::<i32, anyhow::Error>(99) // This shouldn't be called
        }).await;
        assert_eq!(result2.unwrap(), 42);
    }

    #[test]
    fn test_cache_cleanup() {
        let cache = Cache::new(Duration::from_millis(1));
        cache.set("key1".to_string(), 42);
        cache.set("key2".to_string(), 43);
        
        assert_eq!(cache.size(), 2);
        
        std::thread::sleep(Duration::from_millis(5));
        cache.cleanup_expired();
        
        assert_eq!(cache.size(), 0);
    }
}