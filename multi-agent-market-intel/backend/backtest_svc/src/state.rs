use sqlx::postgres::PgPoolOptions;
use anyhow::Result;

#[derive(Clone)]
pub struct AppState { pub db: sqlx::Pool<sqlx::Postgres> }

impl AppState {
  pub async fn new() -> Result<Self> {
    let db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL");
    let pool = PgPoolOptions::new().max_connections(10).connect(&db_url).await?;
    Ok(Self{ db: pool })
  }
}
