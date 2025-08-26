use axum::{Json, extract::State};
use serde_json::json;
use chrono::Utc;
use common::FeatureRow;
use crate::state::AppState;

#[utoipa::path(post, path="/v1/features/compute", request_body=FeatureRow, responses((status=200, body=FeatureRow)))]
pub async fn post_compute_features(State(_): State<AppState>, Json(mut row): Json<FeatureRow>) -> Json<FeatureRow> {
    let mut features = row.features.clone();
    let demo = json!({ "demo_mom_20": 0.23, "demo_vol_10": 1.12 });
    if let Some(obj) = features.as_object_mut() { obj.extend(demo.as_object().unwrap().clone()); }
    row.features = features; row.asof = Utc::now();
    Json(row)
}
