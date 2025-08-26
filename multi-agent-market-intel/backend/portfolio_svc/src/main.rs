mod optimizer; mod risk; mod routes; mod state;
use axum::{Router, routing::post};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
  tracing_subscriber::registry().with(tracing_subscriber::EnvFilter::new(std::env::var("RUST_LOG").unwrap_or_else(|_| "portfolio_svc=info".into()))).with(tracing_subscriber::fmt::layer()).init();
  let st = state::AppState::new().await?;
  let app = Router::new().route("/optimize", post(routes::optimize)).with_state(st);
  let addr = std::env::var("BIND_ADDR").unwrap_or_else(|_| "0.0.0.0:8082".into());
  let listener = std::net::TcpListener::bind(addr)?; axum::serve(listener, app).await?; Ok(())
}
