#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  SOLAR ZEN MODE TOGGLE v1.1 — Layer Shell Fix                   ║
# ║  Toggles between Neon Cyberpunk and Zen/Solar aesthetic          ║
# ║  Bound to: SUPER + I                                            ║
# ║                                                                  ║
# ║  On  → Live ASCII solar system bg + minimal grey terminal        ║
# ║  Off → Full Cyberpunk neon restored                              ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────
SOLCL_BIN="/home/hashim/go/bin/solcl"
CYCLE_SCRIPT="$HOME/.scripts/solar-bg-cycle.sh"
ASTRO_BIN="$HOME/.local/bin/astroterm"
STATE_FILE="/tmp/solar_state"
LOCK_FILE="/tmp/solar_zen.lock"
LOG_FILE="/tmp/solar-zen.log"

# ── Kitty theme dirs (mirrors the theme-swapper pattern) ─────────────
KITTY_BASE="$HOME/.config/kitty/kitty-base.conf"
KITTY_ZEN_THEME="$HOME/.config/kitty/solar-zen-theme.conf"
KITTY_CYBER_THEME="$HOME/.config/themes/cyberpunk/kitty-theme.conf"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"

# ── Cyberpunk border colors (from current-theme.conf) ─────────────────
CYBER_BORDER_ACTIVE="rgba(00e5ffee) rgba(ff003cee) 45deg"
CYBER_BORDER_INACTIVE="rgba(1a1a26cc)"
CYBER_GROUP_ACTIVE="rgba(00e5ffee) rgba(ff003cee) 45deg"
CYBER_GROUP_INACTIVE="rgba(1a1a26cc)"
CYBER_GROUPBAR_ACTIVE="rgba(3a1f5dff)"
CYBER_GROUPBAR_INACTIVE="rgba(1a1a26cc)"

# ── Zen border colors ─────────────────────────────────────────────────
ZEN_BORDER_ACTIVE="rgba(4a4a4aee) rgba(2a2a2aee) 45deg"
ZEN_BORDER_INACTIVE="rgba(1c1c1ccc)"
ZEN_GROUP_ACTIVE="rgba(3c3c3cee)"
ZEN_GROUP_INACTIVE="rgba(1c1c1ccc)"
ZEN_GROUPBAR_ACTIVE="rgba(2a2a2aff)"
ZEN_GROUPBAR_INACTIVE="rgba(141414cc)"

# ── Logging ──────────────────────────────────────────────────────────
log() {
    local ts
    ts=$(date '+%H:%M:%S')
    echo "[$ts] $*" | tee -a "$LOG_FILE"
}

# ── Concurrency lock ─────────────────────────────────────────────────
acquire_lock() {
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        local age
        age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
        if (( age > 20 )); then
            log "⚠ Stale lock ($age s), reclaiming..."
            rmdir "$LOCK_FILE" 2>/dev/null || true
            mkdir "$LOCK_FILE"
        else
            log "✗ Solar toggle already running. Aborting."
            notify-send -u low -t 2000 "☀ Solar Zen" "Toggle already in progress..." 2>/dev/null || true
            exit 0
        fi
    fi
    trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT
}

# ── Read current state ───────────────────────────────────────────────
read_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "off"
}

# ══════════════════════════════════════════════════════════════════════
#  ENABLE ZEN MODE
# ══════════════════════════════════════════════════════════════════════
enable_zen() {
    log "▸ Enabling Solar Zen Mode..."

    notify-send -u low -t 3000 -i dialog-information \
        "☀ Solar Zen Mode" "Entering the void... breathe." 2>/dev/null || true

    # ── 1. Smooth border fade: animate from neon → grey ──────────────
    # Hyprland doesn't have native tween on keyword injection, so we
    # step through intermediate colors over ~600ms for a felt transition.
    log "  → Fading borders to zen grey..."
    _fade_borders_to_zen

    # ── 2. Swap Hyprland animations to slower/softer ──────────────────
    hyprctl keyword animations:animation "windows,   1, 5, default, popin 95%"
    hyprctl keyword animations:animation "windowsOut,1, 4, default, popin 95%"
    hyprctl keyword animations:animation "border,    1, 6, default"
    hyprctl keyword animations:animation "fade,      1, 5, default"
    log "  ✓ Hyprland animations slowed"

    # ── 3. Switch Kitty terminal colors (hot-reload all sessions) ─────
    _apply_kitty_zen

    # ── 4. Launch solcl inside a solar-bg Kitty instance ─────────────
    _launch_solar_bg

    # ── 5. Kill hyprpaper — the panel kitten REPLACES it at the layer level ──
    # `kitty +kitten panel --edge=background` speaks wlr-layer-shell and
    # occupies the compositor BACKGROUND layer, physically below ALL windows.
    # hyprpaper also occupies the background layer, so we must free it first.
    killall hyprpaper 2>/dev/null || true
    log "  ✓ Hyprpaper suspended (panel kitten owns the background layer)"

    echo "on" > "$STATE_FILE"
    log "  ✓ State saved: ON"

    notify-send -u normal -t 4000 -i dialog-information \
        "☀ Solar Zen Mode" "The solar system is live. Find your orbit." 2>/dev/null || true

    log "══ Solar Zen Mode ACTIVE ══"
}

