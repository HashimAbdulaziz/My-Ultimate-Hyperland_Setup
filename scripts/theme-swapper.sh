#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  THEME PROFILE SWAPPER                                      ║
# ║  Hot-swaps between Cyberpunk and Undertale desktop themes    ║
# ║  Usage: theme-swapper.sh <cyberpunk|undertale>               ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

THEME_DIR="$HOME/.config/themes"
HYPR_DIR="$HOME/.config/hypr"
WAYBAR_DIR="$HOME/.config/waybar"
KITTY_DIR="$HOME/.config/kitty"
GHOSTTY_DIR="$HOME/.config/ghostty"
CYBERPUNK_WALLPAPER="$HOME/Pictures/lofi.jpeg"
UNDERTALE_WALLPAPER="$THEME_DIR/undertale/wallpaper-black.png"
GRAYSCALE_SHADER="$HOME/.config/hypr/shaders/grayscale.glsl"
OBSIDIAN_SNIPPET="$HOME/Documents/Obsidian Vault/CS/.obsidian/snippets/auto-theme.css"

# ── Cyberpunk GTK defaults (captured from live system) ────────
CYBERPUNK_GTK_THEME="WhiteSur-Dark"
CYBERPUNK_ICON_THEME="Adwaita"
CYBERPUNK_CURSOR_THEME="Bibata-Modern-Classic"
CYBERPUNK_FONT="Adwaita Sans 11"
CYBERPUNK_DOC_FONT="Adwaita Sans 12"
CYBERPUNK_MONO_FONT="Adwaita Mono 11"

