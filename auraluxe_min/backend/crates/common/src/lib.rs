use anyhow::Result;
use sqlx::{Pool, Postgres};
use std::env;
#[derive(Clone)]
pub struct AppState {
    pub pool: Pool<Postgres>,
}
pub async fn app_state() -> Result<AppState> {
    let url = env::var("DATABASE_URL")
        .unwrap_or("postgres://auraluxe:auraluxe@localhost:5432/auraluxe".into());
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(8)
        .connect(&url)
        .await?;
    Ok(AppState { pool })
}
