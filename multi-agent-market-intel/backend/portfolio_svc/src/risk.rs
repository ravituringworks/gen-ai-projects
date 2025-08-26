use nalgebra::{DMatrix, DVector};

pub fn factor_exposure(w: &DVector<f64>, loadings: &DMatrix<f64>) -> DVector<f64> { loadings.transpose() * w }

pub fn var_gaussian(w: &DVector<f64>, cov: &DMatrix<f64>, z: f64) -> f64 {
  let var = (w.transpose() * cov * w)[(0,0)];
  -z * var.sqrt()
}
