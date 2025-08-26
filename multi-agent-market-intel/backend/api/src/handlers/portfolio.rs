use axum::{Json, extract::State};
use chrono::Utc;
use common::PortfolioInstruction;
use serde_json::json;
use crate::state::AppState;

#[utoipa::path(post, path="/v1/portfolio/publish", request_body=PortfolioInstruction, responses((status=200, body=PortfolioInstruction)))]
pub async fn post_publish_portfolio(State(_st): State<AppState>, Json(mut p): Json<PortfolioInstruction>) -> Json<PortfolioInstruction> {
    let url = std::env::var("PORTFOLIO_SVC_URL").unwrap_or_else(|_| "http://localhost:8082".into());
    let universe: Vec<String> = p.target_weights.as_object().unwrap().keys().cloned().collect();
    let exp_ret: Vec<f64> = universe.iter().map(|_| 0.001).collect();
    let body = json!({
        "asof": p.asof.to_rfc3339(),
        "book": p.book,
        "universe": universe,
        "expected_returns": exp_ret,
        "returns_window_days": 252,
        "gross_max": 1.0,
        "per_name_max": 0.05,
        "per_name_min": -0.05
    });
    let resp = reqwest::Client::new().post(format!("{}/optimize", url)).json(&body).send().await.unwrap().json::<serde_json::Value>().await.unwrap();
    // Map optimized weights back to object
    let mut map = serde_json::Map::new();
    for e in resp.get("weights").unwrap().as_array().unwrap().iter() {
        let arr = e.as_array().unwrap();
        map.insert(arr[0].as_str().unwrap().to_string(), serde_json::json!(arr[1].as_f64().unwrap()));
    }
    p.target_weights = serde_json::Value::Object(map);
    p.asof = Utc::now();
    Json(p)
}
