#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${AASE_RELEASE_VERSION:-v0.1.0-sprint1}"
DIST="${ROOT}/dist"
OUT="${DIST}/tcwa3-stats-tracker-${VERSION}"
ZIP="${DIST}/tcwa3-stats-tracker-${VERSION}.zip"
SERVERMOD="${OUT}/@tcwa3_stats_tracker_server"
ADDON="${OUT}/@tcwa3_stats_tracker"
BUILD_DIR="${AASE_EXTENSION_BUILD_DIR:-${ROOT}/build/extension-linux}"

export HEMTT_BI_TOOLS="${HEMTT_BI_TOOLS:-/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/}"

echo "Working tree status:"
git -C "$ROOT" status --short

rm -rf "$OUT" "$ZIP"
mkdir -p "$SERVERMOD" "$ADDON/addons" "$ADDON/keys"

hemtt check
hemtt release --no-archive

cmake -S "$ROOT/extension" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$BUILD_DIR" --config RelWithDebInfo
ctest --test-dir "$BUILD_DIR" --output-on-failure

LINUX_SO="${BUILD_DIR}/tcwa3_stats_tracker.so"
LINUX_X64_SO="${BUILD_DIR}/tcwa3_stats_tracker_x64.so"
WIN_DLL="$(find "$ROOT/build" -name 'tcwa3_stats_tracker_x64.dll' -print -quit || true)"

if [[ ! -f "$LINUX_SO" ]]; then
  echo "Missing Linux extension artifact: $LINUX_SO" >&2
  exit 1
fi

if [[ ! -f "$LINUX_X64_SO" ]]; then
  echo "Missing Linux x64 extension artifact: $LINUX_X64_SO" >&2
  exit 1
fi

find "$ROOT/.hemttout/release/addons" -maxdepth 1 -type f \( -name '*.pbo' -o -name '*.bisign' \) -exec cp {} "$ADDON/addons/" \;
find "$ROOT/.hemttout/release/keys" -maxdepth 1 -type f -name '*.bikey' -exec cp {} "$ADDON/keys/" \;
cp "$ROOT/.hemttout/release/mod.cpp" "$ROOT/.hemttout/release/meta.cpp" "$ADDON/"

cp "$LINUX_SO" "$SERVERMOD/"
cp "$LINUX_X64_SO" "$SERVERMOD/"
if [[ -n "$WIN_DLL" ]]; then
  cp "$WIN_DLL" "$SERVERMOD/"
else
  echo "Windows DLL not found locally; continuing with Linux server artifacts only." >&2
fi

cp "$ROOT/servermod/arma_attendance.example.toml" "$SERVERMOD/"
cp "$ROOT/servermod/tcwa3_stats_tracker.example.toml" "$SERVERMOD/"
cp "$ROOT/servermod/mod.cpp" "$SERVERMOD/"
cp "$ROOT/servermod/meta.cpp" "$SERVERMOD/"
cp "$ROOT/servermod/README-server-install.md" "$SERVERMOD/"
cp "$ROOT/servermod/README-server-install.txt" "$SERVERMOD/"
cp "$ROOT/servermod/README-workshop-server-extension.md" "$SERVERMOD/"

python3 "$ROOT/tools/audit_workshop_package.py" "$SERVERMOD"

(
  cd "$OUT"
  find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -0 sha256sum > "$SERVERMOD/checksums.sha256"
)

(
  cd "$DIST"
  zip -r "$(basename "$ZIP")" "$(basename "$OUT")"
)

echo "Package created: $ZIP"
