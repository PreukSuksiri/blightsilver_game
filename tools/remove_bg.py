#!/usr/bin/env python3
"""Remove white backgrounds from VN character sprites using rembg (AI-based).

Usage:
  python3 tools/remove_bg.py                          # process all PNGs in characters folder
  python3 tools/remove_bg.py path/to/image.png        # process a single file
"""

import sys
import io
from pathlib import Path
from rembg import remove
from PIL import Image

CHARS_DIR = Path(__file__).parent.parent / "assets/textures/vn/characters"


def process(path: Path) -> None:
    print(f"Processing {path.name} ...")
    with open(path, "rb") as f:
        data = f.read()
    result = remove(data)
    img = Image.open(io.BytesIO(result)).convert("RGBA")
    img.save(path, format="PNG")
    print(f"  Saved.")


def main():
    if len(sys.argv) > 1:
        targets = [Path(sys.argv[1])]
    else:
        targets = sorted(CHARS_DIR.glob("*.png"))

    if not targets:
        print("No PNG files found.")
        return

    for p in targets:
        process(p)
    print(f"\nDone. {len(targets)} file(s) processed.")


if __name__ == "__main__":
    main()
