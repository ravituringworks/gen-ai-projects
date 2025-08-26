use axum::{Json, extract::{State, Query}};
use serde::Deserialize;
use chrono::Utc;
use uuid::Uuid;
use common::Signal;
use crate::state::AppState;
use sqlx::FromRow;

#[derive(Deserialize)]
pub struct SignalQuery { pub symbol: Option<String>, pub horizon: Option<String>, pub limit: Option<i64> }

#[derive(FromRow)]
struct DbSignal { id: Uuid, asof: chrono::DateTime<Utc>, symbol: String, model_version: String, horizon: String, score: f64, confidence: f64, explain: serde_json::Value }

#[utoipa::path(get, path="/v1/signals", params(("symbol" = Option<String>, Query),("horizon" = Option<String>, Query),("limit" = Option<i64>, Query)), responses((status=200, body=[Signal])))]
pub async fn get_signals(State(st): State<AppState>, Query(q): Query<SignalQuery>) -> Json<Vec<Signal>> {
    let limit = q.limit.unwrap_or(20).min(200);
    let rows: Vec<DbSignal> = if let Some(sym) = &q.symbol {
        if let Some(h) = &q.horizon {
            sqlx::query_as::<_, DbSignal>(
                "SELECT id, asof, symbol, model_version, horizon, score, confidence, explain FROM signals WHERE symbol = $1 AND horizon = $2 ORDER BY asof DESC LIMIT $3"
            ).bind(sym).bind(h).bind(limit).fetch_all(&st.db).await.unwrap()
        } else {
            sqlx::query_as::<_, DbSignal>(
                "SELECT id, asof, symbol, model_version, horizon, score, confidence, explain FROM signals WHERE symbol = $1 ORDER BY asof DESC LIMIT $2"
            ).bind(sym).bind(limit).fetch_all(&st.db).await.unwrap()
        }
    } else {
        sqlx::query_as::<_, DbSignal>(
            "SELECT id, asof, symbol, model_version, horizon, score, confidence, explain FROM signals ORDER BY asof DESC LIMIT $1"
        ).bind(limit).fetch_all(&st.db).await.unwrap()
    };

    let out = rows.into_iter().map(|r| Signal { asof: r.asof, symbol: r.symbol, signal_id: r.id, model_version: r.model_version, horizon: r.horizon, score: r.score, confidence: r.confidence, explain: r.explain }).collect();
    Json(out)
}
