use chrono::{DateTime, Utc};
use serde::{Serialize, Deserialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bar { pub ts: DateTime<Utc>, pub open: f64, pub high: f64, pub low: f64, pub close: f64, pub volume: f64 }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyTarget { pub ts: DateTime<Utc>, pub weights: Vec<(String, f64)> }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EquityPoint { pub ts: DateTime<Utc>, pub nav: f64 }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Report { pub run_id: Uuid, pub sharpe: f64, pub max_dd: f64, pub turnover: f64, pub equity_curve: Vec<EquityPoint> }
