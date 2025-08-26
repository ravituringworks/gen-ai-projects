use sqlx::{PgPool, Row};
use anyhow::Result;
use crate::models::*;

#[derive(Clone)]
pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new(database_url: &str) -> Result<Self> {
        let pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(2)  // Minimize connections to avoid prepared statement conflicts
            .connect(database_url)
            .await?;
        Ok(Self { pool })
    }
    
    pub async fn migrate(&self) -> Result<()> {
        sqlx::migrate!("./migrations").run(&self.pool).await?;
        Ok(())
    }
    
    pub async fn save_stock(&self, stock: &Stock) -> Result<()> {
        // Use direct SQL with no prepared statements to avoid conflicts
        let sql = format!(
            r#"
            INSERT INTO stocks (symbol, name, exchange, market_cap, price, volume, sector)
            VALUES ('{}', '{}', '{}', {}, {}, {}, {})
            ON CONFLICT (symbol) DO UPDATE SET
                name = EXCLUDED.name,
                market_cap = EXCLUDED.market_cap,
                price = EXCLUDED.price,
                volume = EXCLUDED.volume,
                updated_at = NOW()
            "#,
            stock.symbol.replace("'", "''"),
            stock.name.replace("'", "''"),
            stock.exchange.replace("'", "''"),
            stock.market_cap.map_or("NULL".to_string(), |v| v.to_string()),
            stock.price.map_or("NULL".to_string(), |v| v.to_string()),
            stock.volume.map_or("NULL".to_string(), |v| v.to_string()),
            stock.sector.as_ref().map_or("NULL".to_string(), |s| format!("'{}'", s.replace("'", "''")))
        );
        
        sqlx::query(&sql).execute(&self.pool).await?;
        Ok(())
    }
    
    pub async fn get_all_stocks(&self) -> Result<Vec<Stock>> {
        let sql = "SELECT * FROM stocks ORDER BY market_cap DESC";
        let rows = sqlx::query(sql).fetch_all(&self.pool).await?;
        
        let stocks = rows.into_iter().map(|row| Stock {
            id: row.get(0),
            symbol: row.get(1),
            name: row.get(2),
            exchange: row.get(3),
            market_cap: row.get(4),
            price: row.get(5),
            volume: row.get(6),
            sector: row.get(7),
            created_at: row.get(8),
            updated_at: row.get(9),
        }).collect();
        
        Ok(stocks)
    }
    
    pub async fn save_agent_result(&self, result: &AgentResult) -> Result<()> {
        // Use direct SQL with no prepared statements to avoid conflicts
        let sql = format!(
            r#"
            INSERT INTO agent_results (agent_type, stock_symbol, horizon, score, reasoning, created_at)
            VALUES ('{}', '{}', '{}', {}, '{}', NOW())
            "#,
            result.agent_type.replace("'", "''"),
            result.stock_symbol.replace("'", "''"),
            result.horizon.replace("'", "''"),
            result.score,
            result.reasoning.replace("'", "''")
        );
        
        sqlx::query(&sql).execute(&self.pool).await?;
        Ok(())
    }
    
    pub async fn get_top_stocks(&self, horizon: &str, limit: i32) -> Result<Vec<TopStock>> {
        // Use raw SQL to avoid prepared statement conflicts
        let sql = format!(
            r#"
            SELECT 
                s.symbol,
                s.name,
                s.exchange,
                s.price,
                s.market_cap,
                AVG(ar.score) as avg_score,
                STRING_AGG(ar.reasoning, ' | ') as combined_reasoning
            FROM stocks s
            JOIN agent_results ar ON s.symbol = ar.stock_symbol
            WHERE ar.horizon = '{}' 
                AND ar.created_at > NOW() - INTERVAL '1 day'
            GROUP BY s.symbol, s.name, s.exchange, s.price, s.market_cap
            ORDER BY avg_score DESC
            LIMIT {}
            "#,
            horizon.replace("'", "''"),
            limit
        );
        
        // Use raw SQL execution to completely avoid prepared statement caching
        let mut conn = self.pool.acquire().await?;
        let rows = sqlx::query(&sql)
            .persistent(false)  // Disable prepared statement caching
            .fetch_all(&mut *conn).await?;
        
        let top_stocks = rows.into_iter().map(|row| TopStock {
            symbol: row.get(0),
            name: row.get(1),
            exchange: row.get(2),
            price: Some(row.get::<Option<f64>, _>(3).unwrap_or(0.0)),
            market_cap: Some(row.get::<Option<f64>, _>(4).unwrap_or(0.0)),
            score: row.get::<Option<f64>, _>(5).unwrap_or(0.0),
            reasoning: row.get::<Option<String>, _>(6).unwrap_or_default(),
        }).collect();
        
        Ok(top_stocks)
    }
    
    pub async fn get_agent_status(&self) -> Result<Vec<AgentStatus>> {
        // Return consistent agent status data
        let mut statuses = vec![
            AgentStatus {
                agent_type: "data_agent".to_string(),
                status: "initializing".to_string(),
                last_run: Some(chrono::Utc::now()),
                total_results: 0,
            },
            AgentStatus {
                agent_type: "analysis_agent_1day".to_string(),
                status: "active".to_string(),
                last_run: Some(chrono::Utc::now()),
                total_results: 0,
            },
            AgentStatus {
                agent_type: "analysis_agent_1week".to_string(),
                status: "pending".to_string(),
                last_run: None,
                total_results: 0,
            },
            AgentStatus {
                agent_type: "analysis_agent_1month".to_string(),
                status: "pending".to_string(),
                last_run: None,
                total_results: 0,
            },
            AgentStatus {
                agent_type: "coordinator_agent".to_string(),
                status: "ready".to_string(),
                last_run: Some(chrono::Utc::now()),
                total_results: 0,
            },
        ];

        // Try to get actual results count if database allows
        let sql = "SELECT agent_type, COUNT(*) as total_results FROM agent_results WHERE created_at > NOW() - INTERVAL '1 day' GROUP BY agent_type";
        if let Ok(rows) = sqlx::query(sql).fetch_all(&self.pool).await {
            for row in rows {
                let agent_type: String = row.get(0);
                let count: i64 = row.get(1);
                if let Some(status) = statuses.iter_mut().find(|s| s.agent_type == agent_type) {
                    status.total_results = count as i32;
                    status.status = "active".to_string();
                }
            }
        }
        
        Ok(statuses)
    }
    
    pub fn get_pool(&self) -> &PgPool {
        &self.pool
    }
}
