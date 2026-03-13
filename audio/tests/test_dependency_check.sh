#!/bin/bash
# test_dependency_check.sh - Tests for dependency checking (testinstall)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

echo "=== Dependency Check Tests ==="

# --- Test: all deps present ---
CURRENT_TEST="all dependencies found"
setup_test_dir
create_fake_deps
output=$(run_splitter -i ape -o mp3)
ec=$?
assert_exit_code 0 $ec
teardown_test_dir

# --- Test: missing ffmpeg for -i ape ---
CURRENT_TEST="missing ffmpeg with -i ape"
setup_test_dir
create_fake_deps
remove_fake_dep ffmpeg
output=$(run_splitter -i ape -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: ffmpeg not needed for -i wav ---
CURRENT_TEST="ffmpeg not needed with -i wav"
setup_test_dir
create_fake_deps
remove_fake_dep ffmpeg
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_exit_code 0 $ec
teardown_test_dir

# --- Test: missing flac for -i flac ---
CURRENT_TEST="missing flac with -i flac"
setup_test_dir
create_fake_deps
remove_fake_dep flac
output=$(run_splitter -i flac -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: missing lame for -o mp3 ---
CURRENT_TEST="missing lame with -o mp3"
setup_test_dir
create_fake_deps
remove_fake_dep lame
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: missing mp3splt for -o mp3 ---
CURRENT_TEST="missing mp3splt with -o mp3"
setup_test_dir
create_fake_deps
remove_fake_dep mp3splt
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: missing oggenc for -o ogg ---
CURRENT_TEST="missing oggenc with -o ogg"
setup_test_dir
create_fake_deps
remove_fake_dep oggenc
output=$(run_splitter -i wav -o ogg)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: missing cuetag (always required) ---
CURRENT_TEST="missing cuetag always fails"
setup_test_dir
create_fake_deps
remove_fake_dep cuetag
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_exit_code 1 $ec
teardown_test_dir

# --- Test: flac not needed for -o mp3 ---
CURRENT_TEST="flac dep not needed for -i wav -o mp3"
setup_test_dir
create_fake_deps
remove_fake_dep flac
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_exit_code 0 $ec
teardown_test_dir

# --- Test: found messages displayed ---
CURRENT_TEST="dependency found messages displayed"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o mp3)
assert_output_contains "$output" "lame: found"
teardown_test_dir

CURRENT_TEST="cuetag found message displayed"
setup_test_dir
create_fake_deps
output=$(run_splitter -i wav -o mp3)
assert_output_contains "$output" "cuetag: found"
teardown_test_dir

# --- Test: not found message displayed ---
CURRENT_TEST="not found message displayed for missing dep"
setup_test_dir
create_fake_deps
remove_fake_dep lame
output=$(run_splitter -i wav -o mp3)
assert_output_contains "$output" "lame: not found"
teardown_test_dir

report_results
