
use agent_framework::{A2A, McpClient};
use std::error::Error;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let mcp = McpClient::new();
    let historical_data = mcp.query_api("https://api.example.com/historical/AAPL")
        .await
        .unwrap_or("No forecast data".into());

    println!("Forecast Agent Output: {}", historical_data);
    Ok(())
}
