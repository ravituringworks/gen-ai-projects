use sqlx::postgres::PgPoolOptions;
#[derive(Clone)]
pub struct AppState { pub db: sqlx::Pool<sqlx::Postgres> }
impl AppState { pub async fn new() -> anyhow::Result<Self>{
  let url = std::env::var("DATABASE_URL").expect("DATABASE_URL");
  let pool = PgPoolOptions::new().max_connections(10).connect(&url).await?; Ok(Self{ db: pool }) }
}
