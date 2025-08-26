use axum::{Json, extract::State};
use chrono::{NaiveDate, Utc};
use serde::Deserialize;
use uuid::Uuid;
use crate::{state::AppState, model::{Bar, DailyTarget}, sim::{simulate, EngineCfg}};

#[derive(Deserialize)]
struct RunReq { strategy_id: String, start: String, end: String, costs_bps: Option<f64> }

#[derive(serde::Serialize)]
struct RunResp { run_id: Uuid, sharpe: f64, max_dd: f64, turnover: f64, equity_curve: Vec<(String, f64)> }

#[utoipa::path(post, path="/run", request_body=RunReq, responses((status=200, body=RunResp)))]
pub async fn run_backtest(State(st): State<AppState>, Json(req): Json<RunReq>) -> Json<RunResp> {
    let (start, end) = (
        chrono::DateTime::from_naive_utc_and_offset(NaiveDate::parse_from_str(&req.start, "%Y-%m-%d").unwrap().and_hms_opt(0,0,0).unwrap(), chrono::Utc),
        chrono::DateTime::from_naive_utc_and_offset(NaiveDate::parse_from_str(&req.end, "%Y-%m-%d").unwrap().and_hms_opt(0,0,0).unwrap(), chrono::Utc)
    );

    let rows = sqlx::query!(
        r#"SELECT asof, symbol, score FROM signals WHERE asof BETWEEN $1 AND $2 ORDER BY asof DESC"#,
        start, end
    ).fetch_all(&st.db).await.unwrap();

    use std::collections::HashMap; let mut by_day: HashMap<String, Vec<(String,f64)>> = HashMap::new();
    for r in rows { let d = r.asof.date_naive().to_string(); by_day.entry(d).or_default().push((r.symbol, r.score)); }

    let mut targets = Vec::new();
    for (d, mut vec) in by_day { vec.sort_by(|a,b| b.1.partial_cmp(&a.1).unwrap()); let top = vec.into_iter().take(5).collect::<Vec<_>>();
        let w = 1.0/(top.len().max(1) as f64); let weights = top.into_iter().map(|(s,_)| (s, w)).collect::<Vec<_>>();
        let ts = chrono::DateTime::from_naive_utc_and_offset(chrono::NaiveDate::parse_from_str(&d, "%Y-%m-%d").unwrap().and_hms_opt(0,0,0).unwrap(), chrono::Utc);
        targets.push(DailyTarget{ ts, weights });
    }
    targets.sort_by_key(|t| t.ts);

    // Load bars; fallback to synthetic
    let mut bars: HashMap<String, Vec<Bar>> = HashMap::new();
    for t in &targets { for (sym, _) in &t.weights { bars.entry(sym.clone()).or_default(); } }
    for (sym, vecb) in bars.iter_mut(){
      let recs = sqlx::query(
          r#"SELECT ts, open, high, low, close, volume FROM ohlcv WHERE symbol=$1 AND ts BETWEEN $2 AND $3 ORDER BY ts ASC"#
        ).bind(&sym).bind(start).bind(end).fetch_all(&st.db).await.unwrap();
      if recs.is_empty() {
        let mut px = 100.0; let mut ts = start; while ts <= end { px *= (1.0 + (rand::random::<f64>()-0.5)*0.02); vecb.push(Bar{ ts, open:px, high:px*1.01, low:px*0.99, close:px, volume:1_000_000.0 }); ts += chrono::Duration::days(1); }
      } else {
        use sqlx::Row;
        for r in recs { vecb.push(Bar{ ts: r.get("ts"), open: r.get("open"), high: r.get("high"), low: r.get("low"), close: r.get("close"), volume: r.get("volume") }); }
      }
    }

    let rep = simulate(1_000_000.0, &targets, &bars, &EngineCfg{ rebalance_days: 1, tc_bps: req.costs_bps.unwrap_or(5.0), borrow_bps: 0.0 });
    Json(RunResp{ run_id: rep.run_id, sharpe: rep.sharpe, max_dd: rep.max_dd, turnover: rep.turnover, equity_curve: rep.equity_curve.into_iter().map(|p| (p.ts.date_naive().to_string(), p.nav)).collect() })
}
