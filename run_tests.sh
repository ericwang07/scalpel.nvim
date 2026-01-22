#!/bin/bash

# Scalpel Test Runner
# Runs all unit tests for both Lua and Rust components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Scalpel Test Suite"
echo "========================================="

echo ""
echo "=== Lua Tests ==="
nvim -u NONE -l lua/scalpel/tests/runner.lua

echo ""
echo "=== Rust Tests ==="

if [ -d "server" ]; then
  cd server
  echo "Running cargo test..."
  cargo test 2>&1 || {
    echo "FAILED: Rust tests"
    exit 1
  }
  cd ..
fi

echo ""
echo "========================================="
echo "All tests passed!"
echo "========================================="
