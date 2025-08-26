
use agent_framework::{A2A, McpClient, fetch_with_resilience};
use std::error::Error;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let a2a = A2A::new();
    let mcp = McpClient::new();

    let data = fetch_with_resilience(|| {
        mcp.query_api("https://query1.finance.yahoo.com/v7/finance/quote?symbols=AAPL")
            .map_err(|_| "fetch failed")
    })
    .await?;

    println!("Trend Agent Analysis: {}", data);
    Ok(())
}
