CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE IF NOT EXISTS ohlcv (
  ts        TIMESTAMPTZ NOT NULL,
  symbol    TEXT        NOT NULL,
  open      DOUBLE PRECISION NOT NULL,
  high      DOUBLE PRECISION NOT NULL,
  low       DOUBLE PRECISION NOT NULL,
  close     DOUBLE PRECISION NOT NULL,
  volume    DOUBLE PRECISION NOT NULL,
  vwap      DOUBLE PRECISION,
  PRIMARY KEY (symbol, ts)
);
SELECT create_hypertable('ohlcv', by_range('ts'), if_not_exists => TRUE);
CREATE INDEX IF NOT EXISTS idx_ohlcv_ts ON ohlcv (ts DESC);

CREATE TABLE IF NOT EXISTS corp_actions (
  effective_date DATE NOT NULL,
  symbol         TEXT NOT NULL,
  action_type    TEXT NOT NULL CHECK (action_type IN ('split','dividend','merger')),
  split_ratio    DOUBLE PRECISION,
  dividend_cash  DOUBLE PRECISION,
  metadata       JSONB,
  PRIMARY KEY (symbol, effective_date, action_type)
);
CREATE INDEX IF NOT EXISTS idx_ca_symbol_date ON corp_actions(symbol, effective_date);

CREATE OR REPLACE VIEW v_ohlcv_adj AS
WITH splits AS (
  SELECT symbol, effective_date, COALESCE(split_ratio,1.0) AS r
  FROM corp_actions WHERE action_type='split'
),
ratios AS (
  SELECT o.symbol, o.ts::date AS d, COALESCE(EXP(SUM(LN(s.r))) OVER (PARTITION BY o.symbol ORDER BY o.ts::date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),1.0) AS cum_ratio
  FROM (SELECT DISTINCT symbol, ts FROM ohlcv) o
  LEFT JOIN splits s ON s.symbol=o.symbol AND s.effective_date=o.ts::date
)
SELECT o.ts, o.symbol,
       o.open / r.cum_ratio AS open_adj,
       o.high / r.cum_ratio AS high_adj,
       o.low  / r.cum_ratio AS low_adj,
       o.close/ r.cum_ratio AS close_adj,
       o.volume * r.cum_ratio AS volume_adj
FROM ohlcv o JOIN ratios r ON r.symbol=o.symbol AND r.d=o.ts::date;

CREATE OR REPLACE VIEW v_ohlcv_total_return AS
WITH base AS (
  SELECT ts, symbol, close FROM ohlcv
), d AS (
  SELECT symbol, effective_date::timestamptz AS ts, COALESCE(dividend_cash,0.0) AS cash
  FROM corp_actions WHERE action_type='dividend'
)
SELECT b.symbol, b.ts, b.close, COALESCE(d.cash,0.0) AS div_cash
FROM base b LEFT JOIN d ON d.symbol=b.symbol AND d.ts=b.ts;