# ══════════════════════════════════════════════════════════════════════
#  DISABLE ZEN MODE
# ══════════════════════════════════════════════════════════════════════
disable_zen() {
    log "▸ Disabling Solar Zen Mode..."

    notify-send -u low -t 3000 -i dialog-information \
        "⚡ Cyberpunk Restored" "Rebooting the neon grid..." 2>/dev/null || true

    # ── 1. Kill the solar background terminal ─────────────────────────
    _kill_solar_bg

    # ── 2. Fade borders back to Cyberpunk neon ───────────────────────
    log "  → Fading borders back to neon..."
    _fade_borders_to_cyber

    # ── 3. Restore Hyprland animation speeds ─────────────────────────
    hyprctl keyword animations:animation "windows,   1, 3, snappy, popin 90%"
    hyprctl keyword animations:animation "windowsOut,1, 2, snappy, popin 90%"
    hyprctl keyword animations:animation "border,    1, 2, snappy"
    hyprctl keyword animations:animation "fade,      1, 2, snappy"
    log "  ✓ Hyprland animations restored"

    # ── 4. Restore Kitty colors (cyberpunk) ───────────────────────────
    _apply_kitty_cyber

    # ── 5. Restart hyprpaper to restore wallpaper ─────────────────────
    nohup hyprpaper >/dev/null 2>&1 &
    disown
    log "  ✓ Hyprpaper restarted"

    echo "off" > "$STATE_FILE"
    log "  ✓ State saved: OFF"

    notify-send -u normal -t 4000 -i dialog-information \
        "⚡ CYBERPUNK" "Neon aesthetic fully restored. Welcome back, Netrunner." 2>/dev/null || true

    log "══ Solar Zen Mode INACTIVE ══"
}

# ══════════════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════════════

# Stepped border fade: Neon → Zen grey (~600ms, 3 steps)
_fade_borders_to_zen() {
    # Step 1 — muted neon (desaturate ~30%)
    hyprctl keyword general:col.active_border   "rgba(00aaaa99) rgba(880022aa) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(1a1a26bb)"
    sleep 0.2
    # Step 2 — near grey
    hyprctl keyword general:col.active_border   "rgba(666666cc) rgba(404040cc) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(1e1e1ebb)"
    sleep 0.2
    # Step 3 — final zen grey
    hyprctl keyword general:col.active_border   "$ZEN_BORDER_ACTIVE"
    hyprctl keyword general:col.inactive_border "$ZEN_BORDER_INACTIVE"
    # Groups
    hyprctl keyword group:col.border_active     "$ZEN_GROUP_ACTIVE"
    hyprctl keyword group:col.border_inactive   "$ZEN_GROUP_INACTIVE"
    hyprctl keyword group:groupbar:col.active   "$ZEN_GROUPBAR_ACTIVE"
    hyprctl keyword group:groupbar:col.inactive "$ZEN_GROUPBAR_INACTIVE"
}

# Stepped border fade: Zen grey → Neon (~600ms, 3 steps)
_fade_borders_to_cyber() {
    # Step 1 — muted neon
    hyprctl keyword general:col.active_border   "rgba(006677aa) rgba(660022aa) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(1a1a26bb)"
    sleep 0.2
    # Step 2 — brightening neon
    hyprctl keyword general:col.active_border   "rgba(00b8cccc) rgba(cc002ecc) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(1a1a26cc)"
    sleep 0.2
    # Step 3 — full cyberpunk
    hyprctl keyword general:col.active_border   "$CYBER_BORDER_ACTIVE"
    hyprctl keyword general:col.inactive_border "$CYBER_BORDER_INACTIVE"
    # Groups
    hyprctl keyword group:col.border_active     "$CYBER_GROUP_ACTIVE"
    hyprctl keyword group:col.border_inactive   "$CYBER_GROUP_INACTIVE"
    hyprctl keyword group:groupbar:col.active   "$CYBER_GROUPBAR_ACTIVE"
    hyprctl keyword group:groupbar:col.inactive "$CYBER_GROUPBAR_INACTIVE"
}

