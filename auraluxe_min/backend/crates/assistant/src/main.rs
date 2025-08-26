use axum::{
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tracing_subscriber::EnvFilter;
#[derive(Deserialize)]
struct ChatReq {
    messages: Vec<Msg>,
}
#[derive(Deserialize)]
struct Msg {
    role: String,
    content: String,
}
#[derive(Serialize)]
struct Resp {
    reply: String,
    seeds: Vec<String>,
}
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();
    let app = Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/v1/assistant/chat", post(chat));
    let addr: SocketAddr = "127.0.0.1:4005".parse()?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
async fn chat(Json(r): Json<ChatReq>) -> Json<Resp> {
    let last = r
        .messages
        .last()
        .map(|m| m.content.to_lowercase())
        .unwrap_or_default();
    let mut seeds = vec!["focus".to_string(), "chill".to_string()];
    if last.contains("jazz") {
        seeds = vec!["smooth_jazz".into(), "late_night".into()]
    }
    if last.contains("workout") {
        seeds = vec!["power".into(), "edm".into()]
    }
    Json(Resp {
        reply: format!("Queueing a mix based on: {}", seeds.join(", ")),
        seeds,
    })
}
