use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};
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
        .route("/v1/lyrics/:id", get(get_lyrics))
        .with_state(s);
    let addr: SocketAddr = "127.0.0.1:4006".parse()?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
async fn get_lyrics(State(s): State<AppState>, Path(id): Path<String>) -> Json<serde_json::Value> {
    let row = sqlx::query("SELECT lrc FROM lyrics WHERE track_id=$1::uuid")
        .bind(&id)
        .fetch_optional(&s.pool)
        .await
        .unwrap();
    if let Some(r) = row {
        Json(serde_json::json!({"track_id":id,"lrc":r.get::<String,_>("lrc")}))
    } else {
        Json(
            serde_json::json!({"track_id":id,"lrc":"[00:00.00] Demo Track\n[00:05.00] Hello world"}),
        )
    }
}
