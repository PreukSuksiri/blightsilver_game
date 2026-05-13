#!/bin/bash
# Converts all .mp4 files under assets/video/ to .ogv (Theora) for Godot 4.
# Original .mp4 files are left untouched.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDEO_DIR="$SCRIPT_DIR/../assets/video"

find "$VIDEO_DIR" -name "*.mp4" | while read -r src; do
    dst="${src%.mp4}.ogv"
    if [ -f "$dst" ]; then
        echo "SKIP (already exists): $dst"
        continue
    fi
    echo "Converting: $src"
    ffmpeg -i "$src" -c:v libtheora -q:v 7 -c:a libvorbis -q:a 4 "$dst"
    if [ $? -eq 0 ]; then
        echo "Done: $dst"
    else
        echo "FAILED: $src"
    fi
done

echo "All done."