# ── Validate argument ──────────────────────────────────────────
if [[ $# -ne 1 ]] || [[ "$1" != "cyberpunk" && "$1" != "undertale" ]]; then
    echo "Usage: theme-swapper.sh <cyberpunk|undertale>"
    exit 1
fi

THEME="$1"
echo "▸ Switching to theme: $THEME"

# ── Safe file assembler ───────────────────────────────────────
safe_cat_into() {
    local target="${@: -1}"  # Last argument
    local sources=("${@:1:$#-1}") # All arguments except the last

    for src in "${sources[@]}"; do
        if [[ ! -f "$src" ]]; then
            echo "  ⚠ Missing source file: $src (skipping assembly for $target)"
            return 1
        fi
    done

    cat "${sources[@]}" > "$target"
}

# ── 1. Symlink Hyprland theme (borders + decoration) ──────────
ln -sf "$THEME_DIR/$THEME/hyprland-theme.conf" "$HYPR_DIR/current-theme.conf"
echo "  ✓ Hyprland theme linked"

# ── 2. Assemble Waybar theme ───────────────────────────────────
if safe_cat_into "$THEME_DIR/$THEME/waybar-palette.css" "$WAYBAR_DIR/style-base.css" "$THEME_DIR/$THEME/waybar-override.css" "$WAYBAR_DIR/style.css"; then
    echo "  ✓ Waybar theme assembled"
fi

# ── 3. Assemble Rofi theme ───────────────────────────────────
ROFI_BASE="$HOME/.config/rofi/launcher/type-7/style-1-base.rasi"
ROFI_OUT="$HOME/.config/rofi/launcher/type-7/style-1.rasi"
if safe_cat_into "$ROFI_BASE" "$THEME_DIR/$THEME/rofi-override.rasi" "$ROFI_OUT"; then
    echo "  ✓ Rofi theme assembled"
fi

# ── 4. Assemble SwayNC theme ─────────────────────────────────
if safe_cat_into "$HOME/.config/swaync/style-base.css" "$THEME_DIR/$THEME/swaync-override.css" "$HOME/.config/swaync/style.css"; then
    echo "  ✓ SwayNC theme assembled"
fi

# ── 5. Assemble Kitty theme ───────────────────────────────────
if safe_cat_into "$KITTY_DIR/kitty-base.conf" "$THEME_DIR/$THEME/kitty-theme.conf" "$KITTY_DIR/kitty.conf"; then
    echo "  ✓ Kitty theme assembled"
fi

# ── 6. Assemble Ghostty theme ────────────────────────────────
if [[ -d "$GHOSTTY_DIR" ]]; then
    if safe_cat_into "$GHOSTTY_DIR/config-base" "$THEME_DIR/$THEME/ghostty-theme" "$GHOSTTY_DIR/config"; then
        echo "  ✓ Ghostty theme assembled"
    fi
fi

# ── 7. Symlink Fastfetch ─────────────────────────────────────
mkdir -p "$HOME/.config/fastfetch"
ln -sf "$THEME_DIR/$THEME/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
echo "  ✓ Fastfetch config linked"

# ── 8. Symlink Starship prompt ────────────────────────────────
ln -sf "$THEME_DIR/$THEME/starship.toml" "$HOME/.config/starship.toml"
echo "  ✓ Starship prompt linked"

# ── 9. Obsidian Theme ─────────────────────────────────────────
mkdir -p "$(dirname "$OBSIDIAN_SNIPPET")"
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

echo "  ✓ Obsidian theme applied"

# ── 10. Wallpaper ──────────────────────────────────────────────
if [[ "$THEME" == "undertale" ]]; then
    WALLPAPER="$UNDERTALE_WALLPAPER"
else
    WALLPAPER="$CYBERPUNK_WALLPAPER"
fi

if command -v swww &>/dev/null; then
    killall hyprpaper 2>/dev/null || true
    if ! pgrep -x swww-daemon >/dev/null; then
        nohup swww-daemon >/dev/null 2>&1 &
        sleep 0.5
    fi
    swww img "$WALLPAPER" --transition-type wipe --transition-angle 30 --transition-duration 7.0 --transition-fps 144
    echo "  ✓ Wallpaper set (swww)"
elif command -v hyprpaper &>/dev/null; then
    echo "preload = $WALLPAPER" > "$HOME/.config/hypr/hyprpaper.conf"
    echo "wallpaper = ,$WALLPAPER" >> "$HOME/.config/hypr/hyprpaper.conf"
    echo "splash = false" >> "$HOME/.config/hypr/hyprpaper.conf"
    
    if ! pgrep -x hyprpaper >/dev/null; then
        nohup hyprpaper >/dev/null 2>&1 &
        disown
        sleep 0.5
    else
        hyprctl hyprpaper preload "$WALLPAPER" 2>/dev/null || true
        hyprctl hyprpaper wallpaper ",$WALLPAPER" 2>/dev/null || true
    fi
    echo "  ✓ Wallpaper set (hyprpaper)"
else
    echo "  ⚠ No wallpaper engine found (install swww or hyprpaper)"
fi

# ── 11. GTK System Theme ──────────────────────────────────────
if [[ "$THEME" == "undertale" ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "HighContrast"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface icon-theme "HighContrast"
    gsettings set org.gnome.desktop.interface font-name "Terminess Nerd Font 14"
    gsettings set org.gnome.desktop.interface document-font-name "Terminess Nerd Font 14"
    gsettings set org.gnome.desktop.interface monospace-font-name "Terminess Nerd Font 14"
    hyprctl setcursor "Adwaita" 24
    echo "  ✓ GTK theme → HighContrast & Terminess Font"
elif [[ "$THEME" == "cyberpunk" ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "$CYBERPUNK_GTK_THEME"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface icon-theme "$CYBERPUNK_ICON_THEME"
    gsettings set org.gnome.desktop.interface font-name "$CYBERPUNK_FONT"
    gsettings set org.gnome.desktop.interface document-font-name "$CYBERPUNK_DOC_FONT"
    gsettings set org.gnome.desktop.interface monospace-font-name "$CYBERPUNK_MONO_FONT"
    hyprctl setcursor "$CYBERPUNK_CURSOR_THEME" 24
    echo "  ✓ GTK theme → $CYBERPUNK_GTK_THEME & Adwaita Fonts"
fi

# ── Helper for robust JSON Editor Theme swapping ─────────────
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
                { 'scope': ['source', 'text', 'keyword', 'string', 'variable', 'entity', 'constant', 'punctuation', 'storage', 'support', 'meta', 'markup', 'invalid'],
                  'settings': { 'foreground': '#ffffff', 'fontStyle': '' } },
                { 'scope': ['comment'], 'settings': { 'foreground': '#666666', 'fontStyle': 'italic' } }
            ]
        }
    }
    data['editor.semanticTokenColorCustomizations'] = {
        '[Default High Contrast]': {
            'enabled': True,
            'rules': {
                '*.modifier': '#ffffff', '*.type': '#ffffff', '*.class': '#ffffff', '*.interface': '#ffffff',
                '*.function': '#ffffff', '*.method': '#ffffff', '*.macro': '#ffffff', '*.variable': '#ffffff',
                '*.parameter': '#ffffff', '*.property': '#ffffff', '*.namespace': '#ffffff', '*.operator': '#ffffff',
                '*.string': '#ffffff', '*.number': '#ffffff', '*.keyword': '#ffffff', '*.regexp': '#ffffff',
                'comment': '#666666'
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

with open(sys.argv[1] + '.tmp', 'w') as f:
    json.dump(data, f, indent=4)
import os
os.replace(sys.argv[1] + '.tmp', sys.argv[1])
" "$file" "$THEME"
    fi
}

# ── 12. GTK CSS Override (Libadwaita / Nautilus) ─────────────
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cp "$THEME_DIR/$THEME/gtk-theme.css" "$HOME/.config/gtk-3.0/gtk.css"
cp "$THEME_DIR/$THEME/gtk-theme.css" "$HOME/.config/gtk-4.0/gtk.css"
echo "  ✓ GTK CSS injected"

# ── 13. Editor Theme ──────────────────────────────────────────
if [[ "$THEME" == "undertale" ]]; then
    update_editor_theme "$HOME/.config/Cursor/User/settings.json" "Default High Contrast"
    update_editor_theme "$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json" "Default High Contrast"
    update_editor_theme "$HOME/.config/Antigravity/User/settings.json" "Default High Contrast"
    echo "  ✓ Editor theme → Default High Contrast"
elif [[ "$THEME" == "cyberpunk" ]]; then
    update_editor_theme "$HOME/.config/Cursor/User/settings.json" "One Dark Pro"
    update_editor_theme "$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json" "One Dark Pro"
    update_editor_theme "$HOME/.config/Antigravity/User/settings.json" "One Dark Pro"
    echo "  ✓ Editor theme → One Dark Pro"
fi

# ── Live-reload open editor windows ────────────────────────────


# ── 14. Hot-reload UI ──────────────────────────────────────────
hyprctl reload
echo "  ✓ Hyprland reloaded"

# Hot-reload Waybar smoothly (SIGUSR2 reloads CSS/config without restarting the process)
killall -SIGUSR2 waybar 2>/dev/null || true
echo "  ✓ Waybar CSS hot-reloaded"

# ── 15. Daemon Reloads ─────────────────────────────────────────
# Hot-reload terminal colors smoothly
killall -SIGUSR1 kitty 2>/dev/null || true
# Ghostty auto-reloads its config dynamically, no kill needed

# Reload SwayNC smoothly
swaync-client -rs 2>/dev/null || true

echo "  ✓ Terminals hot-reloaded (smooth transition)"
echo "  ✓ SwayNC CSS reloaded"

echo ""
echo "══════════════════════════════════════"
echo "  Theme '$THEME' applied successfully!"
echo "══════════════════════════════════════"
