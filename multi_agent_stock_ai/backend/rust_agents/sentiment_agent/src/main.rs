
use agent_framework::{A2A, McpClient};
use std::error::Error;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let mcp = McpClient::new();
    let data = mcp.query_api("https://newsapi.org/v2/everything?q=NASDAQ&apiKey=demo")
        .await
        .unwrap_or("No sentiment data".into());

    println!("Sentiment Agent Output: {}", data);
    Ok(())
}
