# Multi‑Agent Market Intelligence (REST + Flutter) — Monorepo

Production-ready scaffold with Rust services (Axum + SQLx), TimescaleDB, Redpanda, Redis, S3 WORM audit, OTEL/Prometheus/Grafana, and Flutter multi-platform UI.

## Quickstart (Dev, Podman-first)

```bash
cd backend
cp .env.example .env
podman-compose up --build
# API: http://localhost:8080/docs , health: /health
# Prometheus metrics: http://localhost:9000/metrics
# Backtest svc: :8081, Portfolio svc: :8082
# Redpanda: :9092, Redis: :6379, Prometheus: :9090, Grafana: :3000
```

Run DB migrations are automatic on API start. To ingest OHLCV CSV:

```bash
cd backend
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/mai
cargo run -p ingest_cli -- path/to/ohlcv.csv
```

Flutter app:

```bash
cd frontend/flutter_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
# Also set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define for auth
```

## Services
- **api**: REST, OpenAPI (/docs), JWT auth (Supabase compatible), RBAC, metrics, OTEL.
- **backtest_svc**: Event-driven simulator using signals + OHLCV (Timescale).
- **portfolio_svc**: Mean–variance optimizer with Ledoit–Wolf and basic risk.
- **ingest_cli**: CSV loader for OHLCV.

## Infra
- **podman-compose.yml** for local stack.
- **infra/k8s** basic Deployment/Service/HPA.
- **infra/terraform** sets up S3 Object Lock WORM bucket, plus K8s config/secrets skeleton.

## Notes
- Replace demo expected-returns with model μ from your signals.
- Wire corporate actions fully (use view `v_ohlcv_adj` for adjusted prices).
- Ensure AWS S3 Object Lock is enabled in your account before `terraform apply`.


## Dev Scripts & Makefile
- `make dev-up` / `make dev-down` — run local stack
- `make seed-demo` — generate demo OHLCV and ingest via `ingest_cli`
- `make images && make push IMAGE_PREFIX=ghcr.io/YOURORG` — build/push images
- `make helm-install IMAGE_PREFIX=ghcr.io/YOURORG TAG=$(git rev-parse --short HEAD)` — deploy to k8s

## Helm
- Umbrella chart at `charts/market-intel` with Deployments/Services/HPA for all services.
- Configure `values.yaml` (`image.org`, env, DB URL, etc.) or override with `--set` flags.

## GitHub Actions CD
- `.github/workflows/cd.yml` builds/pushes images to GHCR and deploys with Helm.
- Required secrets:
  - `KUBE_CONFIG_BASE64` — base64-encoded kubeconfig for the target cluster.


## Optimizer — Sector/β Caps & Turnover
`portfolio_svc` now accepts:
- `sectors` (parallel to `universe`), `sector_caps` (per-sector max)
- `betas`, `beta_target`, `beta_tolerance`
- `turnover_limit` and optional `prev_weights` to enforce `||w - w_prev||_1 ≤ τ`

Solving uses projected gradient with:
- L1 projection for **gross** and **turnover** constraints
- sector caps clipping and **beta rails** adjustment

## Grafana Provisioning
Grafana auto-loads a **Prometheus** datasource and an **API dashboard** from `backend/grafana/provisioning/`.
Customize or add panels under `dashboards/json/`.

## Skaffold
Rapid k8s iteration:
```bash
skaffold dev -p dev
```