# Assemble + hot-reload Kitty with zen theme
_apply_kitty_zen() {
    if [[ -f "$KITTY_BASE" && -f "$KITTY_ZEN_THEME" ]]; then
        cat "$KITTY_BASE" "$KITTY_ZEN_THEME" > "$KITTY_CONF"
        log "  ✓ Kitty conf assembled (zen)"
    else
        log "  ⚠ Kitty zen theme file missing: $KITTY_ZEN_THEME"
    fi
    # Hot-reload ALL open Kitty instances — no session lost
    kitty @ --to unix:/tmp/mykitty set-colors -a all "$KITTY_ZEN_THEME" 2>/dev/null || \
        kitty @ set-colors -a all "$KITTY_ZEN_THEME" 2>/dev/null || \
        killall -SIGUSR1 kitty 2>/dev/null || true
    log "  ✓ Kitty sessions hot-reloaded (zen)"
}

# Assemble + hot-reload Kitty with cyberpunk theme
_apply_kitty_cyber() {
    if [[ -f "$KITTY_BASE" && -f "$KITTY_CYBER_THEME" ]]; then
        cat "$KITTY_BASE" "$KITTY_CYBER_THEME" > "$KITTY_CONF"
        log "  ✓ Kitty conf assembled (cyberpunk)"
    else
        log "  ⚠ Kitty cyberpunk theme file missing: $KITTY_CYBER_THEME"
    fi
    # Hot-reload ALL open Kitty instances
    kitty @ --to unix:/tmp/mykitty set-colors -a all "$KITTY_CYBER_THEME" 2>/dev/null || \
        kitty @ set-colors -a all "$KITTY_CYBER_THEME" 2>/dev/null || \
        killall -SIGUSR1 kitty 2>/dev/null || true
    log "  ✓ Kitty sessions hot-reloaded (cyberpunk)"
}

# ── Shared kitty panel options ────────────────────────────────────
# -o term=xterm-256color: makes kitty advertise proper TERM to child
# processes (solcl/astroterm use TERM to detect color support).
# Without this, panel kitten defaults to TERM=xterm-kitty which some
# Go terminal libraries don't recognise → blank screen.
KITTY_PANEL_OPTS=(
    -o "allow_remote_control=no"
    -o "background_opacity=0.95"
    -o "window_padding_width=0"
    -o "hide_window_decorations=yes"
    -o "font_size=18"
    -o "term=xterm-256color"
    -o "cursor_blink_interval=0"
)

# ── Discover active monitors ──────────────────────────────────────
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

# ── Launch solar background via wlr-layer-shell panel kitten ─────
# Each panel runs solcl DIRECTLY — no wrapper script.
# TUI apps (tcell/ncurses) need to be the direct child of the pty.
_launch_solar_bg() {
    _kill_solar_bg

    if [[ ! -x "$SOLCL_BIN" ]]; then
        log "  ⚠ solcl not found at $SOLCL_BIN"
        notify-send -u critical -t 5000 "☀ Solar Zen" \
            "solcl not found at $SOLCL_BIN" 2>/dev/null || true
        return 0
    fi

    local monitors
    monitors=$(_get_monitors)
    [[ -z "$monitors" ]] && { log "  ⚠ No monitors found — using DP-3"; monitors="DP-3"; }

    local count=0
    while IFS= read -r monitor; do
        [[ -z "$monitor" ]] && continue
        log "  → Spawning solcl panel on $monitor..."
        kitty +kitten panel \
            --edge=background \
            --output-name="$monitor" \
            "${KITTY_PANEL_OPTS[@]}" \
            "$SOLCL_BIN" &
        disown
        (( count++ )) || true
    done <<< "$monitors"

    sleep 0.8
    log "  ✓ solar-bg panels launched on $count monitor(s)"

    # Start the rotation daemon in background
    chmod +x "$HOME/.scripts/solar-bg-rotate.sh" 2>/dev/null
    bash "$HOME/.scripts/solar-bg-rotate.sh" &
    disown
    log "  ✓ Rotation daemon started (25 min solcl → 5 min astroterm)"
}

# ── Kill all solar panels + rotation daemon ───────────────────────
_kill_solar_bg() {
    pkill -f "kitten panel.*--edge=background" 2>/dev/null || true
    pkill -f "kitty.*panel.*background"        2>/dev/null || true
    pkill -f "solar-bg-rotate.sh"              2>/dev/null || true
    pkill -f "solar-bg-cycle.sh"               2>/dev/null || true
    pkill -f "$SOLCL_BIN"                      2>/dev/null || true
    pkill -f "astroterm"                        2>/dev/null || true
    sleep 0.4
    log "  ✓ solar-bg panels + rotation daemon terminated"
}

# ══════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════
acquire_lock

STATE=$(read_state)
log "Current state: $STATE"

if [[ "$STATE" == "on" ]]; then
    disable_zen
else
    enable_zen
fi
