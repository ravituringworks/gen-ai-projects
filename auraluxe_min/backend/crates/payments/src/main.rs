use axum::{extract::{Query, State}, routing::{get, post}, Json, Router};
use common::{app_state, AppState};
use serde::Deserialize;
use sqlx::Row;
use std::net::SocketAddr;
use tracing_subscriber::EnvFilter;
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt().with_env_filter(EnvFilter::from_default_env()).init();
    let s = app_state().await?;
    let app = Router::new().route("/health", get(|| async { "ok" })).route("/v1/plans", get(plans)).route("/v1/subscribe", post(subscribe)).route("/v1/entitlements", get(ents)).with_state(s);
    let addr: SocketAddr = "127.0.0.1:4003".parse()?;
    axum::Server::bind(&addr).serve(app.into_make_service()).await?;
    Ok(())
}
async fn plans(State(s): State<AppState>) -> Json<serde_json::Value> {
    let c: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM plans").fetch_one(&s.pool).await.unwrap_or(0);
    if c == 0 { sqlx::query("INSERT INTO plans(name,price_cents,currency,period,features_json) VALUES ('Free',0,'USD','month','{}'),('Premium',999,'USD','month','{""offline"":true}'),('HiFi',1499,'USD','month','{""hifi"":true}')").execute(&s.pool).await.ok(); }
    let rows = sqlx::query("SELECT id,name,price_cents,currency,period,features_json FROM plans ORDER BY price_cents").fetch_all(&s.pool).await.unwrap();
    let items: Vec<_> = rows.iter().map(|r| serde_json::json!({"id":r.get::<uuid::Uuid,_>("id").to_string(),"name":r.get::<String,_>("name"),"price_cents":r.get::<i32,_>("price_cents"),"currency":r.get::<String,_>("currency"),"period":r.get::<String,_>("period"),"features":r.get::<serde_json::Value,_>("features_json")})).collect();
    Json(serde_json::json!({"plans":items}))
}
#[derive(Deserialize)]
struct Sub {
    user_email: String,
    plan_id: String,
}
async fn subscribe(State(s): State<AppState>, Json(b): Json<Sub>) -> Json<serde_json::Value> {
    let uid: uuid::Uuid = sqlx::query_scalar("INSERT INTO users(email,region) VALUES($1,'US') ON CONFLICT(email) DO UPDATE SET region=EXCLUDED.region RETURNING id").bind(&b.user_email).fetch_one(&s.pool).await.unwrap();
    sqlx::query("INSERT INTO subscriptions(user_id,plan_id,status) VALUES($1,$2,'active')").bind(uid).bind(&b.plan_id).execute(&s.pool).await.ok();
    sqlx::query("INSERT INTO entitlements(user_id,feature,expires_at) VALUES($1,'premium',now()+interval '30 days')").bind(uid).execute(&s.pool).await.ok();
    Json(serde_json::json!({"status":"active","user_id":uid.to_string()}))
}
#[derive(Deserialize)]
struct EntQ {
    user_email: String,
}
async fn ents(State(s): State<AppState>, Query(q): Query<EntQ>) -> Json<serde_json::Value> {
    let uid: Option<uuid::Uuid> = sqlx::query_scalar("SELECT id FROM users WHERE email=$1").bind(&q.user_email).fetch_optional(&s.pool).await.unwrap();
    if let Some(u) = uid {
        let rows = sqlx::query("SELECT feature,expires_at FROM entitlements WHERE user_id=$1").bind(u).fetch_all(&s.pool).await.unwrap_or_default();
        let items: Vec<_> = rows.iter().map(|r| serde_json::json!({"feature":r.get::<String,_>("feature"),"expires_at":r.get::<Option<chrono::DateTime<chrono::Utc>>,_>("expires_at")})).collect();
        Json(serde_json::json!({"user_id":u.to_string(),"entitlements":items}))
    } else { Json(serde_json::json!({"user_id":null,"entitlements":[]})) }
}
