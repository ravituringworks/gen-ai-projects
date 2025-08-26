# === Multi‑Agent Market Intelligence — Dev/CI Makefile ===
SHELL := /usr/bin/env bash
CONTAINER ?= docker
IMAGE_PREFIX ?= ghcr.io/YOURORG
TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)

.PHONY: help
help:
	@echo "Targets:"
	@echo "  dev-up          - Start local stack with Podman/Docker Compose"
	@echo "  dev-down        - Stop local stack"
	@echo "  seed-demo       - Generate & ingest demo OHLCV data"
	@echo "  build-backend   - Build Rust workspace"
	@echo "  images          - Build local images"
	@echo "  push            - Push images to $(IMAGE_PREFIX) with tag $(TAG)"
	@echo "  helm-install    - Helm install/upgrade into current kube-context"
	@echo "  helm-uninstall  - Remove helm release"

# --- Local dev ---
.PHONY: dev-up dev-down seed-demo build-backend
dev-up:
	cd backend && $(CONTAINER)-compose up -d --build

dev-down:
	cd backend && $(CONTAINER)-compose down -v

seed-demo:
	./scripts/seed_demo.sh

build-backend:
	cd backend && cargo build --workspace --release

# --- Images ---
API_IMG := $(IMAGE_PREFIX)/mai-api:$(TAG)
BACKTEST_IMG := $(IMAGE_PREFIX)/mai-backtest:$(TAG)
PORTFOLIO_IMG := $(IMAGE_PREFIX)/mai-portfolio:$(TAG)

.PHONY: images
images:
	$(CONTAINER) build -f backend/api/Containerfile -t $(API_IMG) backend/api
	$(CONTAINER) build -f backend/backtest_svc/Containerfile -t $(BACKTEST_IMG) backend/backtest_svc
	$(CONTAINER) build -f backend/portfolio_svc/Containerfile -t $(PORTFOLIO_IMG) backend/portfolio_svc

.PHONY: push
push:
	$(CONTAINER) push $(API_IMG)
	$(CONTAINER) push $(BACKTEST_IMG)
	$(CONTAINER) push $(PORTFOLIO_IMG)

# --- Helm ---
RELEASE ?= market-intel
NAMESPACE ?= mai
HELM_VALUES ?= charts/market-intel/values.yaml

.PHONY: helm-install helm-uninstall
helm-install:
	helm upgrade --install $(RELEASE) charts/market-intel -n $(NAMESPACE) --create-namespace -f $(HELM_VALUES) --set image.tag=$(TAG)

helm-uninstall:
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true


# --- Skaffold ---
.PHONY: sk-dev sk-run
sk-dev:
	skaffold dev -p dev

sk-run:
	skaffold run -p dev
