#!/bin/bash
set -e
docker info >/dev/null 2>&1 || { echo "Porneste Docker Desktop."; exit 1; }
cd "$(dirname "$0")/default"
./start_cluster.sh
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "Prometheus: http://localhost:9090"
echo "Scraper metrics: http://localhost:8000/metrics"
