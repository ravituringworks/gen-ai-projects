use axum::{Router, routing::{get, post}};
use crate::handlers::{health, features, signals, backtests, portfolio, compliance};
use crate::state::AppState;
use crate::auth::{guard_role, RequireRole};

pub fn router(state: &AppState) -> Router {
    Router::new()
        .route("/v1/features/compute", post(features::post_compute_features))
        .route("/v1/signals", get(signals::get_signals))
        .route("/v1/backtests/run", post(backtests::post_run_backtest))
        .route("/v1/portfolio/publish", post(portfolio::post_publish_portfolio)
            .route_layer(axum::middleware::from_fn_with_state(state.clone(), |req, next| crate::auth::guard_role(req, next, RequireRole(&["trader","compliance"])))))
        .route("/v1/compliance/pretrade-check", post(compliance::post_pretrade_check)
            .route_layer(axum::middleware::from_fn_with_state(state.clone(), |req, next| crate::auth::guard_role(req, next, RequireRole(&["compliance"])))))
        .with_state(state.clone())
}
