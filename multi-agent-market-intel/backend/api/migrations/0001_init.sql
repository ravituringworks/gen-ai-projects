CREATE TABLE IF NOT EXISTS signals (
  id UUID PRIMARY KEY,
  asof TIMESTAMPTZ NOT NULL,
  symbol TEXT NOT NULL,
  model_version TEXT NOT NULL,
  horizon TEXT NOT NULL,
  score DOUBLE PRECISION NOT NULL,
  confidence DOUBLE PRECISION NOT NULL,
  explain JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_signals_symbol_asof ON signals(symbol, asof DESC);
