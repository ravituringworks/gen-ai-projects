use async_trait::async_trait;
use anyhow::Result;
use crate::agents::{Agent, AgentCommunicator, AgentMessage};
use crate::models::*;
use crate::database::Database;
use crate::services::stock_service::StockService;

pub struct DataAgent {
    database: Database,
    stock_service: StockService,
    communicator: AgentCommunicator,
}

impl DataAgent {
    pub fn new(database: Database, stock_service: StockService) -> Self {
        Self {
            database,
            stock_service,
            communicator: AgentCommunicator::new(),
        }
    }
    
    pub async fn fetch_all_stocks(&self) -> Result<Vec<Stock>> {
        log::info!("DataAgent: Fetching NASDAQ and OTC stocks");
        
        // Fetch from multiple sources
        let nasdaq_stocks = self.stock_service.fetch_nasdaq_stocks().await?;
        let otc_stocks = self.stock_service.fetch_otc_stocks().await?;
        
        let mut all_stocks = nasdaq_stocks;
        all_stocks.extend(otc_stocks);
        
        // Save to database
        for stock in &all_stocks {
            if let Err(e) = self.database.save_stock(stock).await {
                log::error!("Failed to save stock {}: {}", stock.symbol, e);
            }
        }
        
        log::info!("DataAgent: Processed {} stocks", all_stocks.len());
        
        // Notify other agents
        let message = AgentMessage::new(
            "data_agent".to_string(),
            "all_agents".to_string(),
            "stocks_updated".to_string(),
            serde_json::json!({
                "total_stocks": all_stocks.len(),
                "timestamp": chrono::Utc::now()
            }),
        );
        self.communicator.broadcast(message).await?;
        
        Ok(all_stocks)
    }
    
    pub async fn fetch_real_time_data(&self, symbols: &[String]) -> Result<Vec<StockData>> {
        log::info!("DataAgent: Fetching real-time data for {} symbols", symbols.len());
        
        let mut stock_data = Vec::new();
        
        for chunk in symbols.chunks(100) { // Process in batches
            match self.stock_service.fetch_batch_quotes(chunk).await {
                Ok(mut batch_data) => stock_data.append(&mut batch_data),
                Err(e) => log::error!("Failed to fetch batch data: {}", e),
            }
            
            // Rate limiting
            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
        }
        
        log::info!("DataAgent: Retrieved real-time data for {} stocks", stock_data.len());
        Ok(stock_data)
    }
}

#[async_trait]
impl Agent for DataAgent {
    async fn execute(&self) -> Result<Vec<AgentResult>> {
        let stocks = self.fetch_all_stocks().await?;
        
        // Create results indicating data freshness
        let results = stocks.into_iter().take(10).map(|stock| AgentResult {
            id: None,
            agent_type: self.get_agent_type(),
            stock_symbol: stock.symbol,
            horizon: "data_quality".to_string(),
            score: if stock.updated_at > chrono::Utc::now() - chrono::Duration::hours(1) { 1.0 } else { 0.5 },
            reasoning: "Fresh market data available".to_string(),
            created_at: chrono::Utc::now(),
        }).collect();
        
        Ok(results)
    }
    
    fn get_agent_type(&self) -> String {
        "data_agent".to_string()
    }
}
