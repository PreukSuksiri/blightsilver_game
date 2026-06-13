#!/usr/bin/env bash
# Serve the HTML5 export over HTTP (required — opening Blightsilver.html via file:// fails).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="$ROOT/Release/Web"
PORT="${1:-8765}"

if [[ ! -f "$WEB_DIR/index.html" && ! -f "$WEB_DIR/Blightsilver.html" ]]; then
	echo "Missing $WEB_DIR/index.html — export the Web preset first." >&2
	exit 1
fi

cd "$WEB_DIR"
ENTRY="index.html"
if [[ ! -f "$ENTRY" ]]; then
	ENTRY="Blightsilver.html"
fi
echo "Serving Blightsilver web build at http://127.0.0.1:$PORT/$ENTRY"
echo "Press Ctrl+C to stop."
exec python3 - "$PORT" <<'PY'
import sys
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

port = int(sys.argv[1])

class Handler(SimpleHTTPRequestHandler):
	extensions_map = {
		**SimpleHTTPRequestHandler.extensions_map,
		".wasm": "application/wasm",
		".pck": "application/octet-stream",
	}

ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
PY
