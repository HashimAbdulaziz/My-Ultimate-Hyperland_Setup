#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Favourites dock — a row of big app icons. Click or type to launch.
#  Wired to the Waybar "#M" button (left click).
# ─────────────────────────────────────────────────────────────
THEME="$HOME/.config/rofi/widgets/applauncher.rasi"

# label | icon-name | launch command
FAVS=(
    "Code|vscode|code"
    "Chrome|google-chrome|google-chrome"
    "Terminal|kitty|kitty"
    "Obsidian|md.obsidian.Obsidian|flatpak run md.obsidian.Obsidian"
    "WhatsApp|com.ktechpit.whatsie|flatpak run com.ktechpit.whatsie"
)

# Resolve an icon NAME → largest absolute file path (hicolor + flatpak + pixmaps).
resolve_icon() {
    local name="$1" f base
    for base in /usr/share/icons/hicolor \
                /var/lib/flatpak/exports/share/icons/hicolor \
                "$HOME/.local/share/icons/hicolor"; do
        [ -d "$base" ] || continue
        f=$(find "$base/scalable" -iname "${name}.svg" 2>/dev/null | head -1)
        [ -n "$f" ] && { echo "$f"; return; }
        f=$(find "$base" -iname "${name}.png" 2>/dev/null \
            | sed -E 's#.*/([0-9]+)x[0-9]+/.*#\1\t&#' | sort -n | tail -1 | cut -f2-)
        [ -n "$f" ] && { echo "$f"; return; }
    done
    for p in /usr/share/pixmaps/"$name".png /usr/share/pixmaps/"$name".svg; do
        [ -f "$p" ] && { echo "$p"; return; }
    done
    echo "$name"   # last resort: let rofi resolve by name
}

# Is the launch command actually installed?
available() {
    local first=${1%% *}
    [ "$first" = "flatpak" ] && { command -v flatpak >/dev/null; return; }
    command -v "$first" >/dev/null
}

# Build the icon menu (only installed apps)
menu() {
    local entry label icon cmd
    for entry in "${FAVS[@]}"; do
        IFS='|' read -r label icon cmd <<< "$entry"
        available "$cmd" || continue
        printf '%s\0icon\x1f%s\n' "$label" "$(resolve_icon "$icon")"
    done
}

CHOICE=$(menu | rofi -dmenu -i -p "Apps" -theme "$THEME")
[ -z "$CHOICE" ] && exit 0

# Launch the matching command via Hyprland (so window rules / workspaces apply)
for entry in "${FAVS[@]}"; do
    IFS='|' read -r label icon cmd <<< "$entry"
    if [ "$label" = "$CHOICE" ]; then
        hyprctl dispatch exec "$cmd" >/dev/null 2>&1
        break
    fi
done
