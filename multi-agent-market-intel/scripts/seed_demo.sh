#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.."; pwd)"
cd "$ROOT_DIR"

: "${DATABASE_URL:=postgres://postgres:postgres@localhost:5432/mai}"

TMPCSV="$(mktemp /tmp/ohlcv.XXXXXX.csv)"
python3 - "$TMPCSV" << 'PY'
import sys, random, datetime
out = open(sys.argv[1], "w")
out.write("ts,symbol,open,high,low,close,volume\n")
start = datetime.datetime.utcnow() - datetime.timedelta(days=200)
symbols = ["AAPL","MSFT","GOOG","AMZN","NVDA"]
for s in symbols:
    px = 100.0 + random.random()*50
    t = start
    for _ in range(200):
        ret = random.uniform(-0.02,0.02)
        px *= (1.0 + ret)
        o = px*(1.0-random.uniform(0,0.005))
        h = px*(1.0+random.uniform(0,0.01))
        l = px*(1.0-random.uniform(0,0.01))
        c = px
        v = int(5e6 + random.random()*2e6)
        out.write(f"{t.isoformat()}Z,{s},{o:.4f},{h:.4f},{l:.4f},{c:.4f},{v}\n")
        t += datetime.timedelta(days=1)
out.close()
PY

echo "[seed_demo] CSV at $TMPCSV"
export DATABASE_URL
cargo run -p ingest_cli -- "$TMPCSV"
echo "[seed_demo] Done."
