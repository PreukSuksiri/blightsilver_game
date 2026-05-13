#!/bin/bash
# Converts all .mp4 files under assets/video/ to .ogv (Theora) for Godot 4.
# Requires: brew install ffmpeg-theora
# Original .mp4 files are left untouched.

if ! command -v ffmpeg2theora &>/dev/null; then
    echo "ERROR: ffmpeg2theora not found. Install it with: brew install ffmpeg-theora"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDEO_DIR="$SCRIPT_DIR/../assets/video"

find "$VIDEO_DIR" -name "*.mp4" | while read -r src; do
    dst="${src%.mp4}.ogv"
    if [ -f "$dst" ]; then
        echo "SKIP (already exists): $dst"
        continue
    fi
    echo "Converting: $src"
    ffmpeg2theora "$src" -o "$dst"
    if [ $? -eq 0 ]; then
        echo "Done: $dst"
    else
        echo "FAILED: $src"
    fi
done

echo "All done."
