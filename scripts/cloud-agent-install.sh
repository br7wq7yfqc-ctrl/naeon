#!/usr/bin/env bash
# NAEON Cloud Agent bootstrap: install the Godot 4.3 toolchain + Python pipeline
# dependencies, then import the Godot project so res:// assets are cached.
# Must stay idempotent: it can run repeatedly and against cached/snapshot state.
set -euo pipefail

GODOT_VERSION="4.3"
GODOT_BIN="/usr/local/bin/godot"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[install] system libraries for Godot headless + asset pipeline"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
  unzip ca-certificates curl \
  libgl1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libxext6 libxrender1 libfontconfig1 libasound2t64 libpulse0 \
  python3-requests

echo "[install] Godot ${GODOT_VERSION} (matches .github/workflows/ci.yml)"
if command -v godot >/dev/null 2>&1 && godot --version 2>/dev/null | grep -q "^${GODOT_VERSION}\."; then
  echo "[install] Godot already present: $(godot --version)"
else
  tmp="$(mktemp -d)"
  url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
  echo "[install] downloading ${url}"
  curl -fsSL -o "$tmp/godot.zip" "$url"
  unzip -o -q "$tmp/godot.zip" -d "$tmp"
  sudo install -m 0755 "$tmp/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$GODOT_BIN"
  rm -rf "$tmp"
  echo "[install] installed $(godot --version)"
fi

echo "[install] importing Godot project (generates godot/.godot cache)"
# --editor import triggers resource import; --quit-after bounds the run. Parse
# errors in game scripts are surfaced by CI, not by this bootstrap, so never fail.
godot --headless --editor --quit-after 60 --path "$REPO_ROOT/godot" \
  >/tmp/naeon_godot_import.log 2>&1 || true
echo "[install] import finished; log at /tmp/naeon_godot_import.log"

echo "[install] done"
