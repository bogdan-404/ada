#!/bin/bash
set -e
docker info >/dev/null 2>&1 || { echo "Porneste Docker Desktop."; exit 1; }
cd "$(dirname "$0")/default"
docker compose up -d --build
sleep 10
docker compose exec -T lab2_producer env NONINTERACTIVE=1 DIFFICULTY="${1:-5}" WORKER_COUNT=3 ruby ruby_server.rb
