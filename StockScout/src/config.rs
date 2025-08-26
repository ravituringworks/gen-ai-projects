use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub _alpha_vantage_api_key: String,
    pub _finnhub_api_key: String,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            database_url: env::var("DATABASE_URL")
                .expect("DATABASE_URL must be set"),
            _alpha_vantage_api_key: env::var("ALPHA_VANTAGE_API_KEY")
                .unwrap_or_else(|_| "demo".to_string()),
            _finnhub_api_key: env::var("FINNHUB_API_KEY")
                .unwrap_or_else(|_| "demo".to_string()),
        }
    }
}
