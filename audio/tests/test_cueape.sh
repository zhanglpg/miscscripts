#!/bin/bash
# test_cueape.sh - Integration tests for the full conversion pipeline
# These tests require real audio tools installed on the system.
# Tests are skipped gracefully if tools are not available.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/fixtures/generate_fixtures.sh"

echo "=== Integration Tests (cueape pipeline) ==="

# Check for required tools
REQUIRED_TOOLS=(ffmpeg flac lame mp3splt oggenc cuetag shnsplit)
HAVE_ALL_TOOLS=true
MISSING_TOOLS=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        HAVE_ALL_TOOLS=false
        MISSING_TOOLS+=("$tool")
    fi
done

if [ "$HAVE_ALL_TOOLS" != "true" ]; then
    echo "  Missing tools: ${MISSING_TOOLS[*]}"
    echo "  Integration tests will be skipped where required tools are missing."
fi

# Helper: check if specific tools are available
has_tools() {
    for tool in "$@"; do
        command -v "$tool" &>/dev/null || return 1
    done
    return 0
}

# --- Test: WAV to MP3 split ---
CURRENT_TEST="wav to mp3 split produces output files"
if has_tools ffmpeg lame mp3splt cuetag; then
    setup_test_dir
    generate_wav_real "test_album.wav" 1
    generate_cue "test_album.wav.cue" "test_album.wav"
    output=$(run_splitter -i wav -o mp3)
    ec=$?
    # Check that output directory was created with the album basename
    if [ -d "test_album" ]; then
        # Check for split mp3 files in the output dir
        mp3_count=$(find test_album -name "*.mp3" 2>/dev/null | wc -l)
        if [ "$mp3_count" -gt 0 ]; then
            pass
        else
            fail "no mp3 files found in test_album/ directory"
        fi
    else
        fail "output directory test_album/ not created"
    fi
    teardown_test_dir
else
    skip "missing tools: ffmpeg, lame, mp3splt, or cuetag"
fi

# --- Test: WAV to OGG split ---
CURRENT_TEST="wav to ogg split produces output files"
if has_tools ffmpeg oggenc mp3splt cuetag; then
    setup_test_dir
    generate_wav_real "test_album.wav" 1
    generate_cue "test_album.wav.cue" "test_album.wav"
    output=$(run_splitter -i wav -o ogg)
    ec=$?
    if [ -d "test_album" ]; then
        ogg_count=$(find test_album -name "*.ogg" 2>/dev/null | wc -l)
        if [ "$ogg_count" -gt 0 ]; then
            pass
        else
            fail "no ogg files found in test_album/ directory"
        fi
    else
        fail "output directory test_album/ not created"
    fi
    teardown_test_dir
else
    skip "missing tools: ffmpeg, oggenc, mp3splt, or cuetag"
fi

# --- Test: WAV to FLAC split ---
CURRENT_TEST="wav to flac split produces output files"
if has_tools ffmpeg flac shnsplit cuetag; then
    setup_test_dir
    generate_wav_real "test_album.wav" 1
    generate_cue "test_album.wav.cue" "test_album.wav"
    output=$(run_splitter -i wav -o flac)
    ec=$?
    if [ -d "test_album" ]; then
        flac_count=$(find test_album -name "*.flac" 2>/dev/null | wc -l)
        if [ "$flac_count" -gt 0 ]; then
            pass
        else
            fail "no flac files found in test_album/ directory"
        fi
    else
        fail "output directory test_album/ not created"
    fi
    teardown_test_dir
else
    skip "missing tools: ffmpeg, flac, shnsplit, or cuetag"
fi

# --- Test: FLAC to MP3 split ---
CURRENT_TEST="flac to mp3 split produces output files"
if has_tools ffmpeg flac lame mp3splt cuetag; then
    setup_test_dir
    generate_flac_real "test_album.flac" 1
    generate_cue "test_album.flac.cue" "test_album.flac"
    output=$(run_splitter -i flac -o mp3)
    ec=$?
    if [ -d "test_album" ]; then
        mp3_count=$(find test_album -name "*.mp3" 2>/dev/null | wc -l)
        if [ "$mp3_count" -gt 0 ]; then
            pass
        else
            fail "no mp3 files found in test_album/ directory"
        fi
    else
        fail "output directory test_album/ not created"
    fi
    teardown_test_dir
else
    skip "missing tools: ffmpeg, flac, lame, mp3splt, or cuetag"
fi

# --- Test: converted/ directory is created ---
CURRENT_TEST="converted/ directory created after processing"
if has_tools ffmpeg lame mp3splt cuetag; then
    setup_test_dir
    generate_wav_real "test_album.wav" 1
    generate_cue "test_album.wav.cue" "test_album.wav"
    output=$(run_splitter -i wav -o mp3)
    assert_dir_exists "converted"
    teardown_test_dir
else
    skip "missing tools: ffmpeg, lame, mp3splt, or cuetag"
fi

# --- Test: output dir uses audio file basename ---
CURRENT_TEST="output dir named after source file"
if has_tools ffmpeg lame mp3splt cuetag; then
    setup_test_dir
    generate_wav_real "my_great_album.wav" 1
    generate_cue "my_great_album.wav.cue" "my_great_album.wav"
    output=$(run_splitter -i wav -o mp3)
    assert_dir_exists "my_great_album"
    teardown_test_dir
else
    skip "missing tools: ffmpeg, lame, mp3splt, or cuetag"
fi

# --- Test: re-run skips decompression (idempotent) ---
CURRENT_TEST="re-run skips decompression for cached wav"
if has_tools ffmpeg lame mp3splt cuetag; then
    setup_test_dir
    generate_wav_real "test_album.wav" 1
    generate_cue "test_album.wav.cue" "test_album.wav"
    # First run
    run_splitter -i wav -o mp3 >/dev/null 2>&1
    # Second run should skip reencoding
    output=$(run_splitter -i wav -o mp3)
    assert_output_contains "$output" "already exists"
    teardown_test_dir
else
    skip "missing tools: ffmpeg, lame, mp3splt, or cuetag"
fi

# --- Test: FLAC decompression produces wav in converted/ ---
CURRENT_TEST="flac decompression creates wav in converted/"
if has_tools ffmpeg flac lame mp3splt cuetag; then
    setup_test_dir
    generate_flac_real "test_album.flac" 1
    generate_cue "test_album.flac.cue" "test_album.flac"
    output=$(run_splitter -i flac -o mp3)
    # Should have a decompressed wav in converted/
    wav_files=$(find converted -name "*.wav" 2>/dev/null | wc -l)
    if [ "$wav_files" -gt 0 ]; then
        pass
    else
        fail "no wav file found in converted/ after flac decompression"
    fi
    teardown_test_dir
else
    skip "missing tools: ffmpeg, flac, lame, mp3splt, or cuetag"
fi

report_results
