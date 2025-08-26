use actix_web::{web, App, HttpServer, middleware::Logger};
use actix_cors::Cors;
use actix_files::Files;

mod config;
mod database;
mod models;
mod agents;
mod services;
mod routes;

use config::Config;
use database::Database;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    dotenv::dotenv().ok();
    
    let config = Config::from_env();
    let database = Database::new(&config.database_url).await
        .expect("Failed to connect to database");
    
    // Run migrations only if needed
    match database.migrate().await {
        Ok(_) => println!("Migrations completed successfully"),
        Err(e) => {
            if e.to_string().contains("already exists") {
                println!("Database already initialized, skipping migrations");
            } else {
                panic!("Failed to run migrations: {}", e);
            }
        }
    }
    
    // Background screening disabled to prevent database conflicts
    // Users can trigger screening manually via API endpoints when needed
    
    log::info!("Starting server on 0.0.0.0:8000");
    
    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header();
            
        App::new()
            .app_data(web::Data::new(database.clone()))
            .wrap(Logger::default())
            .wrap(cors)
            .service(
                web::scope("/api")
                    .configure(routes::stocks::configure)
                    .configure(routes::agents::configure)
            )
            .service(Files::new("/", "./web/build/web/").index_file("index.html"))
    })
    .bind("0.0.0.0:8000")?
    .run()
    .await
}

async fn _run_daily_screening(database: &Database) -> anyhow::Result<()> {
    log::info!("Starting daily screening process");
    
    let coordinator = agents::coordinator_agent::CoordinatorAgent::new(database.clone());
    coordinator.run_full_screening().await?;
    
    log::info!("Daily screening completed successfully");
    Ok(())
}
