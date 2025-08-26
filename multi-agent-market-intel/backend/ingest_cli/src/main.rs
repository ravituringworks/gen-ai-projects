use chrono::{DateTime, Utc};
use serde::Deserialize;

#[derive(Deserialize)]
struct Row { ts: DateTime<Utc>, symbol: String, open: f64, high: f64, low: f64, close: f64, volume: f64 }

#[tokio::main]
async fn main() -> anyhow::Result<()> {
  let db = std::env::var("DATABASE_URL").expect("DATABASE_URL");
  let pool = sqlx::postgres::PgPoolOptions::new().max_connections(5).connect(&db).await?;
  let path = std::env::args().nth(1).expect("csv path");
  let mut rdr = csv::Reader::from_path(path)?;
  let mut tx = pool.begin().await?;
  for res in rdr.deserialize(){ let r: Row = res?;
    sqlx::query!("INSERT INTO ohlcv(ts,symbol,open,high,low,close,volume) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(symbol,ts) DO UPDATE SET open=EXCLUDED.open,high=EXCLUDED.high,low=EXCLUDED.low,close=EXCLUDED.close,volume=EXCLUDED.volume", r.ts, r.symbol, r.open, r.high, r.low, r.close, r.volume).execute(&mut *tx).await?;
  }
  tx.commit().await?; Ok(())
}
