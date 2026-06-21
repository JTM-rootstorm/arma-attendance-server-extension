#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${AASE_EXTENSION_BUILD_DIR:-${ROOT}/build/extension-linux}"
OUT_ROOT="${TCWA3_SERVER_WORKSHOP_OUT:-${ROOT}/dist/workshop-server-extension}"
SERVERMOD="${OUT_ROOT}/@tcwa3_stats_tracker_server"

LINUX_SO="${TCWA3_LINUX_SO:-${BUILD_DIR}/tcwa3_stats_tracker.so}"
LINUX_X64_SO="${TCWA3_LINUX_X64_SO:-${BUILD_DIR}/tcwa3_stats_tracker_x64.so}"
WIN_DLL="${TCWA3_WIN_DLL:-}"

if [[ -z "$WIN_DLL" ]]; then
  WIN_DLL="$(find "$ROOT/build" "$ROOT/artifacts" -name 'tcwa3_stats_tracker_x64.dll' -print -quit 2>/dev/null || true)"
fi

rm -rf "$SERVERMOD"
mkdir -p "$SERVERMOD/addons" "$SERVERMOD/keys"

(
  cd "$ROOT"
  rm -rf .hemttout
  hemtt release --no-archive
)

(
  cd "$ROOT/servermod"
  rm -rf .hemttout
  hemtt release --no-archive
)

if [[ ! -f "$LINUX_SO" ]]; then
  echo "Missing Linux extension artifact: $LINUX_SO" >&2
  exit 1
fi

if [[ ! -f "$LINUX_X64_SO" ]]; then
  echo "Missing Linux x64 extension artifact: $LINUX_X64_SO" >&2
  exit 1
fi

cp "$LINUX_SO" "$SERVERMOD/"
cp "$LINUX_X64_SO" "$SERVERMOD/"

find "$ROOT/.hemttout/release/addons" -maxdepth 1 -type f \( -name '*.pbo' -o -name '*.bisign' \) -exec cp {} "$SERVERMOD/addons/" \;
find "$ROOT/.hemttout/release/keys" -maxdepth 1 -type f -name '*.bikey' -exec cp {} "$SERVERMOD/keys/" \;
find "$ROOT/servermod/.hemttout/release/addons" -maxdepth 1 -type f \( -name '*.pbo' -o -name '*.bisign' \) -exec cp {} "$SERVERMOD/addons/" \;
find "$ROOT/servermod/.hemttout/release/keys" -maxdepth 1 -type f -name '*.bikey' -exec cp {} "$SERVERMOD/keys/" \;

if [[ -n "$WIN_DLL" && -f "$WIN_DLL" ]]; then
  cp "$WIN_DLL" "$SERVERMOD/"
else
  echo "Windows DLL not found; assembled package will contain Linux server artifacts only." >&2
fi

cp "$ROOT/servermod/arma_attendance.example.toml" "$SERVERMOD/"
cp "$ROOT/servermod/tcwa3_stats_tracker.example.toml" "$SERVERMOD/"
cp "$ROOT/servermod/mod.cpp" "$SERVERMOD/"
cp "$ROOT/servermod/meta.cpp" "$SERVERMOD/"
cp "$ROOT/servermod/README-server-install.md" "$SERVERMOD/"
cp "$ROOT/servermod/README-workshop-server-extension.md" "$SERVERMOD/"

(
  cd "$SERVERMOD"
  find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -0 sha256sum > checksums.sha256
)

python3 "$ROOT/tools/audit_workshop_package.py" "$SERVERMOD"

echo "Server extension Workshop package assembled: $SERVERMOD"
