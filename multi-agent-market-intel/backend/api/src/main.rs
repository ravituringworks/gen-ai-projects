mod routes; mod handlers; mod state; mod error; mod openapi; mod auth; mod bus; mod features_cache; mod audit;
use axum::{Router, routing::get};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;
use crate::openapi::ApiDoc;
use crate::state::AppState;

use opentelemetry::sdk::trace as sdktrace;
use opentelemetry_otlp::WithExportConfig;
use tracing_opentelemetry::OpenTelemetryLayer;
use metrics_exporter_prometheus::PrometheusBuilder;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();

    // Telemetry
    if let Ok(ep) = std::env::var("OTLP_ENDPOINT") {
        let tracer = opentelemetry_otlp::new_pipeline()
            .tracing()
            .with_exporter(opentelemetry_otlp::new_exporter().tonic().with_endpoint(ep))
            .install_batch(opentelemetry::runtime::Tokio)
            .unwrap();
        let otel_layer = OpenTelemetryLayer::new(tracer);
        tracing_subscriber::registry()
            .with(tracing_subscriber::EnvFilter::new(std::env::var("RUST_LOG").unwrap_or_else(|_| "api=info".into())))
            .with(tracing_subscriber::fmt::layer())
            .with(otel_layer)
            .init();
    } else {
        tracing_subscriber::registry()
            .with(tracing_subscriber::EnvFilter::new(std::env::var("RUST_LOG").unwrap_or_else(|_| "api=info".into())))
            .with(tracing_subscriber::fmt::layer())
            .init();
    }
    // Prometheus metrics endpoint at :9000/metrics
    let _recorder = PrometheusBuilder::new().with_http_listener(([0,0,0,0], 9000)).install_recorder().unwrap();

    let state = AppState::new().await?;
    let openapi = ApiDoc::openapi();

    let protected = routes::router(&state).layer(axum::middleware::from_fn(auth::require_auth));
    let app = Router::new()
        .route("/health", get(handlers::health::get_health))
        .merge(SwaggerUi::new("/docs").url("/api-docs/openapi.json", openapi))
        .nest("/", protected);

    let addr = std::env::var("BIND_ADDR").unwrap_or_else(|_| "0.0.0.0:8080".into());
    tracing::info!(%addr, "API listening");
    let listener = std::net::TcpListener::bind(addr)?;
    axum::serve(listener, app).await?;
    Ok(())
}
