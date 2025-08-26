#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../backend"
${CONTAINER:-podman}-compose down -v
