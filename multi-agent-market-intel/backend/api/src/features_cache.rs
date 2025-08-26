use redis::AsyncCommands;

pub async fn put_feature(symbol: &str, json_row: &serde_json::Value) -> anyhow::Result<()> {
  let url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1/".into());
  let client = redis::Client::open(url)?; let mut con = client.get_async_connection().await?;
  let key = format!("feat:{}", symbol);
  let _: () = con.set_ex(key, json_row.to_string(), 60).await?; // 60s TTL
  Ok(())
}
