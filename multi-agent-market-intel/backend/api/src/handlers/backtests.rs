use axum::{Json, extract::State};
use serde_json::json;
use uuid::Uuid;
use common::{BacktestRequest, BacktestReport};
use crate::state::AppState;

#[utoipa::path(post, path="/v1/backtests/run", request_body=BacktestRequest, responses((status=200, body=BacktestReport)))]
pub async fn post_run_backtest(State(st): State<AppState>, Json(req): Json<BacktestRequest>) -> Json<BacktestReport> {
    let url = std::env::var("BACKTEST_SVC_URL").unwrap_or_else(|_| "http://localhost:8081".into());
    let body = json!({ "strategy_id": req.strategy_id, "start": req.start.date_naive().to_string(), "end": req.end.date_naive().to_string(), "costs_bps": req.costs_bps });
    let resp = reqwest::Client::new().post(format!("{}/run", url)).json(&body).send().await.unwrap().json::<serde_json::Value>().await.unwrap();
    let report = BacktestReport{
        run_id: Uuid::parse_str(resp.get("run_id").unwrap().as_str().unwrap()).unwrap(),
        sharpe: resp.get("sharpe").unwrap().as_f64().unwrap(),
        max_dd: resp.get("max_dd").unwrap().as_f64().unwrap(),
        turnover: resp.get("turnover").unwrap().as_f64().unwrap(),
        summary: resp.clone(),
    };
    sqlx::query!(
      "INSERT INTO backtests(run_id, strategy_id, start_ts, end_ts, sharpe, max_dd, turnover, summary) VALUES($1,$2,$3,$4,$5,$6,$7,$8)",
      report.run_id, req.strategy_id, req.start, req.end, report.sharpe, report.max_dd, report.turnover, report.summary
    ).execute(&st.db).await.unwrap();
    Json(report)
}
