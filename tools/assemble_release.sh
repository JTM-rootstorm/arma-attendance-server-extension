#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${AASE_RELEASE_VERSION:-v0.1.0-sprint1}"
DIST="${ROOT}/dist"
OUT="${DIST}/arma-attendance-extension-${VERSION}"
ZIP="${DIST}/arma-attendance-extension-${VERSION}.zip"
SERVERMOD="${OUT}/@arma_attendance_server"
ADDON="${OUT}/@arma_attendance"
BUILD_DIR="${AASE_EXTENSION_BUILD_DIR:-${ROOT}/build/extension-linux}"
AASE_BIKEY_DIR="${AASE_BIKEY_DIR:-$HOME/Documents/Programming/bikey}"

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

LINUX_SO="${BUILD_DIR}/arma_attendance.so"
LINUX_X64_SO="${BUILD_DIR}/arma_attendance_x64.so"
WIN_DLL="$(find "$ROOT/build" -name 'arma_attendance_x64.dll' -print -quit || true)"

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

find "$AASE_BIKEY_DIR" -maxdepth 1 -type f -name '*.bikey' -exec cp {} "$ADDON/keys/" \;

cp "$LINUX_SO" "$SERVERMOD/"
cp "$LINUX_X64_SO" "$SERVERMOD/"
if [[ -n "$WIN_DLL" ]]; then
  cp "$WIN_DLL" "$SERVERMOD/"
else
  echo "Windows DLL not found locally; continuing with Linux server artifacts only." >&2
fi

cp "$ROOT/servermod/arma_attendance.example.toml" "$SERVERMOD/"
cp "$ROOT/servermod/README-server-install.md" "$SERVERMOD/"
cp "$ROOT/servermod/README-server-install.txt" "$SERVERMOD/"

if find "$OUT" \( -name '*.biprivatekey' -o -name '*.hemttprivatekey' -o -name 'arma_attendance.toml' -o -name '.env' -o -name '.env.*' \) | grep -q .; then
  echo "Refusing to package private keys or real config." >&2
  exit 1
fi

(
  cd "$OUT"
  find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -0 sha256sum > "$SERVERMOD/checksums.sha256"
)

(
  cd "$DIST"
  zip -r "$(basename "$ZIP")" "$(basename "$OUT")"
)

echo "Package created: $ZIP"
