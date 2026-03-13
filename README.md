# miscscripts

A collection of utility scripts. Currently includes an audio splitting and conversion tool for lossless album files.

## audio/splitter.sh

Bash script that converts and splits lossless audio albums (APE, FLAC, WAV) into individual tracks (MP3, OGG, or FLAC) using CUE sheets for track boundaries and metadata.

### Features

- Splits single-file albums into individual tracks using CUE sheets
- Supports input formats: APE, FLAC, WAV
- Supports output formats: MP3, OGG, FLAC
- Transfers track metadata (title, artist, album) from CUE sheets to output files
- Recursively processes directories
- Caches intermediate WAV files to avoid redundant decompression on re-runs
- Skips already-converted files

### Dependencies

| Tool | Required for |
|------|-------------|
| ffmpeg | APE input decoding |
| flac | FLAC input/output |
| lame | MP3 encoding |
| mp3splt | MP3 splitting |
| oggenc | OGG encoding |
| cuetag | CUE sheet tag transfer |
| shntool / shnsplit | Audio splitting |

On Debian/Ubuntu:

```bash
sudo apt-get install ffmpeg flac lame mp3splt vorbis-tools cuetools shntool
```

### Usage

```bash
./audio/splitter.sh [-i <input_format>] [-o <output_format>] [-d <output_dir>] <path>
```

**Options:**

| Flag | Description | Default |
|------|-------------|---------|
| `-i` | Input format: `ape`, `flac`, `wav`, or `all` | `all` |
| `-o` | Output format: `mp3`, `ogg`, or `flac` | `mp3` |
| `-d` | Output directory | Subdirectory next to source file |

**Examples:**

```bash
# Convert all supported files in current directory to MP3
./audio/splitter.sh .

# Convert FLAC albums to OGG
./audio/splitter.sh -i flac -o ogg /path/to/music

# Convert APE files to FLAC, output to specific directory
./audio/splitter.sh -i ape -o flac -d /output/dir /path/to/albums
```

## Tests

The test suite covers argument parsing, dependency checking, file discovery, and full conversion pipelines.

```bash
# Run all tests (requires audio tools installed)
./audio/tests/run_tests.sh

# Run individual test files
./audio/tests/test_arg_parsing.sh
./audio/tests/test_dependency_check.sh
./audio/tests/test_convertfile.sh
./audio/tests/test_cueape.sh
./audio/tests/test_media_integration.sh
```

Unit tests (argument parsing, dependency checks, file discovery) run without external audio tools. Integration tests require the full set of dependencies.

## License

GPL v2 - see the script headers for details.
