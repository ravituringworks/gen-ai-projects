use anyhow::Result;
use crate::agents::{AgentCommunicator, AgentMessage, data_agent::DataAgent, analysis_agent::AnalysisAgent};
use crate::database::Database;
use crate::services::{stock_service::StockService, screening_service::ScreeningService};
use crate::models::*;

pub struct CoordinatorAgent {
    database: Database,
    communicator: AgentCommunicator,
}

impl CoordinatorAgent {
    pub fn new(database: Database) -> Self {
        Self {
            database,
            communicator: AgentCommunicator::new(),
        }
    }
    
    pub async fn run_full_screening(&self) -> Result<ScreeningResult> {
        log::info!("CoordinatorAgent: Starting full market screening");
        
        let start_time = chrono::Utc::now();
        
        // Initialize services
        let stock_service = StockService::new();
        let screening_service = ScreeningService::new();
        
        // Step 1: Data acquisition
        log::info!("CoordinatorAgent: Initiating data acquisition");
        let data_agent = DataAgent::new(self.database.clone(), stock_service);
        let stocks = data_agent.fetch_all_stocks().await?;
        
        // Step 2: Multi-horizon analysis
        let horizons = vec!["1day".to_string(), "1week".to_string(), "1month".to_string()];
        let mut all_results = Vec::new();
        
        for horizon in &horizons {
            log::info!("CoordinatorAgent: Running {} analysis", horizon);
            
            let analysis_agent = AnalysisAgent::new(
                self.database.clone(),
                screening_service.clone(),
                horizon.clone()
            );
            
            let results = analysis_agent.analyze_stocks().await?;
            all_results.extend(results);
        }
        
        // Step 3: Generate top 100 lists for each horizon
        let mut screening_results = Vec::new();
        
        for horizon in &horizons {
            let top_stocks = self.database.get_top_stocks(horizon, 100).await?;
            
            screening_results.push(ScreeningResult {
                horizon: horizon.clone(),
                top_stocks,
                total_analyzed: stocks.len() as i32,
                screening_time: start_time,
            });
        }
        
        log::info!("CoordinatorAgent: Screening completed. Processed {} stocks, generated {} results", 
                  stocks.len(), all_results.len());
        
        // Broadcast completion
        let message = AgentMessage::new(
            "coordinator_agent".to_string(),
            "all_agents".to_string(),
            "screening_complete".to_string(),
            serde_json::json!({
                "total_stocks": stocks.len(),
                "total_results": all_results.len(),
                "horizons": horizons,
                "completion_time": chrono::Utc::now()
            }),
        );
        self.communicator.broadcast(message).await?;
        
        // Return primary result (1day for immediate display)
        Ok(screening_results.into_iter()
           .find(|r| r.horizon == "1day")
           .unwrap_or_else(|| ScreeningResult {
               horizon: "1day".to_string(),
               top_stocks: Vec::new(),
               total_analyzed: 0,
               screening_time: start_time,
           }))
    }
    
    pub async fn get_screening_status(&self) -> Result<Vec<AgentStatus>> {
        self.database.get_agent_status().await
    }
    
    pub async fn coordinate_agents(&self) -> Result<()> {
        log::info!("CoordinatorAgent: Coordinating agent communications");
        
        // In a full implementation, this would manage A2A protocols
        // For MVP, we simulate coordination through database state
        
        let agent_statuses = self.get_screening_status().await?;
        
        for status in agent_statuses {
            if status.total_results == 0 {
                log::warn!("Agent {} has no recent results", status.agent_type);
            }
        }
        
        Ok(())
    }
}
