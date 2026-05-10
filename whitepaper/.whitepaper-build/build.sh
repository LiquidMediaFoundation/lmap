#!/usr/bin/env bash
# Reproducible PDF build for the LMAP whitepaper.
# Source of truth: ../whitepaper.md (committed). Output: ../whitepaper.pdf.
#
# Requirements:
#   - pandoc (brew install pandoc)
#   - Google Chrome (headless rendering)
#
# Usage:
#   ./whitepaper/.whitepaper-build/build.sh

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STATIC="$(cd "$HERE/.." && pwd)"
SRC="$STATIC/whitepaper.md"
CSS="$HERE/whitepaper.css"
HTML="$(mktemp -t whitepaper.XXXXXX).html"
OUT="$STATIC/whitepaper.pdf"

PANDOC="${PANDOC:-/opt/homebrew/bin/pandoc}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

"$PANDOC" "$SRC" \
  --standalone \
  --css="$CSS" \
  --embed-resources \
  --metadata title="LMAP — Whitepaper v2.2" \
  -o "$HTML"

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --virtual-time-budget=10000 \
  --print-to-pdf="$OUT" \
  "file://$HTML"

rm -f "$HTML"
echo "Built: $OUT"
