#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  THEME PROFILE SWAPPER v2.0                                     ║
# ║  Hot-swaps between Cyberpunk and Undertale desktop themes        ║
# ║  Features: Dual-monitor sync, cinematic transitions,            ║
# ║            state tracking, lock-guard, notification feedback     ║
# ║                                                                  ║
# ║  Usage: theme-swapper.sh <cyberpunk|undertale|toggle>            ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Core Paths ─────────────────────────────────────────────────────
THEME_DIR="$HOME/.config/themes"
HYPR_DIR="$HOME/.config/hypr"
WAYBAR_DIR="$HOME/.config/waybar"
KITTY_DIR="$HOME/.config/kitty"
GHOSTTY_DIR="$HOME/.config/ghostty"

# ── State & Lock ───────────────────────────────────────────────────
STATE_FILE="/tmp/.theme-swapper-current"
LOCK_FILE="/tmp/.theme-swapper.lock"
LOG_FILE="/tmp/theme-swapper.log"

# ── Wallpapers ─────────────────────────────────────────────────────
CYBERPUNK_WALLPAPER="$HOME/Pictures/lofi.jpeg"
# Undertale: pure black void — the game's signature darkness
UNDERTALE_WALLPAPER="$THEME_DIR/undertale/wallpaper-black.png"

# ── Shaders ────────────────────────────────────────────────────────
GRAYSCALE_SHADER="$HOME/.config/hypr/shaders/grayscale.glsl"
OBSIDIAN_SNIPPET="$HOME/Documents/Obsidian Vault/.obsidian/snippets/auto-theme.css"

# ── Cyberpunk GTK defaults (captured from live system) ─────────────
CYBERPUNK_GTK_THEME="adw-gtk3-dark"
CYBERPUNK_ICON_THEME="WhiteSur-dark"
CYBERPUNK_CURSOR_THEME="Bibata-Modern-Classic"
CYBERPUNK_FONT="Adwaita Sans 11"
CYBERPUNK_DOC_FONT="Adwaita Sans 12"
CYBERPUNK_MONO_FONT="Adwaita Mono 11"

# ── Logging ────────────────────────────────────────────────────────
log() {
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

# ── Concurrency Lock ──────────────────────────────────────────────
acquire_lock() {
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        # Check if the lock is stale (older than 30 seconds)
        if [[ -d "$LOCK_FILE" ]]; then
            local lock_age
            lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
            if (( lock_age > 30 )); then
                log "⚠ Stale lock detected (${lock_age}s old), reclaiming..."
                rmdir "$LOCK_FILE" 2>/dev/null || true
                mkdir "$LOCK_FILE" 2>/dev/null || true
            else
                log "✗ Theme swap already in progress. Aborting."
                notify-send -u low -t 2000 "Theme Swap" "Already switching themes..." 2>/dev/null || true
                exit 0
            fi
        fi
    fi
    trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT
}

# ── Validate argument ──────────────────────────────────────────────
resolve_theme() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: theme-swapper.sh <cyberpunk|undertale|toggle>"
        exit 1
    fi

    local arg="$1"
    if [[ "$arg" == "toggle" ]]; then
        local current
        current=$(cat "$STATE_FILE" 2>/dev/null || echo "cyberpunk")
        if [[ "$current" == "cyberpunk" ]]; then
            echo "undertale"
        else
            echo "cyberpunk"
        fi
    elif [[ "$arg" == "cyberpunk" || "$arg" == "undertale" ]]; then
        echo "$arg"
    else
        echo "Usage: theme-swapper.sh <cyberpunk|undertale|toggle>"
        exit 1
    fi
}

# ── Safe file assembler ───────────────────────────────────────────
safe_cat_into() {
    local target="${@: -1}"    # Last argument
    local sources=("${@:1:$#-1}") # All arguments except the last

    for src in "${sources[@]}"; do
        if [[ ! -f "$src" ]]; then
            log "  ⚠ Missing source file: $src (skipping assembly for $target)"
            return 1
        fi
    done

    cat "${sources[@]}" > "$target"
}

# ── Discover all connected monitors ───────────────────────────────
get_monitors() {
    hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
try:
    monitors = json.load(sys.stdin)
    for m in monitors:
        if not m.get('disabled', False):
            print(m['name'])
except:
    pass
" 2>/dev/null
}

# ── Get Undertale wallpaper (always pure black void) ──────────────
get_undertale_wallpaper() {
    echo "$UNDERTALE_WALLPAPER"
}

# ══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ══════════════════════════════════════════════════════════════════

acquire_lock

