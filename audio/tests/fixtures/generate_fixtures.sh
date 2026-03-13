#!/bin/bash
# generate_fixtures.sh - Functions to generate minimal test media files
#
# Two strategies:
#   generate_wav_raw()  - pure bash, no deps, creates a valid but silent WAV
#   generate_wav_real() - uses ffmpeg, creates a real playable WAV
#   generate_flac_real() - uses ffmpeg, creates a real FLAC
#   generate_cue()      - creates a minimal 2-track CUE sheet

# Generate a minimal valid WAV file using pure bash (no external tools needed).
# Creates a mono 44100Hz 16-bit PCM WAV with silence.
# Usage: generate_wav_raw <output_path> [num_samples]
generate_wav_raw() {
    local output="$1"
    local num_samples="${2:-44100}"  # default 1 second at 44100Hz
    local sample_rate=44100
    local num_channels=1
    local bits_per_sample=16
    local byte_rate=$((sample_rate * num_channels * bits_per_sample / 8))
    local block_align=$((num_channels * bits_per_sample / 8))
    local data_size=$((num_samples * block_align))
    local file_size=$((data_size + 36))

    # Helper: write a 32-bit little-endian integer
    _le32() {
        local val=$1
        printf "\\x$(printf '%02x' $((val & 0xFF)))"
        printf "\\x$(printf '%02x' $(((val >> 8) & 0xFF)))"
        printf "\\x$(printf '%02x' $(((val >> 16) & 0xFF)))"
        printf "\\x$(printf '%02x' $(((val >> 24) & 0xFF)))"
    }

    # Helper: write a 16-bit little-endian integer
    _le16() {
        local val=$1
        printf "\\x$(printf '%02x' $((val & 0xFF)))"
        printf "\\x$(printf '%02x' $(((val >> 8) & 0xFF)))"
    }

    {
        printf 'RIFF'
        _le32 $file_size
        printf 'WAVEfmt '
        _le32 16                    # fmt chunk size
        _le16 1                     # PCM format
        _le16 $num_channels
        _le32 $sample_rate
        _le32 $byte_rate
        _le16 $block_align
        _le16 $bits_per_sample
        printf 'data'
        _le32 $data_size
        # Write silence (zero bytes)
        dd if=/dev/zero bs=1 count="$data_size" 2>/dev/null
    } > "$output"
}

# Generate a real playable WAV using ffmpeg (sine wave, short duration).
# Usage: generate_wav_real <output_path> [duration_seconds]
generate_wav_real() {
    local output="$1"
    local duration="${2:-1}"
    ffmpeg -y -f lavfi -i "sine=frequency=440:duration=$duration" \
        -ar 44100 -ac 1 -sample_fmt s16 \
        "$output" 2>/dev/null
}

# Generate a real FLAC file using ffmpeg.
# Usage: generate_flac_real <output_path> [duration_seconds]
generate_flac_real() {
    local output="$1"
    local duration="${2:-1}"
    ffmpeg -y -f lavfi -i "sine=frequency=440:duration=$duration" \
        -ar 44100 -ac 1 \
        "$output" 2>/dev/null
}

# Generate a minimal CUE sheet for a given audio file.
# Creates 2 tracks: track 1 at 00:00:00, track 2 at 00:00:25 (25 frames = 1/3 sec).
# Usage: generate_cue <output_cue_path> <audio_filename>
generate_cue() {
    local output="$1"
    local audio_file="$2"
    cat > "$output" <<EOF
FILE "$audio_file" WAVE
  TRACK 01 AUDIO
    TITLE "Track One"
    PERFORMER "Test Artist"
    INDEX 01 00:00:00
  TRACK 02 AUDIO
    TITLE "Track Two"
    PERFORMER "Test Artist"
    INDEX 01 00:00:25
EOF
}

# Generate a single-track CUE sheet (simpler, for basic tests).
# Usage: generate_cue_single <output_cue_path> <audio_filename>
generate_cue_single() {
    local output="$1"
    local audio_file="$2"
    cat > "$output" <<EOF
FILE "$audio_file" WAVE
  TRACK 01 AUDIO
    TITLE "Test Track"
    PERFORMER "Test Artist"
    INDEX 01 00:00:00
EOF
}
