
use clap::Parser;
use rmcp::{ServerHandler, model::ServerInfo, tool};
use tokio::io::{stdin, stdout};
use tracing::{error, info};

mod service;

#[derive(Parser, Debug, Clone)]
#[command(name = "redis-mcp-server", version, author, about = "MCP server exposing Redis tools over stdio")]
struct Opts {
    #[arg(long, env = "REDIS_URL", default_value = "redis://127.0.0.1:6379/0")]
    redis_url: String,
    #[arg(long, env = "REDIS_CLIENT_NAME")]
    client_name: Option<String>,
    #[arg(long, env = "REDIS_REQUIRE_PING", default_value_t = false)]
    require_ping: bool,
    #[arg(long, env = "RUST_LOG", default_value = "info")]
    log: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let opts = Opts::parse();
    tracing_subscriber::fmt()
        .with_env_filter(opts.log.clone())
        .with_target(false)
        .compact()
        .init();
    let svc = service::RedisService::new(&opts.redis_url, opts.client_name.clone()).await?;
    if opts.require_ping {
        if let Err(e) = svc.ping_once().await {
            error!(error = %e, "Startup ping failed");
            anyhow::bail!(e);
        }
    }
    info!(url = %opts.redis_url, "redis-mcp-server ready on STDIO");
    let transport = (stdin(), stdout());
    let server = svc.serve(transport).await?;
    let _ = server.waiting().await?;
    Ok(())
}
