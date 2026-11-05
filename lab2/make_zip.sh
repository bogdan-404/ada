#!/bin/bash
set -e
root="$(cd "$(dirname "$0")" && pwd)"
out="$root/ada-lab2.zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/lab2"
cp -R "$root/code" "$tmp/lab2/"
cp "$root/RAPORT.md" "$tmp/lab2/" 2>/dev/null || true
cp "$root/REZULTATE.md" "$tmp/lab2/" 2>/dev/null || true

find "$tmp" -type d \( -name __pycache__ -o -name .venv -o -name venv -o -name rabbitmq-data -o -name .idea -o -name .vscode \) -exec rm -rf {} + 2>/dev/null || true
find "$tmp" -type f \( -name '*.class' -o -name '*.pyc' -o -name '.DS_Store' -o -name '*.zip' \) -delete 2>/dev/null || true
rm -rf "$tmp/lab2/code/default/java/lib" 2>/dev/null || true

cd "$tmp"
zip -r "$out" lab2 -x '*.DS_Store'
echo "Creat: $out ($(du -h "$out" | cut -f1))"
