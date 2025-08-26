use axum::{
    extract::{Path, Query},
    routing::{get, post},
    Json, Router,
};
use serde::Deserialize;
use std::net::SocketAddr;
use tracing_subscriber::EnvFilter;
#[derive(Clone)]
struct Cfg {
    catalog: String,
    playback: String,
    payments: String,
    recs: String,
    assistant: String,
    lyrics: String,
}
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();
    let cfg = Cfg {
        catalog: std::env::var("CATALOG_URL").unwrap_or("http://127.0.0.1:4001".into()),
        playback: std::env::var("PLAYBACK_URL").unwrap_or("http://127.0.0.1:4002".into()),
        payments: std::env::var("PAYMENTS_URL").unwrap_or("http://127.0.0.1:4003".into()),
        recs: std::env::var("RECS_URL").unwrap_or("http://127.0.0.1:4004".into()),
        assistant: std::env::var("ASSISTANT_URL").unwrap_or("http://127.0.0.1:4005".into()),
        lyrics: std::env::var("LYRICS_URL").unwrap_or("http://127.0.0.1:4006".into()),
    };
    let app = Router::new()
        .route("/health", get(|| async { "ok" }))
        .route(
            "/v1/catalog/search",
            get({
                let c = cfg.clone();
                move |q| search(c, q)
            }),
        )
        .route(
            "/v1/tracks/:id",
            get({
                let c = cfg.clone();
                move |p| track(c, p)
            }),
        )
        .route(
            "/v1/recs/home",
            get({
                let c = cfg.clone();
                move |_| recs(c)
            }),
        )
        .route(
            "/v1/stream/manifest/:id",
            get({
                let c = cfg.clone();
                move |p| manifest(c, p)
            }),
        )
        .route(
            "/v1/assistant/chat",
            post({
                let c = cfg.clone();
                move |b| chat(c, b)
            }),
        )
        .route(
            "/v1/lyrics/:id",
            get({
                let c = cfg.clone();
                move |p| lyrics(c, p)
            }),
        )
        .route(
            "/v1/billing/plans",
            get({
                let c = cfg.clone();
                move || plans(c)
            }),
        )
        .route(
            "/v1/billing/subscribe",
            post({
                let c = cfg.clone();
                move |b| subscribe(c, b)
            }),
        );
    let addr: SocketAddr = std::env::var("BIND_ADDR")
        .unwrap_or("127.0.0.1:8080".into())
        .parse()?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
#[derive(Deserialize)]
struct Q {
    q: Option<String>,
}
async fn search(cfg: Cfg, Query(q): Query<Q>) -> Json<serde_json::Value> {
    let url = format!(
        "{}/v1/catalog/search?q={}",
        cfg.catalog,
        q.q.unwrap_or_default()
    );
    let r = reqwest::get(url)
        .await
        .unwrap()
        .json::<serde_json::Value>()
        .await
        .unwrap();
    Json(r)
}
async fn track(cfg: Cfg, Path(id): Path<String>) -> Json<serde_json::Value> {
    let url = format!("{}/v1/tracks/{}", cfg.catalog, id);
    Json(
        reqwest::get(url)
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
async fn recs(cfg: Cfg) -> Json<serde_json::Value> {
    Json(
        reqwest::get(format!("{}/v1/recs/home", cfg.recs))
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
async fn manifest(cfg: Cfg, Path(id): Path<String>) -> Json<serde_json::Value> {
    Json(
        reqwest::get(format!("{}/v1/stream/manifest/{}", cfg.playback, id))
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
async fn chat(cfg: Cfg, Json(b): Json<serde_json::Value>) -> Json<serde_json::Value> {
    Json(
        reqwest::Client::new()
            .post(format!("{}/v1/assistant/chat", cfg.assistant))
            .json(&b)
            .send()
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
async fn lyrics(cfg: Cfg, Path(id): Path<String>) -> Json<serde_json::Value> {
    Json(
        reqwest::get(format!("{}/v1/lyrics/{}", cfg.lyrics, id))
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
async fn plans(cfg: Cfg) -> Json<serde_json::Value> {
    Json(
        reqwest::get(format!("{}/v1/plans", cfg.payments))
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
async fn subscribe(cfg: Cfg, Json(b): Json<serde_json::Value>) -> Json<serde_json::Value> {
    Json(
        reqwest::Client::new()
            .post(format!("{}/v1/subscribe", cfg.payments))
            .json(&b)
            .send()
            .await
            .unwrap()
            .json::<serde_json::Value>()
            .await
            .unwrap(),
    )
}