THEME=$(resolve_theme "$@")
log "▸ Switching to theme: $THEME"

# Send an immediate "switching" notification
if [[ "$THEME" == "undertale" ]]; then
    notify-send -u low -t 3000 -i dialog-information \
        "❤ Theme Swap" "* (The world is shifting to UNDERTALE...)" 2>/dev/null || true
else
    notify-send -u low -t 3000 -i dialog-information \
        "⚡ Theme Swap" "Initializing Cyberpunk aesthetic..." 2>/dev/null || true
fi

# ── 1. Symlink Hyprland theme (borders + decoration) ──────────────
ln -sf "$THEME_DIR/$THEME/hyprland-theme.conf" "$HYPR_DIR/current-theme.conf"
log "  ✓ Hyprland theme linked"

# ── 2. Assemble Waybar theme ──────────────────────────────────────
if safe_cat_into "$THEME_DIR/$THEME/waybar-palette.css" "$WAYBAR_DIR/style-base.css" "$THEME_DIR/$THEME/waybar-override.css" "$WAYBAR_DIR/style.css"; then
    log "  ✓ Waybar theme assembled"
fi

# ── 2b. Patch Waybar config for theme-specific aesthetic ──────
patch_waybar_config() {
    local config="$WAYBAR_DIR/config.jsonc"
    [[ -f "$config" ]] || return 1

    python3 - "$config" "$THEME" <<'PYEOF'
import json, re, sys

config_path = sys.argv[1]
theme = sys.argv[2]

with open(config_path, 'r') as f:
    s = f.read()

# Strip JSON comments for parsing
clean = re.sub(r'//.*', '', s)
clean = re.sub(r'/\*.*?\*/', '', clean, flags=re.DOTALL)
clean = re.sub(r',\s*}', '}', clean)
clean = re.sub(r',\s*]', ']', clean)

try:
    data = json.loads(clean)
except Exception:
    sys.exit(0)

if theme == 'undertale':
    if 'custom/launcher' in data: data['custom/launcher']['exec'] = "echo '{\"text\":\"❤\",\"tooltip\":\"* It fills you with determination.\"}'"
    if 'hyprland/workspaces' in data:
        data['hyprland/workspaces']['format'] = "{icon}"
        data['hyprland/workspaces']['format-icons'] = { "active": "❤", "default": "♡", "urgent": "💔" }
    if 'cpu' in data: data['cpu']['format'] = "💙 {usage}%"
    if 'memory' in data: data['memory']['format'] = "💚 {}%"
    if 'temperature' in data: data['temperature']['format'] = "🧡 {temperatureC}°C"
    if 'disk' in data: data['disk']['format'] = "💛 {percentage_used}%"
    if 'battery' in data: 
        data['battery']['format'] = "💜 {capacity}%"
        data['battery']['format-charging'] = "💖 {capacity}%"
        data['battery']['format-plugged'] = "💖 {capacity}%"
        data['battery']['format-full'] = "💖 {capacity}%"
    if 'custom/power' in data: data['custom/power']['exec'] = "echo '{\"text\":\"🗡\",\"tooltip\":\"FIGHT / MERCY\"}'"
    if 'clock' in data: data['clock']['format'] = "⏱ {:%H:%M}"
else:
    if 'custom/launcher' in data: data['custom/launcher']['exec'] = "echo '{\"text\":\"#M\",\"tooltip\":\"Menu\"}'"
    if 'hyprland/workspaces' in data:
        data['hyprland/workspaces']['format'] = "{name}"
        data['hyprland/workspaces'].pop('format-icons', None)
    if 'cpu' in data: data['cpu']['format'] = " {usage}%"
    if 'memory' in data: data['memory']['format'] = "⛃ {}%"
    if 'temperature' in data: data['temperature']['format'] = "{icon} {temperatureC}°C"
    if 'disk' in data: data['disk']['format'] = " {percentage_used}% ({free})"
    if 'battery' in data: 
        data['battery']['format'] = "{icon} {capacity}%"
        data['battery']['format-charging'] = " {capacity}%"
        data['battery']['format-plugged'] = " {capacity}%"
        data['battery']['format-full'] = " {capacity}%"
    if 'custom/power' in data: data['custom/power']['exec'] = "echo '{\"text\":\"⏻\",\"tooltip\":\"Power\"}'"
    if 'clock' in data: data['clock']['format'] = " {:%d <small>%a</small> %H:%M}"

# Write in-place to preserve inode and trigger file watchers immediately
with open(config_path, 'w') as f:
    json.dump(data, f, indent=4)
PYEOF

    log "  ✓ Waybar config patched for $THEME icons"
}
patch_waybar_config


