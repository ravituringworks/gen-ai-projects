use axum::{Json, extract::State};
use chrono::Utc;
use common::ApiHealth;
use crate::state::AppState;

#[utoipa::path(get, path="/health", responses((status=200, description="OK", body=ApiHealth)))]
pub async fn get_health(State(_): State<AppState>) -> Json<ApiHealth> {
    Json(ApiHealth { status: "ok".into(), ts: Utc::now() })
}
