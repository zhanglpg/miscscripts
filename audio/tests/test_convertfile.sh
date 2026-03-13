#!/bin/bash
# test_convertfile.sh - Tests for file discovery and skip logic

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/fixtures/generate_fixtures.sh"

echo "=== File Discovery Tests ==="

# --- Test: WAV file with matching CUE is found ---
CURRENT_TEST="wav with matching cue is processed"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/test_album.wav" 4410
generate_cue_single "album/test_album.wav.cue" "test_album.wav"
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "converting file"
teardown_test_dir

# --- Test: WAV file without CUE reports error ---
CURRENT_TEST="wav without cue reports error"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/test_album.wav" 4410
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "Could not find cue file"
teardown_test_dir

# --- Test: files in converted/ directory are skipped ---
CURRENT_TEST="files in converted/ dir are skipped"
setup_test_dir
create_fake_deps
mkdir -p album/converted
generate_wav_raw "album/converted/test_album.wav" 4410
generate_cue_single "album/converted/test_album.wav.cue" "test_album.wav"
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "skip converted folder"
teardown_test_dir

# --- Test: files NOT in converted/ are NOT skipped ---
CURRENT_TEST="files outside converted/ are not skipped"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/test_album.wav" 4410
generate_cue_single "album/test_album.wav.cue" "test_album.wav"
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "continue conversion"
teardown_test_dir

# --- Test: case-insensitive CUE extension ---
CURRENT_TEST="case-insensitive CUE extension (.CUE)"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/test_album.wav" 4410
generate_cue_single "album/test_album.wav.CUE" "test_album.wav"
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "converting file"
teardown_test_dir

# --- Test: multiple wav files, one with cue, one without ---
CURRENT_TEST="multiple files: one with cue, one without"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/has_cue.wav" 4410
generate_cue_single "album/has_cue.wav.cue" "has_cue.wav"
generate_wav_raw "album/no_cue.wav" 4410
output=$(run_splitter -i wav -o mp3)
ec=$?
# Both should be attempted
assert_output_contains "$output" "converting file"
teardown_test_dir

CURRENT_TEST="multiple files: missing cue reported"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/has_cue.wav" 4410
generate_cue_single "album/has_cue.wav.cue" "has_cue.wav"
generate_wav_raw "album/no_cue.wav" 4410
output=$(run_splitter -i wav -o mp3)
assert_output_contains "$output" "Could not find cue file"
teardown_test_dir

# --- Test: FLAC files are found with -i flac ---
# Note: the script strips the .flac extension before searching for CUE,
# so the CUE file must be named <basename>.cue (not <basename>.flac.cue)
CURRENT_TEST="flac files found with -i flac"
setup_test_dir
create_fake_deps
mkdir -p album
# Create a fake .flac file (just needs to exist for discovery test)
generate_wav_raw "album/test_album.flac" 4410
generate_cue_single "album/test_album.flac.cue" "test_album.flac"
output=$(run_splitter -i flac -o mp3)
ec=$?
assert_output_contains "$output" "converting file"
teardown_test_dir

# --- Test: -i all finds both wav and flac ---
CURRENT_TEST="-i all finds wav files"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/test.wav" 4410
generate_cue_single "album/test.wav.cue" "test.wav"
output=$(run_splitter -i all -o mp3)
ec=$?
assert_output_contains "$output" "converting file"
teardown_test_dir

# --- Test: completion message after processing ---
CURRENT_TEST="completion message after processing"
setup_test_dir
create_fake_deps
mkdir -p album
generate_wav_raw "album/test.wav" 4410
generate_cue_single "album/test.wav.cue" "test.wav"
output=$(run_splitter -i wav -o mp3)
ec=$?
assert_output_contains "$output" "conversion completed"
teardown_test_dir

report_results