# ── 3. Assemble Rofi theme ────────────────────────────────────────
ROFI_BASE="$HOME/.config/rofi/launcher/type-7/style-1-base.rasi"
ROFI_OUT="$HOME/.config/rofi/launcher/type-7/style-1.rasi"
if safe_cat_into "$ROFI_BASE" "$THEME_DIR/$THEME/rofi-override.rasi" "$ROFI_OUT"; then
    log "  ✓ Rofi theme assembled"
fi

# ── 4. Assemble SwayNC theme ─────────────────────────────────────
if safe_cat_into "$HOME/.config/swaync/style-base.css" "$THEME_DIR/$THEME/swaync-override.css" "$HOME/.config/swaync/style.css"; then
    log "  ✓ SwayNC theme assembled"
fi

# ── 5. Assemble Kitty theme ──────────────────────────────────────
if safe_cat_into "$KITTY_DIR/kitty-base.conf" "$THEME_DIR/$THEME/kitty-theme.conf" "$KITTY_DIR/kitty.conf"; then
    log "  ✓ Kitty theme assembled"
fi

# ── 6. Assemble Ghostty theme ────────────────────────────────────
if [[ -d "$GHOSTTY_DIR" ]]; then
    if safe_cat_into "$GHOSTTY_DIR/config-base" "$THEME_DIR/$THEME/ghostty-theme" "$GHOSTTY_DIR/config"; then
        log "  ✓ Ghostty theme assembled"
    fi
fi

# ── 7. Symlink Fastfetch ─────────────────────────────────────────
mkdir -p "$HOME/.config/fastfetch"
ln -sf "$THEME_DIR/$THEME/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
log "  ✓ Fastfetch config linked"

# ── 8. Symlink Starship prompt ────────────────────────────────────
ln -sf "$THEME_DIR/$THEME/starship.toml" "$HOME/.config/starship.toml"
log "  ✓ Starship prompt linked"

# ── 9. Obsidian Theme ─────────────────────────────────────────────
mkdir -p "$(dirname "$OBSIDIAN_SNIPPET")"
if [[ -f "$THEME_DIR/$THEME/obsidian-theme.css" ]]; then
    cat "$THEME_DIR/$THEME/obsidian-theme.css" > "$OBSIDIAN_SNIPPET"

    # Ensure the snippet is enabled in Obsidian
    python3 -c "
import json, os, sys
path = os.path.join(os.path.dirname(os.path.dirname(sys.argv[1])), 'appearance.json')
data = {}
if os.path.exists(path):
    try:
        with open(path, 'r') as f: data = json.load(f)
    except: pass
if 'enabledCssSnippets' not in data:
    data['enabledCssSnippets'] = []
if 'auto-theme' not in data['enabledCssSnippets']:
    data['enabledCssSnippets'].append('auto-theme')
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
" "$OBSIDIAN_SNIPPET"

    log "  ✓ Obsidian theme applied"
fi

# ══════════════════════════════════════════════════════════════════
#  10. WALLPAPER — Per-Monitor with Cinematic Transitions
# ══════════════════════════════════════════════════════════════════
set_wallpaper() {
    local wallpaper="$1"

    if ! [[ -f "$wallpaper" ]]; then
        log "  ⚠ Wallpaper file not found: $wallpaper"
        return 1
    fi

    if command -v swww &>/dev/null; then
        # Kill hyprpaper if running — swww takes priority
        killall hyprpaper 2>/dev/null || true

        # Ensure swww daemon is running
        if ! pgrep -x swww-daemon >/dev/null; then
            nohup swww-daemon >/dev/null 2>&1 &
            sleep 0.8
        fi

        # Apply to all monitors simultaneously for perfect cinematic sync
        if [[ "$THEME" == "undertale" ]]; then
            # Undertale: cinematic fade to black void
            swww img "$wallpaper" \
                --transition-type fade \
                --transition-duration 1.8 \
                --transition-fps 144 \
                --transition-step 2 \
                --transition-bezier ".25,.1,.25,1"
        else
            # Cyberpunk: smooth diagonal reveal
            swww img "$wallpaper" \
                --transition-type wipe \
                --transition-angle 30 \
                --transition-duration 2.5 \
                --transition-fps 144 \
                --transition-step 2 \
                --transition-bezier ".25,.1,.25,1"
        fi

        log "  ✓ Wallpaper set on all monitors synchronously (swww)"

    elif command -v hyprpaper &>/dev/null; then
        # ── Hyprpaper fallback with per-monitor targeting ─────
        local monitors
        monitors=$(get_monitors)

        {
            echo "preload = $wallpaper"
            echo "splash = false"
            if [[ -n "$monitors" ]]; then
                while IFS= read -r monitor; do
                    [[ -z "$monitor" ]] && continue
                    echo "wallpaper = $monitor,$wallpaper"
                done <<< "$monitors"
            else
                echo "wallpaper = ,$wallpaper"
            fi
        } > "$HOME/.config/hypr/hyprpaper.conf"

        if pgrep -x hyprpaper >/dev/null; then
            # Force hyprpaper to reload by restarting it
            killall hyprpaper 2>/dev/null || true
            sleep 0.3
        fi
        nohup hyprpaper >/dev/null 2>&1 &
        disown
        sleep 0.5
        log "  ✓ Wallpaper set on all monitors (hyprpaper)"
    else
        log "  ⚠ No wallpaper engine found (install swww or hyprpaper)"
    fi
}

