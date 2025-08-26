use axum::{Json, extract::State};
use serde::Deserialize;
use nalgebra::{DMatrix, DVector};
use crate::{optimizer::{ledoit_wolf_cov, mv_optimize, MVConfig}, risk::{factor_exposure, var_gaussian}};
use crate::state::AppState;

#[derive(Deserialize)]
pub struct OptReq {
  pub asof: String,
  pub book: String,
  pub universe: Vec<String>,
  pub expected_returns: Vec<f64>,
  pub returns_window_days: i64,
  pub gross_max: f64,
  pub per_name_max: f64,
  pub per_name_min: f64,
  pub sectors: Vec<String>,            // parallel to universe
  pub sector_caps: Option<Vec<(String, f64)>>, // (sector, max_weight)
  pub betas: Option<Vec<f64>>,         // CAPM beta per symbol
  pub beta_target: Option<f64>,
  pub beta_tolerance: Option<f64>,
  pub turnover_limit: Option<f64>,     // L1 constraint on changes vs prev
  pub prev_weights: Option<Vec<f64>>,  // optional previous weights parallel to universe
}

#[derive(serde::Serialize)]
pub struct OptResp { pub weights: Vec<(String, f64)>, pub var95: f64, pub exposures: Vec<f64> }

pub async fn optimize(State(st): State<AppState>, Json(req): Json<OptReq>) -> Json<OptResp> {
  let n = req.universe.len();
  let rows = sqlx::query!(
    r#"SELECT symbol, ts::date AS d, close FROM ohlcv WHERE symbol = ANY($1) AND ts >= (DATE $2 - ($3||' days')::interval) ORDER BY d ASC"#,
    &req.universe, &req.asof, req.returns_window_days
  ).fetch_all(&st.db).await.unwrap();

  use std::collections::BTreeMap; let mut by_sym: BTreeMap<String, Vec<(chrono::NaiveDate, f64)>> = BTreeMap::new();
  for r in rows { by_sym.entry(r.symbol).or_default().push((r.d.unwrap(), r.close)); }

  let dates: Vec<_> = by_sym.values().next().unwrap_or(&vec![]).iter().map(|(d,_)| *d).collect();
  let t = dates.len().saturating_sub(1);
  let mut mat = DMatrix::zeros(t, n);
  for (j, sym) in req.universe.iter().enumerate(){
    let v = &by_sym.get(sym).unwrap();
    for i in 1..v.len(){ let r = (v[i].1 / v[i-1].1).ln(); mat[(i-1, j)] = r; }
  }

  let cov = ledoit_wolf_cov(&mat);
  let mu = DVector::from_vec(req.expected_returns.clone());
  let w = mv_optimize(&mu, &cov, &MVConfig{ gross_max: req.gross_max, per_name_max: req.per_name_max, per_name_min: req.per_name_min });
  let loadings = DMatrix::identity(n, n);
  let exp = factor_exposure(&w, &loadings);
  let var95 = var_gaussian(&w, &cov, 1.65);

  Json(OptResp{ weights: req.universe.into_iter().zip(w.iter().cloned()).collect(), var95, exposures: exp.iter().cloned().collect() })
}
