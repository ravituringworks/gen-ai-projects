use axum::{extract::State, routing::get, Json, Router};
use common::{app_state, AppState};
use sqlx::Row;
use std::net::SocketAddr;
use tracing_subscriber::EnvFilter;
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();
    let s = app_state().await?;
    let app = Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/v1/recs/home", get(home))
        .with_state(s);
    let addr: SocketAddr = "127.0.0.1:4004".parse()?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
async fn home(State(s): State<AppState>) -> Json<serde_json::Value> {
    let rows = sqlx::query("SELECT id,title FROM tracks ORDER BY created_at DESC LIMIT 10")
        .fetch_all(&s.pool)
        .await
        .unwrap_or_default();
    let items:Vec<_>=rows.iter().map(|r| serde_json::json!({"id":r.get::<uuid::Uuid,_>("id").to_string(),"title":r.get::<String,_>("title")})).collect();
    Json(serde_json::json!({"mixes":[{"title":"New For You","items":items}]}))
}
