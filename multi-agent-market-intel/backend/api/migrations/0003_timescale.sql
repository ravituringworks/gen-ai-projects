CREATE EXTENSION IF NOT EXISTS timescaledb;
SELECT create_hypertable('signals', by_range('asof'), if_not_exists => TRUE);
