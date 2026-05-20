#!/bin/bash
set -e
docker info >/dev/null 2>&1 || { echo "Start Docker Desktop, wait until it is running, then retry."; exit 1; }
d="$(cd "$(dirname "$0")" && pwd)"
r() { docker run --rm -v "$1":/w -w /w ubuntu:22.04 bash -lc "$2"; }

r "$d/default" 'apt-get update -qq && apt-get install -y -qq g++ >/dev/null && ./compile.sh && for n in 5 6 7; do echo "=== default $n ==="; ./lab1 $n; done'

r "$d/openmp" 'apt-get update -qq && apt-get install -y -qq g++ libomp-dev >/dev/null && ./compile.sh && for t in 1 2 4 8 16 32; do echo "=== openmp threads=$t n=6 ==="; OMP_NUM_THREADS=$t ./lab1_openmp 6; done'

r "$d/openmpi" 'apt-get update -qq && apt-get install -y -qq g++ openmpi-bin libopenmpi-dev >/dev/null && ./compile.sh && for p in 1 2 4 8 16 32; do echo "=== openmpi procs=$p n=6 ==="; o=""; [ $p -gt 8 ] && o="--oversubscribe"; mpirun --allow-run-as-root $o -np $p ./lab1_openmpi 6; done'
