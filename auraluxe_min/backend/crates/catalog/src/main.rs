use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Json, Router,
};
use common::{app_state, AppState};
use serde::Deserialize;
use sqlx::Row;
use std::net::SocketAddr;
use tracing_subscriber::EnvFilter;
#[derive(Deserialize)]
struct Q {
    q: Option<String>,
}
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();
    let state = app_state().await?;
    let app = Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/v1/catalog/search", get(search))
        .route("/v1/tracks/:id", get(track))
        .route("/seed", post(seed))
        .with_state(state);
    let addr: SocketAddr = "127.0.0.1:4001".parse()?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
async fn search(State(s): State<AppState>, Query(q): Query<Q>) -> Json<serde_json::Value> {
    let rows=sqlx::query("SELECT t.id,t.title,COALESCE(a.name,'') artist,t.duration_ms FROM tracks t LEFT JOIN albums al ON t.album_id=al.id LEFT JOIN artists a ON al.artist_id=a.id WHERE ($1='' OR t.title ILIKE $2 OR a.name ILIKE $2) ORDER BY t.created_at DESC LIMIT 25").bind(q.q.clone().unwrap_or_default()).bind(format!("%{}%", q.q.unwrap_or_default())).fetch_all(&s.pool).await.unwrap_or_default();
    let items:Vec<_>=rows.iter().map(|r| serde_json::json!({"id":r.get::<uuid::Uuid,_>("id").to_string(),"title":r.get::<String,_>("title"),"artist":r.get::<String,_>("artist"),"duration_ms":r.get::<i32,_>("duration_ms")})).collect();
    Json(serde_json::json!({"items":items}))
}
async fn track(State(s): State<AppState>, Path(id): Path<String>) -> Json<serde_json::Value> {
    let r = sqlx::query("SELECT id,title,duration_ms FROM tracks WHERE id=$1::uuid")
        .bind(&id)
        .fetch_optional(&s.pool)
        .await
        .unwrap();
    if let Some(r) = r {
        Json(
            serde_json::json!({"id":r.get::<uuid::Uuid,_>("id").to_string(),"title":r.get::<String,_>("title"),"duration_ms":r.get::<i32,_>("duration_ms")}),
        )
    } else {
        Json(serde_json::json!({"error":"not_found"}))
    }
}
#[derive(Deserialize)]
struct Seed {
    count: Option<i64>,
}
async fn seed(State(s): State<AppState>, Json(req): Json<Seed>) -> Json<serde_json::Value> {
    let n = req.count.unwrap_or(5);
    let artist_id: uuid::Uuid =
        sqlx::query_scalar("INSERT INTO artists(name) VALUES('Auraluxe Demo') RETURNING id")
            .fetch_one(&s.pool)
            .await
            .unwrap();
    let album_id: uuid::Uuid = sqlx::query_scalar(
        "INSERT INTO albums(artist_id,title) VALUES($1,'Demo Album') RETURNING id",
    )
    .bind(artist_id)
    .fetch_one(&s.pool)
    .await
    .unwrap();
    for i in 0..n {
        sqlx::query("INSERT INTO tracks(album_id,title,duration_ms) VALUES($1,$2,$3)")
            .bind(album_id)
            .bind(format!("Demo Track {}", i + 1))
            .bind(180000)
            .execute(&s.pool)
            .await
            .unwrap();
    }
    Json(serde_json::json!({"inserted":n}))
}
