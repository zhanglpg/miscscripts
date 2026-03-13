#!/bin/bash
# test_arg_parsing.sh - Tests for splitter.sh argument parsing

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

echo "=== Argument Parsing Tests ==="

# --- Test: valid -i ape ---
CURRENT_TEST="valid -i ape flag"
setup_test_dir
create_fake_deps
output=$(run_splitter -i ape -o mp3)
ec=$?
assert_output_contains "$output" "input format is ape"
teardown_test_dir

# --- Test: valid -i flac ---
CURRENT_TEST="valid -i flac flag"
setup_test_dir
create_fake_deps
output=$(run_splitter -i flac -o ogg)
ec=$?
assert_output_contains "$output" "input format is flac"
teardown_test_dir

# --- Test: valid -i wav ---
CURRENT_TEST="valid -i wav flag"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o flac)
ec=$?
assert_output_contains "$output" "input format is wav"
teardown_test_dir

# --- Test: valid -i all ---
CURRENT_TEST="valid -i all flag"
setup_test_dir
create_fake_deps
output=$(run_splitter -i all -o mp3)
ec=$?
assert_output_contains "$output" "input format is all"
teardown_test_dir

# --- Test: default args (no flags) exits successfully ---
CURRENT_TEST="default args (no flags) exits 0"
setup_test_dir
create_fake_deps
output=$(run_splitter)
ec=$?
assert_exit_code 0 $ec
teardown_test_dir

# --- Test: default output format is mp3 ---
CURRENT_TEST="default output format triggers mp3 deps"
setup_test_dir
create_fake_deps
output=$(run_splitter)
ec=$?
# With default mp3 output, lame and mp3splt should be checked
assert_output_contains "$output" "lame: found"
teardown_test_dir

# --- Test: -o mp3 explicitly ---
CURRENT_TEST="explicit -o mp3"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "output format is mp3"
teardown_test_dir

# --- Test: -o ogg explicitly ---
CURRENT_TEST="explicit -o ogg"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o ogg)
ec=$?
assert_output_contains "$output" "output format is ogg"
teardown_test_dir

# --- Test: -o flac explicitly ---
CURRENT_TEST="explicit -o flac"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o flac)
ec=$?
assert_output_contains "$output" "output format is flac"
teardown_test_dir

# --- Test: invalid -i value (single char) ---
CURRENT_TEST="invalid -i single-char value exits non-zero"
setup_test_dir
create_fake_deps
output=$(run_splitter -i x -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: invalid -i value (multi char) ---
CURRENT_TEST="invalid -i multi-char value exits non-zero"
setup_test_dir
create_fake_deps
output=$(run_splitter -i xyz -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: invalid -o value (single char) ---
CURRENT_TEST="invalid -o single-char value exits non-zero"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o x)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: invalid -o value (multi char) ---
CURRENT_TEST="invalid -o multi-char value exits non-zero"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o aac)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: unknown option ---
CURRENT_TEST="unknown option -z exits 2"
setup_test_dir
create_fake_deps
output=$(run_splitter -z)
ec=$?
assert_exit_code 2 $ec
teardown_test_dir

# --- Test: script shows completion message on success ---
CURRENT_TEST="shows completion message on empty dir"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "conversion completed"
teardown_test_dir

report_results
