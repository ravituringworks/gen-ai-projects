use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use common::{app_state, AppState};
use serde::Deserialize;
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
        .route("/v1/stream/manifest/:id", get(manifest))
        .route("/v1/stream/complete", post(complete))
        .with_state(s);
    let addr: SocketAddr = "127.0.0.1:4002".parse()?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
async fn manifest(Path(id): Path<String>) -> Json<serde_json::Value> {
    Json(
        serde_json::json!({"track_id":id,"type":"hls","url":"https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"}),
    )
}
#[derive(Deserialize)]
struct C {
    user_email: String,
    track_id: String,
    completed_ms: i64,
}
async fn complete(State(s): State<AppState>, Json(b): Json<C>) -> Json<serde_json::Value> {
    let uid: Option<uuid::Uuid> = sqlx::query_scalar("SELECT id FROM users WHERE email=$1")
        .bind(&b.user_email)
        .fetch_optional(&s.pool)
        .await
        .unwrap();
    if let Some(u) = uid {
        sqlx::query(
            "INSERT INTO play_events(user_id,track_id,completed_ms) VALUES($1,$2::uuid,$3)",
        )
        .bind(u)
        .bind(&b.track_id)
        .bind(b.completed_ms)
        .execute(&s.pool)
        .await
        .ok();
    }
    Json(serde_json::json!({"ok":true}))
}
