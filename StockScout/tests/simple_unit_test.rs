use stock_research_platform::agents::{AgentMessage, AgentCommunicator};
use serde_json::json;
use chrono::Utc;

#[test]
fn test_agent_message_creation() {
    let message = AgentMessage::new(
        "test-agent".to_string(),
        "target-agent".to_string(),
        "test-message".to_string(),
        json!({"data": "test"}),
    );

    assert_eq!(message.from, "test-agent");
    assert_eq!(message.to, "target-agent");
    assert_eq!(message.message_type, "test-message");
    assert!(message.timestamp <= Utc::now());
}

#[test]
fn test_agent_communicator_creation() {
    let communicator = AgentCommunicator::new();
    // If we reach here without panic, creation succeeded
    assert!(true);
}

#[tokio::test]
async fn test_agent_message_sending() {
    let communicator = AgentCommunicator::new();
    let message = AgentMessage::new(
        "sender".to_string(),
        "receiver".to_string(),
        "test".to_string(),
        json!({"content": "Hello"}),
    );

    // This should not panic
    let result = communicator.send_message(message).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_agent_broadcast() {
    let communicator = AgentCommunicator::new();
    let message = AgentMessage::new(
        "broadcaster".to_string(),
        "all".to_string(),
        "broadcast".to_string(),
        json!({"announcement": "System update"}),
    );

    let result = communicator.broadcast(message).await;
    assert!(result.is_ok());
}