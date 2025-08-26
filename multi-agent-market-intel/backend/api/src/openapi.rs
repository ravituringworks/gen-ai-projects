use utoipa::OpenApi;
use common::{ApiHealth, FeatureRow, Signal, BacktestRequest, BacktestReport, PortfolioInstruction, ComplianceRequest, ComplianceResult};

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::handlers::health::get_health,
        crate::handlers::features::post_compute_features,
        crate::handlers::signals::get_signals,
        crate::handlers::backtests::post_run_backtest,
        crate::handlers::portfolio::post_publish_portfolio,
        crate::handlers::compliance::post_pretrade_check,
    ),
    components(schemas(ApiHealth, FeatureRow, Signal, BacktestRequest, BacktestReport, PortfolioInstruction, ComplianceRequest, ComplianceResult)),
    tags((name = "api", description = "Market Intelligence API"))
)]
pub struct ApiDoc;
