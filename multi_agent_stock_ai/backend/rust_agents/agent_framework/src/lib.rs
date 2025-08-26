
use std::collections::HashMap;
use std::time::{Duration, Instant};
use std::sync::{Arc, Mutex};
use reqwest::Client;
use tokio::time::sleep;

/// MCP Handler for abstract tool access
pub struct McpClient {
    client: Client,
}

impl McpClient {
    pub fn new() -> Self {
        Self { client: Client::new() }
    }

    pub async fn query_api(&self, endpoint: &str) -> Result<String, reqwest::Error> {
        let res = self.client.get(endpoint).send().await?.text().await?;
        Ok(res)
    }
}

/// A2A Protocol Implementation for communication between agents
#[derive(Clone)]
pub struct A2A {
    peers: Arc<Mutex<HashMap<String, String>>>, // agent_id -> endpoint
}

impl A2A {
    pub fn new() -> Self {
        Self {
            peers: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn register(&self, id: &str, endpoint: &str) {
        self.peers.lock().unwrap().insert(id.to_string(), endpoint.to_string());
    }

    pub fn get_peers(&self) -> HashMap<String, String> {
        self.peers.lock().unwrap().clone()
    }
}

/// Circuit breaker and retry logic
pub async fn fetch_with_resilience<F, T>(mut task: F) -> Result<T, &'static str>
where
    F: FnMut() -> Result<T, &'static str>,
{
    let mut failures = 0;
    while failures < 3 {
        match task() {
            Ok(result) => return Ok(result),
            Err(_) => {
                failures += 1;
                sleep(Duration::from_secs(failures)).await;
            }
        }
    }
    Err("Circuit breaker triggered after retries")
}
