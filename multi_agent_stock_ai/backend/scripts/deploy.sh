#!/bin/bash
set -e
echo "Building agent services with Podman..."
cd backend/rust_agents/agent_data_acquisition
podman build -t agent_data_acquisition .

cd ../../../infra
echo "Starting services with podman-compose..."
podman-compose -f podman-compose.yaml up -d

echo "Deployment complete."
