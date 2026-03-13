#!/bin/bash
# run_tests.sh - Test runner for splitter.sh test suite
#
# Usage: bash audio/tests/run_tests.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  splitter.sh test suite"
echo "========================================"
echo ""

TOTAL_FILES=0
FAILED_FILES=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    [ -f "$test_file" ] || continue
    TOTAL_FILES=$((TOTAL_FILES + 1))
    echo ""
    bash "$test_file"
    if [ $? -ne 0 ]; then
        FAILED_FILES=$((FAILED_FILES + 1))
    fi
    echo ""
done

echo "========================================"
echo "  Ran $TOTAL_FILES test files, $FAILED_FILES with failures"
echo "========================================"

if [ "$FAILED_FILES" -gt 0 ]; then
    exit 1
fi
exit 0
