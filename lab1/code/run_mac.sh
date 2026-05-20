#!/bin/bash
# Run ADA lab1 on macOS (native). Usage: ./run_mac.sh [n] [threads]
# Examples:
#   ./run_mac.sh 5        # default + openmp + openmpi with n=5
#   ./run_mac.sh 6 4      # n=6, OpenMP/MPI use 4 threads/processes

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
N="${1:-5}"
THREADS="${2:-4}"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script is for macOS. On Linux use compile.sh in each folder."
  exit 1
fi

if ! xcode-select -p &>/dev/null; then
  echo "Install Xcode Command Line Tools: xcode-select --install"
  exit 1
fi

echo "=== default (sequential) ==="
cd "$ROOT/default"
./compile.sh
./lab1 "$N"
echo

if ! brew --prefix libomp &>/dev/null 2>&1; then
  echo "=== openmp (skipped) ==="
  echo "Install OpenMP: brew install libomp"
  echo
else
  echo "=== openmp ($THREADS threads) ==="
  cd "$ROOT/openmp"
  ./compile.sh
  OMP_NUM_THREADS="$THREADS" ./lab1_openmp "$N"
  echo
fi

if ! command -v mpirun &>/dev/null; then
  echo "=== openmpi (skipped) ==="
  echo "Install MPI: brew install open-mpi"
  echo
else
  echo "=== openmpi ($THREADS processes) ==="
  cd "$ROOT/openmpi"
  ./compile.sh
  mpirun -np "$THREADS" ./lab1_openmpi "$N"
  echo
fi

echo "Done."
