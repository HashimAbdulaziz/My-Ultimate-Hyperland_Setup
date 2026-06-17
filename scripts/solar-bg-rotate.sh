#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  SOLAR ZEN ROTATION DAEMON                                      ║
# ║  Runs in background while Zen Mode is active.                   ║
# ║  Every 25 min: switches panels to astroterm (Cairo sky)          ║
# ║  After 5 min:  switches back to solcl (solar system)             ║
# ║  Killed by solar-zen-toggle.sh on SUPER+I off.                  ║
# ╚══════════════════════════════════════════════════════════════════╝

SOLCL_BIN="/home/hashim/go/bin/solcl"
ASTRO_BIN="$HOME/.local/bin/astroterm"

SOLCL_DURATION=1500   # 25 minutes
ASTRO_DURATION=300    # 5 minutes

# Cairo, Egypt
LATITUDE=30.0
LONGITUDE=31.2

# ── Shared kitty panel options (passed as -o overrides) ──────────
KITTY_OPTS=(
    -o "allow_remote_control=no"
    -o "background_opacity=0.95"
    -o "window_padding_width=0"
    -o "hide_window_decorations=yes"
    -o "font_size=18"
    -o "term=xterm-256color"
    -o "cursor_shape=block"
    -o "cursor_blink_interval=0"
)

# ── Get active monitor names ──────────────────────────────────────
_get_monitors() {
    hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
try:
    for m in json.load(sys.stdin):
        if not m.get('disabled', False):
            print(m['name'])
except: pass
" 2>/dev/null
}

# ── Kill existing solar background panels only ────────────────────
_kill_panels() {
    pkill -f "kitten panel.*--edge=background" 2>/dev/null || true
    pkill -f "kitty.*panel.*background"        2>/dev/null || true
    pkill -f "$SOLCL_BIN"                      2>/dev/null || true
    pkill -f "astroterm"                        2>/dev/null || true
    sleep 0.6
}

# ── Launch panels with a given command ───────────────────────────
_launch_panels() {
    local cmd=("$@")
    local monitors
    monitors=$(_get_monitors)
    [[ -z "$monitors" ]] && monitors="DP-3"

    while IFS= read -r monitor; do
        [[ -z "$monitor" ]] && continue
        kitty +kitten panel \
            --edge=background \
            --output-name="$monitor" \
            "${KITTY_OPTS[@]}" \
            "${cmd[@]}" &
        disown
    done <<< "$monitors"
    sleep 0.8
}

# ── Main rotation loop ────────────────────────────────────────────
# Initial panels are already launched by solar-zen-toggle.sh.
# This daemon just handles the timed switch.
while true; do
    # Wait 25 minutes on solcl
    sleep "$SOLCL_DURATION"

    # Check if we were killed while sleeping (state file gone = zen is off)
    [[ ! -f /tmp/solar_state ]] && exit 0
    [[ "$(cat /tmp/solar_state 2>/dev/null)" != "on" ]] && exit 0

    # Switch to astroterm
    _kill_panels
    if [[ -x "$ASTRO_BIN" ]]; then
        _launch_panels "$ASTRO_BIN" \
            --color \
            --unicode \
            --braille \
            --constellations \
            --grid \
            --metadata \
            --latitude="$LATITUDE" \
            --longitude="$LONGITUDE" \
            --threshold=5.0 \
            --label-thresh=1.5 \
            --fps=12
    fi

    # Wait 5 minutes on astroterm
    sleep "$ASTRO_DURATION"

    [[ ! -f /tmp/solar_state ]] && exit 0
    [[ "$(cat /tmp/solar_state 2>/dev/null)" != "on" ]] && exit 0

    # Switch back to solcl
    _kill_panels
    [[ -x "$SOLCL_BIN" ]] && _launch_panels "$SOLCL_BIN"
done
