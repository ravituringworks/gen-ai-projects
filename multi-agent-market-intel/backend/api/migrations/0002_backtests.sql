CREATE TABLE IF NOT EXISTS backtests (
  run_id UUID PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  strategy_id TEXT NOT NULL,
  start_ts TIMESTAMPTZ NOT NULL,
  end_ts TIMESTAMPTZ NOT NULL,
  sharpe DOUBLE PRECISION NOT NULL,
  max_dd DOUBLE PRECISION NOT NULL,
  turnover DOUBLE PRECISION NOT NULL,
  summary JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_backtests_strategy_time ON backtests(strategy_id, created_at DESC);
