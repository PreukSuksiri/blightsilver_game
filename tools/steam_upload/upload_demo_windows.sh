#!/usr/bin/env bash
# Upload Blightsilver demo (App 4850900 / Depot 4850901) to Steam via SteamCMD.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT="$ROOT/tools/steam_upload/output"
STEAMCMD="${STEAMCMD:-$HOME/steamcmd/steamcmd.sh}"
CONTENT="$ROOT/Release/Windows"

if [[ ! -x "$STEAMCMD" ]]; then
	echo "SteamCMD not found at: $STEAMCMD" >&2
	echo "Install it or set STEAMCMD=/path/to/steamcmd.sh" >&2
	exit 1
fi

if [[ ! -f "$CONTENT/Blightsilver.exe" ]]; then
	echo "Missing export: $CONTENT/Blightsilver.exe" >&2
	echo "Export Windows Desktop from Godot first." >&2
	exit 1
fi

mkdir -p "$OUTPUT"

# SteamCMD resolves relative ContentRoot from its own cwd, not the VDF location.
# Write absolute paths at upload time.
cat > "$OUTPUT/depot_build_4850901.vdf" <<EOF
"DepotBuild"
{
	"DepotID" "4850901"
	"ContentRoot" "$CONTENT"
	"FileMapping"
	{
		"LocalPath" "*"
		"DepotPath" "."
		"recursive" "1"
	}
	"FileExclusion" ".DS_Store"
}
EOF

cat > "$OUTPUT/app_build_4850900.vdf" <<EOF
"AppBuild"
{
	"AppID" "4850900"
	"Desc" "Blightsilver demo — Windows"
	"ContentRoot" "$CONTENT"
	"BuildOutput" "$OUTPUT"
	"Depots"
	{
		"4850901" "depot_build_4850901.vdf"
	}
}
EOF

echo "Demo App ID : 4850900"
echo "Depot ID    : 4850901"
echo "Content     : $CONTENT"
echo "Build logs  : $OUTPUT"
echo ""
echo "You will be prompted to log in with your Steamworks partner account."
echo ""

cd "$OUTPUT"
if [[ $# -ge 1 ]]; then
	exec "$STEAMCMD" +login "$1" +run_app_build "$(pwd)/app_build_4850900.vdf" +quit
else
	exec "$STEAMCMD" +login +run_app_build "$(pwd)/app_build_4850900.vdf" +quit
fi
