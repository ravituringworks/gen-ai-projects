use nalgebra::{DMatrix, DVector};

pub struct MVConfig { pub gross_max: f64, pub per_name_max: f64, pub per_name_min: f64 }

pub fn ledoit_wolf_cov(returns: &DMatrix<f64>) -> DMatrix<f64> {
  let t = returns.nrows() as f64; let n = returns.ncols();
  let mean = returns.column_mean();
  let x = returns - DMatrix::from_columns(&vec![mean; returns.nrows()]);
  let sample = (&x.transpose() * &x) / t;
  let mu = sample.trace() / (n as f64);
  let f = DMatrix::from_diagonal(&DVector::from_element(n, mu));
  let beta = 0.5;
  (&sample * (1.0 - beta)) + (f * beta)
}

pub fn mv_optimize(mu: &DVector<f64>, cov: &DMatrix<f64>, cfg: &MVConfig) -> DVector<f64> {
  let inv = cov.clone().try_inverse().unwrap_or_else(|| cov.clone());
  let mut w = &inv * mu;
  let s: f64 = w.iter().sum(); if s.abs() > 1e-9 { w /= s; }
  for wi in w.iter_mut(){ *wi = wi.clamp(cfg.per_name_min, cfg.per_name_max); }
  let gross: f64 = w.iter().map(|x| x.abs()).sum(); if gross > cfg.gross_max { w *= cfg.gross_max / gross; }
  w
}
