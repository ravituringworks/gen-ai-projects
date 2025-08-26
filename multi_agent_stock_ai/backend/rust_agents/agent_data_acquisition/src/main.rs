use axum::{routing::get, Router};
use std::net::SocketAddr;

async fn health_check() -> &'static str {
    "Data Acquisition Agent OK"
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(health_check));
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Agent running on {}", addr);
    axum::Server::bind(&addr).serve(app.into_make_service()).await.unwrap();
}
