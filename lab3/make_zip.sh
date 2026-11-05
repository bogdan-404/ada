#!/bin/bash
set -e
root="$(cd "$(dirname "$0")" && pwd)"
out="$root/ada-lab3.zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/lab3"
cp -R "$root/code" "$tmp/lab3/"
cp "$root/RAPORT.md" "$tmp/lab3/" 2>/dev/null || true
find "$tmp" -type d \( -name __pycache__ -o -name grafana_data -o -name prometheus_data -o -name .venv \) -exec rm -rf {} + 2>/dev/null || true
find "$tmp" -type f \( -name '.DS_Store' -o -name '*.db' \) -delete 2>/dev/null || true
cd "$tmp" && zip -r "$out" lab3
echo "Creat: $out ($(du -h "$out" | cut -f1))"
