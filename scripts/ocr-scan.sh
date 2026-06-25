#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Copyright (c) 2026 Hashim Abdulaziz
#  https://www.linkedin.com/in/hashim-abdulaziz/
#  They call me Hashing — feel free to use this, just keep my name in the code.
# ─────────────────────────────────────────────────────────────
# OCR scanner: snip any screen area → extract text → copy to clipboard
#
# Quality tricks:
#   1. Auto-detects dark/light background → negates dark ones
#   2. Upscales to ~300 DPI (screen is 96 DPI; tesseract needs 300)
#   3. Normalises contrast for faded/low-contrast text
#   4. Tries PSM 6 (block) and PSM 3 (auto), keeps the longer result
#   5. Strips blank lines and trailing whitespace from output

BASE="/tmp/ocr_$(date +%s)"
RAW="${BASE}_raw.png"
PRE="${BASE}_pre.png"

cleanup() { rm -f "$RAW" "$PRE"; }
trap cleanup EXIT

# ── 1. Capture ─────────────────────────────────────────────────────────────
if ! grim -g "$(slurp -d)" "$RAW" 2>/dev/null; then
    exit 0  # user cancelled
fi

# ── 2. Preprocess ──────────────────────────────────────────────────────────
# Detect mean brightness: if image is mostly dark, negate it first
# (tesseract expects dark text on light background)
MEAN=$(magick "$RAW" -colorspace Gray -format "%[fx:mean]" info: 2>/dev/null)
IS_DARK=$(awk -v m="$MEAN" 'BEGIN{print (m < 0.5) ? "1" : "0"}')

if [ "$IS_DARK" = "1" ]; then
    magick "$RAW" -negate -scale 300% -colorspace Gray -normalize -unsharp 0x0.5 "$PRE" 2>/dev/null
else
    magick "$RAW"         -scale 300% -colorspace Gray -normalize -unsharp 0x0.5 "$PRE" 2>/dev/null
fi

# ── 3. OCR — try PSM 6 (paragraph block) and PSM 3 (auto), keep best ──────
run_ocr() {
    tesseract "$PRE" stdout --oem 3 --psm "$1" -l eng+ara 2>/dev/null \
        | sed '/^[[:space:]]*$/d' \
        | sed 's/[[:space:]]*$//'
}

OUT6=$(run_ocr 6)
OUT3=$(run_ocr 3)

# Pick whichever returned more non-whitespace characters
CHARS6=$(printf '%s' "$OUT6" | tr -cd '[:alnum:]' | wc -c)
CHARS3=$(printf '%s' "$OUT3" | tr -cd '[:alnum:]' | wc -c)

if [ "$CHARS6" -ge "$CHARS3" ]; then
    RESULT="$OUT6"
else
    RESULT="$OUT3"
fi

# ── 4. Output ──────────────────────────────────────────────────────────────
if [ -z "$RESULT" ]; then
    notify-send -t 3000 -i dialog-warning "OCR Scanner" \
        "No text detected.\nTry selecting with a small margin around the text."
    exit 0
fi

printf '%s' "$RESULT" | wl-copy

# Show first ~80 chars in notification as preview
PREVIEW=$(printf '%s' "$RESULT" | head -3 | cut -c1-80)
LINE_COUNT=$(printf '%s' "$RESULT" | wc -l)
notify-send -t 4000 -i edit-copy "OCR — $LINE_COUNT line(s) copied" "$PREVIEW…"
