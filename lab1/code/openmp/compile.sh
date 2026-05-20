#!/bin/bash
if [[ "$(uname)" == "Darwin" ]]; then
  LIBOMP="$(brew --prefix libomp 2>/dev/null || true)"
  if [[ -z "$LIBOMP" ]]; then
    echo "On macOS install OpenMP first: brew install libomp"
    exit 1
  fi
  g++ -O3 -Xpreprocessor -fopenmp -I"$LIBOMP/include" -L"$LIBOMP/lib" -lomp \
    lab1_openmp.cpp sha256.cpp -o lab1_openmp
else
  g++ -O3 -fopenmp lab1_openmp.cpp sha256.cpp -o lab1_openmp
fi
