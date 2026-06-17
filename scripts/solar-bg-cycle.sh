#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  SOLAR ZEN BACKGROUND CYCLE                                     ║
# ║  Alternates between solcl (solar system) and astroterm          ║
# ║  (live star map) on a configurable timer.                        ║
# ║                                                                  ║
# ║  Schedule: 25 min solcl → 5 min astroterm → repeat              ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Critical: fix the panel kitten's broken environment ───────────
# kitty +kitten panel launches with TERM=dumb and no go/bin in PATH.
# Both solcl and astroterm abort when TERM is not a real terminal.
export TERM=xterm-256color
export COLORTERM=truecolor
export PATH="/home/hashim/go/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# ── Config ────────────────────────────────────────────────────────
SOLCL_BIN="/home/hashim/go/bin/solcl"
ASTRO_BIN="$HOME/.local/bin/astroterm"

SOLCL_DURATION=1500   # 25 minutes (primary view)
ASTRO_DURATION=300    # 5 minutes  (interlude view)

# Observer coordinates — Cairo, Egypt
LATITUDE=30.0
LONGITUDE=31.2

# ── Helpers ──────────────────────────────────────────────────────
_clear_screen() {
    printf '\033[2J\033[H'
}

_run_solcl() {
    _clear_screen
    if [[ -x "$SOLCL_BIN" ]]; then
        timeout "$SOLCL_DURATION" "$SOLCL_BIN" 2>/dev/null
    else
        printf '\n\n  [solcl not found at %s]\n' "$SOLCL_BIN"
        sleep "$SOLCL_DURATION"
    fi
}

_run_astroterm() {
    _clear_screen
    if [[ -x "$ASTRO_BIN" ]]; then
        timeout "$ASTRO_DURATION" "$ASTRO_BIN" \
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
            --fps=12 \
            2>/dev/null
    else
        printf '\n\n  [astroterm not found at %s]\n' "$ASTRO_BIN"
        sleep "$ASTRO_DURATION"
    fi
}

# ── Main loop ─────────────────────────────────────────────────────
while true; do
    _run_solcl
    _run_astroterm
done
