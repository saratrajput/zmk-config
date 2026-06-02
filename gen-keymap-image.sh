#!/usr/bin/env bash
# Regenerate keymap.png (and keymap.svg) from config/cradio.keymap.
# Output is a 2x2 grid: default, right (top row), left, tri (bottom row).
# The Hammerspoon Cmd+Alt+/ overlay reads keymap.png directly, so no reload
# is needed after running this.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
keymap_bin="${KEYMAP_BIN:-$HOME/.venvs/keymap-drawer/bin/keymap}"

keymap_file="$repo/config/cradio.keymap"
yaml="$repo/keymap.yaml"
svg="$repo/keymap.svg"
png="$repo/keymap.png"

if [ ! -x "$keymap_bin" ]; then
  echo "keymap-drawer not found at $keymap_bin" >&2
  echo "Install: python3.13 -m venv ~/.venvs/keymap-drawer && ~/.venvs/keymap-drawer/bin/pip install keymap-drawer" >&2
  exit 1
fi
if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "rsvg-convert not found. Install with: brew install librsvg" >&2
  exit 1
fi

# 1. Parse the ZMK keymap into keymap-drawer's YAML representation.
"$keymap_bin" parse -z "$keymap_file" > "$yaml"

# 2. Lay the four layers out in two columns instead of a vertical strip.
printf 'draw_config:\n  n_columns: 2\n' >> "$yaml"

# 3. Draw the SVG, then rasterize to PNG (rsvg-convert renders keymap-drawer's
#    CSS correctly; cairosvg leaves black artifacts).
"$keymap_bin" draw "$yaml" > "$svg"
rsvg-convert -z 2 -b white "$svg" -o "$png"

echo "Wrote $png ($(file -b "$png"))"
