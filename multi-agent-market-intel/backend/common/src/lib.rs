use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ApiHealth { pub status: String, pub ts: DateTime<Utc> }

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FeatureRow {
    pub asof: DateTime<Utc>,
    pub symbol: String,
    pub feature_namespace: String,
    pub features: serde_json::Value,
    pub label: Option<f64>,
    pub window: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct Signal {
    pub asof: DateTime<Utc>,
    pub symbol: String,
    pub signal_id: Uuid,
    pub model_version: String,
    pub horizon: String, // e.g., "1d"
    pub score: f64,
    pub confidence: f64,
    pub explain: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct BacktestRequest {
    pub strategy_id: String,
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
    pub costs_bps: Option<f64>,
    pub constraints: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct BacktestReport {
    pub run_id: Uuid,
    pub sharpe: f64,
    pub max_dd: f64,
    pub turnover: f64,
    pub summary: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PortfolioInstruction {
    pub asof: DateTime<Utc>,
    pub book: String,
    pub target_weights: serde_json::Value,
    pub constraints: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ComplianceRequest {
    pub book: String,
    pub targets: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ComplianceResult {
    pub ok: bool,
    pub violations: Vec<String>,
}
