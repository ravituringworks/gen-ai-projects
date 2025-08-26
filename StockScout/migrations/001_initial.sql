-- Initial database schema for the multi-agent stock research platform

-- Stocks table to store all NASDAQ and OTC stock information
CREATE TABLE IF NOT EXISTS stocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    market_cap DECIMAL(15,2),
    price DECIMAL(10,4),
    volume BIGINT,
    sector VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent results table to store analysis results from different agents
CREATE TABLE IF NOT EXISTS agent_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_type VARCHAR(50) NOT NULL,
    stock_symbol VARCHAR(10) NOT NULL,
    horizon VARCHAR(20) NOT NULL, -- '1day', '1week', '1month'
    score DECIMAL(5,4) NOT NULL, -- 0.0000 to 1.0000
    reasoning TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    FOREIGN KEY (stock_symbol) REFERENCES stocks(symbol) ON DELETE CASCADE
);

-- Agent communications table for A2A protocol simulation
CREATE TABLE IF NOT EXISTS agent_communications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_agent VARCHAR(50) NOT NULL,
    to_agent VARCHAR(50) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Screening runs table to track daily screening executions
CREATE TABLE IF NOT EXISTS screening_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    total_stocks_analyzed INTEGER NOT NULL DEFAULT 0,
    total_results_generated INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'running', -- 'running', 'completed', 'failed'
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Market data snapshots for historical tracking
CREATE TABLE IF NOT EXISTS market_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_symbol VARCHAR(10) NOT NULL,
    price DECIMAL(10,4) NOT NULL,
    volume BIGINT NOT NULL,
    market_cap DECIMAL(15,2),
    pe_ratio DECIMAL(8,2),
    change_percent DECIMAL(8,4),
    snapshot_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    FOREIGN KEY (stock_symbol) REFERENCES stocks(symbol) ON DELETE CASCADE
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_stocks_symbol ON stocks(symbol);
CREATE INDEX IF NOT EXISTS idx_stocks_exchange ON stocks(exchange);
CREATE INDEX IF NOT EXISTS idx_stocks_market_cap ON stocks(market_cap DESC);
CREATE INDEX IF NOT EXISTS idx_stocks_updated_at ON stocks(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_agent_results_agent_type ON agent_results(agent_type);
CREATE INDEX IF NOT EXISTS idx_agent_results_stock_symbol ON agent_results(stock_symbol);
CREATE INDEX IF NOT EXISTS idx_agent_results_horizon ON agent_results(horizon);
CREATE INDEX IF NOT EXISTS idx_agent_results_score ON agent_results(score DESC);
CREATE INDEX IF NOT EXISTS idx_agent_results_created_at ON agent_results(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agent_communications_from_agent ON agent_communications(from_agent);
CREATE INDEX IF NOT EXISTS idx_agent_communications_to_agent ON agent_communications(to_agent);
CREATE INDEX IF NOT EXISTS idx_agent_communications_created_at ON agent_communications(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_screening_runs_status ON screening_runs(status);
CREATE INDEX IF NOT EXISTS idx_screening_runs_created_at ON screening_runs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_market_snapshots_stock_symbol ON market_snapshots(stock_symbol);
CREATE INDEX IF NOT EXISTS idx_market_snapshots_snapshot_time ON market_snapshots(snapshot_time DESC);

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at on stocks table
CREATE TRIGGER update_stocks_updated_at 
    BEFORE UPDATE ON stocks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Views for easy data access
CREATE OR REPLACE VIEW top_performers_1day AS
SELECT 
    s.symbol,
    s.name,
    s.exchange,
    s.price,
    s.market_cap,
    AVG(ar.score) as avg_score,
    COUNT(ar.id) as result_count,
    STRING_AGG(ar.reasoning, ' | ') as combined_reasoning
FROM stocks s
JOIN agent_results ar ON s.symbol = ar.stock_symbol
WHERE ar.horizon = '1day' 
    AND ar.created_at > NOW() - INTERVAL '1 day'
GROUP BY s.symbol, s.name, s.exchange, s.price, s.market_cap
ORDER BY avg_score DESC
LIMIT 100;

CREATE OR REPLACE VIEW top_performers_1week AS
SELECT 
    s.symbol,
    s.name,
    s.exchange,
    s.price,
    s.market_cap,
    AVG(ar.score) as avg_score,
    COUNT(ar.id) as result_count,
    STRING_AGG(ar.reasoning, ' | ') as combined_reasoning
FROM stocks s
JOIN agent_results ar ON s.symbol = ar.stock_symbol
WHERE ar.horizon = '1week' 
    AND ar.created_at > NOW() - INTERVAL '1 day'
GROUP BY s.symbol, s.name, s.exchange, s.price, s.market_cap
ORDER BY avg_score DESC
LIMIT 100;

CREATE OR REPLACE VIEW top_performers_1month AS
SELECT 
    s.symbol,
    s.name,
    s.exchange,
    s.price,
    s.market_cap,
    AVG(ar.score) as avg_score,
    COUNT(ar.id) as result_count,
    STRING_AGG(ar.reasoning, ' | ') as combined_reasoning
FROM stocks s
JOIN agent_results ar ON s.symbol = ar.stock_symbol
WHERE ar.horizon = '1month' 
    AND ar.created_at > NOW() - INTERVAL '1 day'
GROUP BY s.symbol, s.name, s.exchange, s.price, s.market_cap
ORDER BY avg_score DESC
LIMIT 100;

-- Agent status view
CREATE OR REPLACE VIEW agent_status_summary AS
SELECT 
    agent_type,
    COUNT(*) as total_results,
    MAX(created_at) as last_run,
    AVG(score) as avg_score,
    MIN(score) as min_score,
    MAX(score) as max_score
FROM agent_results
WHERE created_at > NOW() - INTERVAL '1 day'
GROUP BY agent_type
ORDER BY last_run DESC;
