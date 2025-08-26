use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stock {
    pub id: Uuid,
    pub symbol: String,
    pub name: String,
    pub exchange: String,
    pub market_cap: Option<f64>,
    pub price: Option<f64>,
    pub volume: Option<i64>,
    pub sector: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentResult {
    pub id: Option<Uuid>,
    pub agent_type: String,
    pub stock_symbol: String,
    pub horizon: String, // "1day", "1week", "1month"
    pub score: f64,
    pub reasoning: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TopStock {
    pub symbol: String,
    pub name: String,
    pub exchange: String,
    pub price: Option<f64>,
    pub market_cap: Option<f64>,
    pub score: f64,
    pub reasoning: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentStatus {
    pub agent_type: String,
    pub status: String,
    pub last_run: Option<DateTime<Utc>>,
    pub total_results: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StockData {
    pub symbol: String,
    pub price: f64,
    pub volume: i64,
    pub market_cap: Option<f64>,
    pub pe_ratio: Option<f64>,
    pub change_percent: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreeningResult {
    pub horizon: String,
    pub top_stocks: Vec<TopStock>,
    pub total_analyzed: i32,
    pub screening_time: DateTime<Utc>,
}
