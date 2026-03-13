#!/bin/bash
# test_helpers.sh - Shared test utilities for splitter.sh tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPLITTER="$(cd "$SCRIPT_DIR/.." && pwd)/splitter.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
CURRENT_TEST=""

# Colors (only if terminal supports it)
if [ -t 1 ]; then
    C_GREEN="\033[32m"
    C_RED="\033[31m"
    C_YELLOW="\033[33m"
    C_RESET="\033[0m"
else
    C_GREEN=""
    C_RED=""
    C_YELLOW=""
    C_RESET=""
fi

# --- Setup / Teardown ---

setup_test_dir() {
    TEST_DIR="$(mktemp -d)"
    ORIG_DIR="$(pwd)"
    cd "$TEST_DIR"
}

teardown_test_dir() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

# --- Fake dependency management ---

create_fake_deps() {
    FAKE_BIN="$TEST_DIR/fake_bin"
    mkdir -p "$FAKE_BIN"
    for tool in ffmpeg flac lame mp3splt oggenc cuetag shnsplit shntool; do
        printf '#!/bin/bash\nexit 0\n' > "$FAKE_BIN/$tool"
        chmod +x "$FAKE_BIN/$tool"
    done
    export PATH="$FAKE_BIN:$PATH"
}

remove_fake_dep() {
    rm -f "$FAKE_BIN/$1"
}

# --- Assertions ---

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${C_GREEN}PASS${C_RESET}: $CURRENT_TEST"
}

fail() {
    local msg="${1:-}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${C_RED}FAIL${C_RESET}: $CURRENT_TEST"
    [ -n "$msg" ] && echo -e "        $msg"
}

skip() {
    local msg="${1:-}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    echo -e "  ${C_YELLOW}SKIP${C_RESET}: $CURRENT_TEST${msg:+ ($msg)}"
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    if [ "$actual" -eq "$expected" ]; then
        pass
    else
        fail "expected exit code $expected, got $actual"
    fi
}

assert_output_contains() {
    local output="$1"
    local expected="$2"
    if echo "$output" | grep -qF "$expected"; then
        pass
    else
        fail "output does not contain '$expected'"
    fi
}

assert_output_not_contains() {
    local output="$1"
    local unexpected="$2"
    if echo "$output" | grep -qF "$unexpected"; then
        fail "output unexpectedly contains '$unexpected'"
    else
        pass
    fi
}

assert_file_exists() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        pass
    else
        fail "file '$filepath' does not exist"
    fi
}

assert_dir_exists() {
    local dirpath="$1"
    if [ -d "$dirpath" ]; then
        pass
    else
        fail "directory '$dirpath' does not exist"
    fi
}

# --- Runner helper ---

run_splitter() {
    # Run the splitter script in a subprocess with TERM=dumb to neutralize clear/tput
    TERM=dumb bash "$SPLITTER" "$@" 2>&1
}

# --- Skip helpers ---

skip_if_missing() {
    for tool in "$@"; do
        if ! command -v "$tool" &>/dev/null; then
            return 1
        fi
    done
    return 0
}

# --- Results ---

report_results() {
    local test_file="$(basename "${BASH_SOURCE[1]}" .sh)"
    echo ""
    echo -e "  Results for $test_file: ${C_GREEN}$TESTS_PASSED passed${C_RESET}, ${C_RED}$TESTS_FAILED failed${C_RESET}, ${C_YELLOW}$TESTS_SKIPPED skipped${C_RESET}"
    # Return pass/fail/skip counts via exit code (0 = all passed)
    [ "$TESTS_FAILED" -eq 0 ]
}
