#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Copyright (c) 2026 Hashim Abdulaziz
#  https://www.linkedin.com/in/hashim-abdulaziz/
#  They call me Hashing — feel free to use this, just keep my name in the code.
# ─────────────────────────────────────────────────────────────
# QR code scanner: snip area → decode → resolve redirects → open URL or copy

BASE="/tmp/qr_$(date +%s)"
RAW="${BASE}_raw.png"
NEG="${BASE}_neg.png"

cleanup() { rm -f "$RAW" "$NEG"; }
trap cleanup EXIT

# Capture selected area
if ! grim -g "$(slurp)" "$RAW" 2>/dev/null; then
    exit 0  # user cancelled slurp
fi

decode() { zbarimg --raw --quiet "$1" 2>/dev/null | head -1; }

# Try normal first, then negate (for white-on-dark QR codes)
QR_RESULT=$(decode "$RAW")
if [ -z "$QR_RESULT" ]; then
    magick "$RAW" -negate "$NEG" 2>/dev/null
    QR_RESULT=$(decode "$NEG")
fi

if [ -z "$QR_RESULT" ]; then
    notify-send -t 3000 -i dialog-warning "QR Scanner" \
        "No QR code detected.\nInclude a border of white space around the code."
    exit 0
fi

QR_RESULT="${QR_RESULT%$'\n'}"

# ── URL: resolve through ad/redirect pages before opening ─────────────────
open_url() {
    local url="$1"

    # Follow HTTP-level redirects first
    local effective
    effective=$(curl -sIL --max-redirs 10 --connect-timeout 5 \
                     -w '%{url_effective}' -o /dev/null "$url" 2>/dev/null)

    # If we're stuck on a known ad-injector (me-qr, qr.io, etc.), parse the HTML
    # and grab the "skip" link — the actual destination
    if [[ "$effective" =~ me-qr\.com|qr1\.me-qr\.com|qr\.io ]]; then
        local real
        real=$(curl -sL --connect-timeout 5 "$url" 2>/dev/null \
               | grep -oP 'href="\K(https?://[^"]+)(?=")' \
               | grep -vE 'me-qr\.com|me-ticket\.com|me-qr-scanner\.com' \
               | head -1)
        [ -n "$real" ] && url="$real"
    elif [[ "$effective" =~ ^https?:// ]]; then
        url="$effective"
    fi

    notify-send -t 3000 -i web-browser "QR Scanned" "Opening: $url"
    ~/.local/bin/google-chrome "$url" &
}

if [[ "$QR_RESULT" =~ ^https?:// ]]; then
    open_url "$QR_RESULT"
else
    printf '%s' "$QR_RESULT" | wl-copy
    notify-send -t 4000 -i edit-copy "QR Scanned" "Copied to clipboard:\n$QR_RESULT"
fi
