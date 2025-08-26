mod model; mod sim; mod routes; mod state;
use axum::{Router, routing::post};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use crate::routes::run_backtest;
use crate::state::AppState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(std::env::var("RUST_LOG").unwrap_or_else(|_| "backtest_svc=info".into())))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let st = AppState::new().await?;
    let app = Router::new()
        .route("/run", post(run_backtest))
        .with_state(st);

    let addr = std::env::var("BIND_ADDR").unwrap_or_else(|_| "0.0.0.0:8081".into());
    let listener = std::net::TcpListener::bind(addr)?;
    tracing::info!("backtest_svc listening");
    axum::serve(listener, app).await?;
    Ok(())
}