# Select and set wallpaper
if [[ "$THEME" == "undertale" ]]; then
    WALLPAPER=$(get_undertale_wallpaper)
    log "  ♫ Undertale wallpaper: $(basename "$WALLPAPER")"
else
    WALLPAPER="$CYBERPUNK_WALLPAPER"
fi

set_wallpaper "$WALLPAPER"

# ── 11. GTK System Theme ──────────────────────────────────────────
if [[ "$THEME" == "undertale" ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "HighContrast"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface icon-theme "HighContrast"
    gsettings set org.gnome.desktop.interface font-name "Terminess Nerd Font 14"
    gsettings set org.gnome.desktop.interface document-font-name "Terminess Nerd Font 14"
    gsettings set org.gnome.desktop.interface monospace-font-name "Terminess Nerd Font 14"
    hyprctl setcursor "Adwaita" 24
    log "  ✓ GTK theme → HighContrast & Terminess Font"
elif [[ "$THEME" == "cyberpunk" ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$CYBERPUNK_GTK_THEME"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface icon-theme "$CYBERPUNK_ICON_THEME"
    gsettings set org.gnome.desktop.interface font-name "$CYBERPUNK_FONT"
    gsettings set org.gnome.desktop.interface document-font-name "$CYBERPUNK_DOC_FONT"
    gsettings set org.gnome.desktop.interface monospace-font-name "$CYBERPUNK_MONO_FONT"
    hyprctl setcursor "$CYBERPUNK_CURSOR_THEME" 24
    log "  ✓ GTK theme → $CYBERPUNK_GTK_THEME & Adwaita Fonts"
fi

# ── Helper for robust JSON Editor Theme swapping ──────────────────
update_editor_theme() {
    local file="$1"
    local theme="$2"
    if [[ -f "$file" ]]; then
        python3 -c "
import json, sys, re
try:
    with open(sys.argv[1], 'r') as f:
        s = f.read()
    s = re.sub(r',\s*}', '}', s)
    s = re.sub(r',\s*\]', ']', s)
    s = re.sub(r'//.*', '', s)
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.DOTALL)
    data = json.loads(s)
except Exception as e:
    sys.exit(0)

if sys.argv[2] == 'undertale':
    data['workbench.colorTheme'] = 'Default High Contrast'
    data['editor.fontFamily'] = \"'Terminess Nerd Font', 'TerminessTTF Nerd Font', monospace\"
    data['terminal.integrated.fontFamily'] = \"'Terminess Nerd Font', 'TerminessTTF Nerd Font', monospace\"
    data['workbench.colorCustomizations'] = {
        '[Default High Contrast]': {
            'contrastBorder': '#444444', 'contrastActiveBorder': '#444444', 'focusBorder': '#444444',
            'widget.border': '#444444', 'panel.border': '#444444', 'editorGroup.border': '#444444',
            'titleBar.activeBackground': '#000000', 'titleBar.inactiveBackground': '#000000',
            'sideBar.background': '#000000', 'editor.background': '#000000', 'terminal.background': '#000000'
        }
    }
    data['editor.tokenColorCustomizations'] = {
        '[Default High Contrast]': {
            'semanticHighlighting': False,
            'textMateRules': [
                { 'scope': ['keyword', 'storage', 'modifier'], 'settings': { 'foreground': '#FFFF00', 'fontStyle': 'bold' } },
                { 'scope': ['string', 'punctuation.definition.string'], 'settings': { 'foreground': '#00FF00' } },
                { 'scope': ['entity.name.function', 'support.function'], 'settings': { 'foreground': '#00FFFF' } },
                { 'scope': ['variable', 'entity.name.variable'], 'settings': { 'foreground': '#FFFFFF' } },
                { 'scope': ['constant.numeric'], 'settings': { 'foreground': '#FFA500' } },
                { 'scope': ['entity.name.type', 'entity.name.class', 'support.type'], 'settings': { 'foreground': '#d24dff' } },
                { 'scope': ['comment'], 'settings': { 'foreground': '#888888', 'fontStyle': 'italic' } }
            ]
        }
    }
    data['editor.semanticTokenColorCustomizations'] = {
        '[Default High Contrast]': {
            'enabled': True,
            'rules': {
                'keyword': '#FFFF00', 'string': '#00FF00', 'function': '#00FFFF', 'method': '#00FFFF',
                'variable': '#FFFFFF', 'number': '#FFA500', 'class': '#d24dff', 'type': '#d24dff',
                'interface': '#d24dff', 'comment': '#888888'
            }
        }
    }
else:
    data['workbench.colorTheme'] = 'ƒ - Material - Operator Mono/Italic'
    data['editor.fontFamily'] = \"'Fira Code iScript', 'Fira Code', 'Courier New', monospace\"
    data['terminal.integrated.fontFamily'] = \"'JetBrainsMono Nerd Font'\"
    data.pop('workbench.colorCustomizations', None)
    data.pop('editor.tokenColorCustomizations', None)
    data.pop('editor.semanticTokenColorCustomizations', None)

# Write IN-PLACE to preserve inode, instantly triggering the editor file watcher without restart!
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=4)
" "$file" "$THEME"
    fi
}

# ── 12. GTK CSS Override (Libadwaita / Nautilus) ──────────────────
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cp "$THEME_DIR/$THEME/gtk-theme.css" "$HOME/.config/gtk-3.0/gtk.css"
cp "$THEME_DIR/$THEME/gtk-theme.css" "$HOME/.config/gtk-4.0/gtk.css"
log "  ✓ GTK CSS injected"

# ── 13. Editor Theme ──────────────────────────────────────────────
if [[ "$THEME" == "undertale" ]]; then
    update_editor_theme "$HOME/.config/Cursor/User/settings.json" "Default High Contrast"
    update_editor_theme "$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json" "Default High Contrast"
    update_editor_theme "$HOME/.config/Antigravity/User/settings.json" "Default High Contrast"
    log "  ✓ Editor theme → Default High Contrast"
elif [[ "$THEME" == "cyberpunk" ]]; then
    update_editor_theme "$HOME/.config/Cursor/User/settings.json" "One Dark Pro"
    update_editor_theme "$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json" "One Dark Pro"
    update_editor_theme "$HOME/.config/Antigravity/User/settings.json" "One Dark Pro"
    log "  ✓ Editor theme → One Dark Pro"
fi

# ══════════════════════════════════════════════════════════════════
#  14. HOT-RELOAD UI — Smooth & Professional
#      Staged reload: wallpaper first, then UI chrome, then daemons
# ══════════════════════════════════════════════════════════════════

# Reload Hyprland config (applies border colors, decoration, shaders)
hyprctl reload
log "  ✓ Hyprland reloaded"

# Brief pause to let the wallpaper transition settle visually
sleep 0.3

# ── Waybar: restart to apply config and CSS ─────────
killall waybar 2>/dev/null || true
nohup waybar >/dev/null 2>&1 &
log "  ✓ Waybar reloaded"

# ── 15. Daemon Reloads ────────────────────────────────────────────
# Hot-reload terminal colors smoothly
killall -SIGUSR1 kitty 2>/dev/null || true
# Ghostty auto-reloads its config dynamically, no kill needed

# Reload SwayNC smoothly
swaync-client -rs 2>/dev/null || true

log "  ✓ Terminals hot-reloaded"
log "  ✓ SwayNC CSS reloaded"

# ── 16. Save current state ────────────────────────────────────────
echo "$THEME" > "$STATE_FILE"

# ── 17. Final notification ────────────────────────────────────────
if [[ "$THEME" == "undertale" ]]; then
    notify-send -u normal -t 4000 -i dialog-information \
        "❤ UNDERTALE" "* (The power of the theme swap fills you with determination.)" 2>/dev/null || true
else
    notify-send -u normal -t 4000 -i dialog-information \
        "⚡ CYBERPUNK" "Neon aesthetic fully loaded. Welcome back, Netrunner." 2>/dev/null || true
fi

log ""
log "══════════════════════════════════════"
log "  Theme '$THEME' applied successfully!"
log "══════════════════════════════════════"
