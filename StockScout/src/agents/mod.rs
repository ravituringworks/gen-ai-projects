use anyhow::Result;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use crate::models::AgentResult;

pub mod data_agent;
pub mod analysis_agent;
pub mod coordinator_agent;

#[async_trait::async_trait]
pub trait Agent {
    async fn execute(&self) -> Result<Vec<AgentResult>>;
    fn get_agent_type(&self) -> String;
}

pub struct AgentCommunicator {
    // Simple message passing system for agents
}

impl AgentCommunicator {
    pub fn new() -> Self {
        Self {}
    }

    pub async fn send_message(&self, _message: AgentMessage) -> Result<()> {
        // For now, just log the message
        log::info!("Agent message sent: {:?}", _message);
        Ok(())
    }

    pub async fn receive_messages(&self) -> Result<Vec<AgentMessage>> {
        // For now, return empty vec
        Ok(vec![])
    }

    pub async fn broadcast(&self, _message: AgentMessage) -> Result<()> {
        // For now, just log the message
        log::info!("Agent broadcast sent: {:?}", _message);
        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentMessage {
    pub from: String,
    pub to: String,
    pub message_type: String,
    pub payload: serde_json::Value,
    pub timestamp: DateTime<Utc>,
}

impl AgentMessage {
    pub fn new(from: String, to: String, message_type: String, payload: serde_json::Value) -> Self {
        Self {
            from,
            to,
            message_type,
            payload,
            timestamp: Utc::now(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_agent_message_creation() {
        let message = AgentMessage::new(
            "data-agent".to_string(),
            "analysis-agent".to_string(),
            "stock-data".to_string(),
            json!({"symbol": "AAPL", "price": 150.0}),
        );

        assert_eq!(message.from, "data-agent");
        assert_eq!(message.to, "analysis-agent");
        assert_eq!(message.message_type, "stock-data");
        assert_eq!(message.payload["symbol"], "AAPL");
        assert!(message.timestamp <= Utc::now());
    }

    #[test]
    fn test_agent_message_serialization() {
        let message = AgentMessage::new(
            "test-from".to_string(),
            "test-to".to_string(),
            "test-type".to_string(),
            json!({"test": "data"}),
        );

        let json = serde_json::to_string(&message).unwrap();
        assert!(json.contains("test-from"));
        assert!(json.contains("test-to"));
        assert!(json.contains("test-type"));

        let deserialized: AgentMessage = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.from, "test-from");
        assert_eq!(deserialized.to, "test-to");
        assert_eq!(deserialized.message_type, "test-type");
    }
}