use async_trait::async_trait;
use anyhow::Result;
use crate::agents::{Agent, AgentCommunicator, AgentMessage};
use crate::models::*;
use crate::database::Database;
use crate::services::screening_service::ScreeningService;

pub struct AnalysisAgent {
    database: Database,
    screening_service: ScreeningService,
    communicator: AgentCommunicator,
    horizon: String,
}

impl AnalysisAgent {
    pub fn new(database: Database, screening_service: ScreeningService, horizon: String) -> Self {
        let _agent_id = format!("analysis_agent_{}", horizon);
        Self {
            database,
            screening_service,
            horizon,
            communicator: AgentCommunicator::new(),
        }
    }
    
    pub async fn analyze_stocks(&self) -> Result<Vec<AgentResult>> {
        log::info!("AnalysisAgent({}): Starting stock analysis", self.horizon);
        
        let stocks = self.database.get_all_stocks().await?;
        let mut results = Vec::new();
        
        for stock in stocks {
            if let Ok(score) = self.calculate_stock_score(&stock).await {
                let reasoning = self.generate_reasoning(&stock, score);
                
                results.push(AgentResult {
                    id: None,
                    agent_type: self.get_agent_type(),
                    stock_symbol: stock.symbol.clone(),
                    horizon: self.horizon.clone(),
                    score,
                    reasoning,
                    created_at: chrono::Utc::now(),
                });
            }
        }
        
        // Save results to database
        for result in &results {
            if let Err(e) = self.database.save_agent_result(result).await {
                log::error!("Failed to save analysis result: {}", e);
            }
        }
        
        log::info!("AnalysisAgent({}): Analyzed {} stocks", self.horizon, results.len());
        
        // Communicate with coordinator
        let message = AgentMessage::new(
            self.get_agent_type(),
            "coordinator_agent".to_string(),
            "analysis_complete".to_string(),
            serde_json::json!({
                "horizon": self.horizon,
                "analyzed_count": results.len(),
                "avg_score": if results.is_empty() { 0.0 } else { results.iter().map(|r| r.score).sum::<f64>() / results.len() as f64 }
            }),
        );
        self.communicator.send_message(message).await?;
        
        Ok(results)
    }
    
    async fn calculate_stock_score(&self, stock: &Stock) -> Result<f64> {
        let mut score = 0.0;
        
        // Market cap factor
        if let Some(market_cap) = stock.market_cap {
            score += match self.horizon.as_str() {
                "1day" => self.screening_service.calculate_momentum_score(market_cap, stock.volume),
                "1week" => self.screening_service.calculate_growth_score(market_cap),
                "1month" => self.screening_service.calculate_value_score(market_cap, stock.price),
                _ => 0.0,
            };
        }
        
        // Volume factor
        if let Some(volume) = stock.volume {
            score += self.screening_service.calculate_volume_score(volume as f64);
        }
        
        // Exchange premium
        score += match stock.exchange.as_str() {
            "NASDAQ" => 0.1,
            "NYSE" => 0.08,
            _ => 0.05, // OTC
        };
        
        // Sector boost for growth sectors
        if let Some(sector) = &stock.sector {
            score += match sector.as_str() {
                "Technology" => 0.15,
                "Healthcare" => 0.12,
                "Consumer Discretionary" => 0.10,
                _ => 0.0,
            };
        }
        
        // Normalize score to 0-1 range
        Ok(score.min(1.0).max(0.0))
    }
    
    fn generate_reasoning(&self, stock: &Stock, score: f64) -> String {
        let mut reasons = Vec::new();
        
        if score > 0.8 {
            reasons.push("Strong technical indicators".to_string());
        }
        
        if let Some(market_cap) = stock.market_cap {
            if market_cap > 1_000_000_000.0 {
                reasons.push("Large cap stability".to_string());
            } else if market_cap < 300_000_000.0 {
                reasons.push("Small cap growth potential".to_string());
            }
        }
        
        if stock.exchange == "NASDAQ" {
            reasons.push("Listed on premier exchange".to_string());
        }
        
        if let Some(sector) = &stock.sector {
            if sector == "Technology" {
                reasons.push("High-growth technology sector".to_string());
            }
        }
        
        if reasons.is_empty() {
            "Standard market performance indicators".to_string()
        } else {
            reasons.join("; ")
        }
    }
}

#[async_trait]
impl Agent for AnalysisAgent {
    async fn execute(&self) -> Result<Vec<AgentResult>> {
        self.analyze_stocks().await
    }
    
    fn get_agent_type(&self) -> String {
        format!("analysis_agent_{}", self.horizon)
    }
}
