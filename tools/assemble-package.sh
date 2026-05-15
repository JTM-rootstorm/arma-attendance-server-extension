#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/dist/arma-attendance-phase0"
SERVERMOD="${OUT}/@arma_attendance_server"
ADDON="${OUT}/@arma_attendance"

export HEMTT_BI_TOOLS="${HEMTT_BI_TOOLS:-/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/}"
AASE_BIKEY_DIR="${AASE_BIKEY_DIR:-$HOME/Documents/Programming/bikey}"

rm -rf "$OUT"
mkdir -p "$SERVERMOD" "$ADDON"

hemtt check
hemtt build

LINUX_SO="$(find "$ROOT/build" -name 'arma_attendance.so' -print -quit || true)"
WIN_DLL="$(find "$ROOT/build" -name 'arma_attendance_x64.dll' -print -quit || true)"

if [[ -z "$LINUX_SO" ]]; then
  echo "Missing Linux extension artifact: arma_attendance.so" >&2
  exit 1
fi

if [[ -z "$WIN_DLL" ]]; then
  echo "Missing Windows extension artifact: arma_attendance_x64.dll" >&2
  exit 1
fi

cp "$LINUX_SO" "$SERVERMOD/"
cp "$WIN_DLL" "$SERVERMOD/"
cp "$ROOT/servermod/arma_attendance.example.toml" "$SERVERMOD/"
cp "$ROOT/servermod/README-server-install.txt" "$SERVERMOD/"
cp "$ROOT/mod.cpp" "$ADDON/"
cp "$ROOT/meta.cpp" "$ADDON/"

PUBLIC_KEY="$(find "$AASE_BIKEY_DIR" -maxdepth 1 -name '*.bikey' -print -quit || true)"
if [[ -n "$PUBLIC_KEY" ]]; then
  mkdir -p "$ADDON/keys"
  cp "$PUBLIC_KEY" "$ADDON/keys/"
fi

if find "$OUT" \( -name '*.biprivatekey' -o -name '*.hemttprivatekey' -o -name 'arma_attendance.toml' -o -name '.env' -o -name '.env.*' \) | grep -q .; then
  echo "Refusing to package private keys or real config." >&2
  exit 1
fi

(cd "$OUT/.." && zip -r "arma-attendance-phase0.zip" "$(basename "$OUT")")

echo "Package created: $ROOT/dist/arma-attendance-phase0.zip"
