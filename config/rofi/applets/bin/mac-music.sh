#!/usr/bin/env bash
# ================================================================
#  mac-music.sh — Modern Waybar → Rofi Music Controller
# ================================================================

# ── Paths ──────────────────────────────────────────────────────
RAW_PATH="/tmp/rofi-music-raw.png"
ART_PATH="/tmp/rofi-music-cover.png"
THEME="$HOME/.config/rofi/mac-music.rasi"

# ── 1. Fetch & Process Album Art ───────────────────────────────
art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [[ -z "$art_url" ]]; then
    # Dark placeholder when no art exists
    magick -size 300x300 xc:"#1a1a2a" \
        -fill "#e6457b" -font "JetBrainsMono-Nerd-Font" \
        -pointsize 80 -gravity center -annotate 0 "♪" \
        "$ART_PATH" 2>/dev/null || touch "$ART_PATH"

elif [[ "$art_url" == http* ]]; then
    curl -s --max-time 3 "$art_url" -o "$RAW_PATH"
    magick "$RAW_PATH" \
        -resize 300x300^ \
        -gravity center \
        -extent 300x300 \
        -strip \
        "$ART_PATH" 2>/dev/null

elif [[ "$art_url" == file://* ]]; then
    local_path="${art_url#file://}"
    magick "$local_path" \
        -resize 300x300^ \
        -gravity center \
        -extent 300x300 \
        -strip \
        "$ART_PATH" 2>/dev/null
fi

# ── 2. Get Track Info ──────────────────────────────────────────
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
album=$(playerctl metadata album 2>/dev/null)
status=$(playerctl status 2>/dev/null)

[[ -z "$title" ]]  && title="No Music Playing"
[[ -z "$artist" ]] && artist="Unknown Artist"

# Escape XML/Pango special chars
title=$(echo "$title"  | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
artist=$(echo "$artist" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
album=$(echo "$album"  | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

# ── 3. Play/Pause icon ─────────────────────────────────────────
if [[ "$status" == "Playing" ]]; then
    pp_icon=""   
    status_dot="<span color='#a6e3a1' size='small'>▶ Playing</span>"
else
    pp_icon=""   
    status_dot="<span color='#f38ba8' size='small'>⏸ Paused</span>"
fi

# ── 4. Build Pango message ─────────────────────────────────────
if [[ -n "$album" ]]; then
    album_line="\n<span color='#6c7086' size='small'>${album}</span>"
else
    album_line=""
fi

# FIX 1: We use $(echo -e "...") so Bash properly interprets the \n line breaks!
markup_text=$(echo -e "<span font='JetBrainsMono Nerd Font Bold 14' color='#cdd6f4'>${title}</span>\n<span font='JetBrainsMono Nerd Font 12' color='#e6457b'>${artist}</span>${album_line}\n${status_dot}")

# ── 5. Controls list ───────────────────────────────────────────
prev_icon=""     
next_icon=""     

options="${prev_icon}\n${pp_icon}\n${next_icon}"

# ── 6. Launch Rofi ─────────────────────────────────────────────
# FIX 2: Removed the -no-fixed-num-lines flag so the buttons actually render!
chosen=$(echo -e "$options" | rofi \
    -dmenu \
    -theme "$THEME" \
    -mesg "$markup_text" \
    -selected-row 1 \
    -p "" \
    -format i)

# ── 7. Handle selection (by index) ────────────────────────────
case "$chosen" in
    0) playerctl previous ;;
    1) playerctl play-pause ;;
    2) playerctl next ;;
esac
