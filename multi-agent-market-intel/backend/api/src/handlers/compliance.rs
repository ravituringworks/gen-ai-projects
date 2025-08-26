use axum::{Json, extract::State};
use common::{ComplianceRequest, ComplianceResult};
use crate::state::AppState;

#[utoipa::path(post, path="/v1/compliance/pretrade-check", request_body=ComplianceRequest, responses((status=200, body=ComplianceResult)))]
pub async fn post_pretrade_check(State(_): State<AppState>, Json(_req): Json<ComplianceRequest>) -> Json<ComplianceResult> {
    let violations = vec![]; // demo: always pass
    Json(ComplianceResult{ ok: violations.is_empty(), violations })
}
