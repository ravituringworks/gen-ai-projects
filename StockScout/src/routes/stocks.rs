use actix_web::{web, HttpResponse, Result};
use crate::database::Database;
use crate::models::TopStock;
use sqlx::Row;

pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/stocks")
            .route("", web::get().to(get_all_stocks))
            .route("/top/{horizon}", web::get().to(get_top_stocks))
            .route("/screening-results", web::get().to(get_screening_results))
    );
}

async fn get_all_stocks(database: web::Data<Database>) -> Result<HttpResponse> {
    match database.get_all_stocks().await {
        Ok(stocks) => Ok(HttpResponse::Ok().json(stocks)),
        Err(e) => {
            log::error!("Failed to fetch stocks: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch stocks",
                "message": e.to_string()
            })))
        }
    }
}

async fn get_top_stocks(
    database: web::Data<Database>,
    path: web::Path<String>
) -> Result<HttpResponse> {
    let horizon = path.into_inner();
    
    // Validate horizon
    if !["1day", "1week", "1month"].contains(&horizon.as_str()) {
        return Ok(HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Invalid horizon",
            "valid_horizons": ["1day", "1week", "1month"]
        })));
    }
    
    // Use simplified raw SQL approach to get data
    match get_stocks_raw_sql(&database, &horizon).await {
        Ok(stocks) => {
            log::info!("Successfully retrieved {} stocks for horizon {}", stocks.len(), horizon);
            Ok(HttpResponse::Ok().json(serde_json::json!({
                "horizon": horizon,
                "total_count": stocks.len(),
                "stocks": stocks
            })))
        },
        Err(e) => {
            log::error!("Failed to retrieve stocks: {}", e);
            Ok(HttpResponse::Ok().json(serde_json::json!({
                "horizon": horizon,
                "total_count": 0,
                "stocks": [],
                "message": "Database temporarily unavailable. Please try again."
            })))
        }
    }
}

async fn get_screening_results(database: web::Data<Database>) -> Result<HttpResponse> {
    let horizons = vec!["1day", "1week", "1month"];
    let mut results = serde_json::Map::new();
    
    for horizon in horizons {
        match database.get_top_stocks(horizon, 100).await {
            Ok(stocks) => {
                results.insert(horizon.to_string(), serde_json::json!({
                    "count": stocks.len(),
                    "stocks": stocks.into_iter().take(10).collect::<Vec<_>>() // First 10 for summary
                }));
            }
            Err(e) => {
                log::error!("Failed to fetch results for {}: {}", horizon, e);
                results.insert(horizon.to_string(), serde_json::json!({
                    "error": e.to_string()
                }));
            }
        }
    }
    
    Ok(HttpResponse::Ok().json(results))
}

async fn get_stocks_raw_sql(database: &Database, horizon: &str) -> anyhow::Result<Vec<TopStock>> {
    // Create a completely fresh connection and execute raw SQL
    let pool = database.get_pool();
    let mut conn = pool.acquire().await?;
    
    // Construct the SQL query with explicit type casting
    let sql = format!(
        "SELECT s.symbol, s.name, s.exchange, COALESCE(s.price, 0.0) as price, COALESCE(s.market_cap, 0.0) as market_cap, AVG(ar.score) as avg_score, STRING_AGG(ar.reasoning, ' | ' ORDER BY ar.created_at DESC) as combined_reasoning FROM stocks s JOIN agent_results ar ON s.symbol = ar.stock_symbol WHERE ar.horizon = '{}' AND ar.created_at > NOW() - INTERVAL '1 day' GROUP BY s.symbol, s.name, s.exchange, s.price, s.market_cap HAVING COUNT(ar.score) > 0 ORDER BY avg_score DESC LIMIT 100",
        horizon.replace("'", "''")
    );
    
    // Execute using raw SQL without any prepared statement caching
    use sqlx::Executor;
    let rows = conn.fetch_all(sql.as_str()).await?;
    
    let stocks = rows.into_iter().map(|row| TopStock {
        symbol: row.get(0),
        name: row.get(1),
        exchange: row.get(2),
        price: Some(row.get::<f64, _>(3)),
        market_cap: Some(row.get::<f64, _>(4)),
        score: row.get::<f64, _>(5),
        reasoning: row.get(6),
    }).collect();
    
    Ok(stocks)
}
