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


use nalgebra::{DMatrix, DVector};
use std::collections::HashMap;

pub fn project_l1_ball(v: &DVector<f64>, z: f64) -> DVector<f64> {
  // Projection onto L1 ball of radius z (Duchi et al. 2008)
  let n = v.len();
  let mut u: Vec<f64> = v.iter().map(|x| x.abs()).collect();
  let mut idx: Vec<usize> = (0..n).collect();
  idx.sort_by(|&i,&j| u[j].partial_cmp(&u[i]).unwrap());
  let mut cssv = 0.0;
  let mut rho = 0usize;
  for (r, &i) in idx.iter().enumerate() {
    cssv += u[i];
    let t = (cssv - z) / ((r+1) as f64);
    if u[i] > t { rho = r+1; }
  }
  let theta = ( (0..rho).map(|r| u[idx[r]]).sum::<f64>() - z ) / (rho as f64);
  let mut w = v.clone();
  for i in 0..n {
    let s = v[i].signum();
    w[i] = s * (v[i].abs() - theta).max(0.0);
  }
  w
}

pub fn project_sector_caps(w: &mut DVector<f64>, sectors: &HashMap<String, Vec<usize>>, caps: &Vec<(String, f64)>) {
  // Simple clipping by proportional rescale within capped sector
  for (sec, cap) in caps {
    if let Some(ix) = sectors.get(sec) {
      let sum: f64 = ix.iter().map(|&j| w[j].max(0.0)).sum();
      if sum > *cap {
        let scale = if sum.abs()>1e-12 { cap / sum } else { 1.0 };
        for &j in ix { if w[j] > 0.0 { w[j] *= scale; } }
      }
    }
  }
}

pub fn enforce_beta(w: &mut DVector<f64>, betas: &DVector<f64>, beta_target: f64, beta_tol: f64) {
  let b = betas.dot(w);
  let low = beta_target - beta_tol; let high = beta_target + beta_tol;
  if b < low || b > high {
    let adj = (beta_target - b) / (betas.norm_squared() + 1e-9);
    *w += betas * adj;
  }
}

pub fn solve_with_constraints(mu: &DVector<f64>,
                              cov: &DMatrix<f64>,
                              cfg: &MVConfig,
                              w_prev: &DVector<f64>,
                              sectors: &HashMap<String, Vec<usize>>,
                              sector_caps: &Vec<(String, f64)>,
                              betas: &DVector<f64>, beta_target: f64, beta_tol: f64,
                              turnover_limit: Option<f64>) -> DVector<f64> {
  let n = mu.len();
  // Start at previous or equal-weight
  let mut w = if w_prev.amax() != 0.0 { w_prev.clone() } else { DVector::from_element(n, 1.0/(n as f64)) };
  // Gradient descent with projections
  let lambda = 1.0;    // risk-aversion scaler for -mu term
  let eta = 0.1;       // step size
  for _iter in 0..500 {
    // grad = Σ w - λ μ
    let grad = cov * &w - (mu * lambda);
    let mut w_new = &w - grad * eta;

    // Box constraints per name
    for i in 0..n { w_new[i] = w_new[i].clamp(cfg.per_name_min, cfg.per_name_max); }

    // Gross exposure constraint via L1 projection
    let gross = w_new.iter().map(|x| x.abs()).sum::<f64>();
    if gross > cfg.gross_max {
      // Project onto L1 ball of radius gross_max while preserving signs
      let sign: Vec<f64> = (0..n).map(|i| w_new[i].signum()).collect();
      let v = DVector::from_vec((0..n).map(|i| w_new[i].abs()).collect());
      let p = project_l1_ball(&v, cfg.gross_max);
      for i in 0..n { w_new[i] = sign[i] * p[i]; }
    }

    // Sector caps
    project_sector_caps(&mut w_new, sectors, sector_caps);

    // Beta rail
    let mut w_beta = w_new.clone();
    enforce_beta(&mut w_beta, betas, beta_target, beta_tol);
    w_new = w_beta;

    // Turnover constraint: ||w_new - w_prev||_1 <= tau
    if let Some(tau) = turnover_limit {
      let d = &w_new - w_prev;
      let p = project_l1_ball(&d, tau);
      w_new = w_prev + p;
    }

    // Convergence check
    if (&w_new - &w).amax() < 1e-6 { w = w_new; break; }
    w = w_new;
  }
  w
}
