#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Audio output switcher — pick a speaker / headphones / sink.
#  Speaker & Headphones are *ports* of the built-in card, so we switch the
#  port; other devices (Bluetooth / HDMI / USB) are switched as sinks. Either
#  way the default is set AND all running streams are moved over.
#  Wired to the Waybar audio icon (left click).
# ─────────────────────────────────────────────────────────────
THEME="$HOME/.config/rofi/widgets/widget.rasi"
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)

glyph_for() {  # $1 = "sinkname + desc", $2 = port desc
    local d="${1,,} ${2,,}"
    case "$d" in
        *bluetooth*|*bluez*)              echo "󰂯" ;;
        *headphone*|*headset*|*earphone*) echo "" ;;
        *hdmi*|*display*)                 echo "󰡁" ;;
        *usb*|*dock*)                     echo "" ;;
        *speaker*|*analog*|*built-in*)    echo "󰓃" ;;
        *)                                echo "" ;;
    esac
}

# Parse `pactl list sinks` → ROWS[] = "visible-label \x1f sink \x1f port"
declare -a ROWS
sink=""; desc=""; active=""; in_ports=0
declare -a PORTS

flush() {
    [ -z "$sink" ] && return
    local p pname pdesc avail label marker text navail=0
    # count available ports → decide what the label should say
    for p in "${PORTS[@]}"; do
        IFS=$'\x1f' read -r pname pdesc avail <<< "$p"
        [ "$avail" != "no" ] && navail=$((navail + 1))
    done
    for p in "${PORTS[@]}"; do
        IFS=$'\x1f' read -r pname pdesc avail <<< "$p"
        [ "$avail" = "no" ] && continue
        marker="   "
        [ "$sink" = "$DEFAULT_SINK" ] && [ "$pname" = "$active" ] && marker=" "
        # one port → show the device name (e.g. "WH-1000XM4"); many ports → show
        # each port (e.g. "Speakers" / "Headphones") of the same card.
        if [ "$navail" -le 1 ]; then text="${desc:-$pdesc}"; else text="${pdesc:-$desc}"; fi
        label="$marker$(glyph_for "$sink $desc" "$pdesc")  $text"
        ROWS+=("$label"$'\x1f'"$sink"$'\x1f'"$pname")
    done
    sink=""; desc=""; active=""; PORTS=()
}

while IFS= read -r raw; do
    line="${raw#"${raw%%[![:space:]]*}"}"   # left-trim
    case "$line" in
        "Name: "*)        flush; sink="${line#Name: }" ;;
        "Description: "*) desc="${line#Description: }" ;;
        "Ports:")         in_ports=1 ;;
        "Active Port: "*) active="${line#Active Port: }"; in_ports=0 ;;
        *)
            if [ "$in_ports" = 1 ] && [[ "$line" == *":"*"("* ]]; then
                pname="${line%%:*}"
                rest="${line#*: }"
                pdesc="${rest%% (*}"
                if   [[ "$line" == *"not available"* ]]; then avail="no"
                else avail="yes"; fi
                PORTS+=("$pname"$'\x1f'"$pdesc"$'\x1f'"$avail")
            fi
            ;;
    esac
done < <(pactl list sinks 2>/dev/null)
flush

if [ "${#ROWS[@]}" -eq 0 ]; then
    notify-send -t 2000 "Audio" "No output devices found"; exit 0
fi

# Show menu (pipe runs in a subshell, but ROWS stays populated in the parent)
CHOICE=$(
    for r in "${ROWS[@]}"; do printf '%s\n' "${r%%$'\x1f'*}"; done \
    | rofi -dmenu -i -p "Output" -theme "$THEME"
)
[ -z "$CHOICE" ] && exit 0

# Map the chosen label back to its sink + port and apply
for r in "${ROWS[@]}"; do
    IFS=$'\x1f' read -r label rsink rport <<< "$r"
    if [ "$label" = "$CHOICE" ]; then
        pactl set-default-sink "$rsink"
        [ -n "$rport" ] && pactl set-sink-port "$rsink" "$rport" 2>/dev/null
        # move every active stream onto the new sink
        for id in $(pactl list short sink-inputs 2>/dev/null | awk '{print $1}'); do
            pactl move-sink-input "$id" "$rsink" 2>/dev/null
        done
        notify-send -t 1500 -i audio-volume-high "Audio Output" "${CHOICE#"${CHOICE%%[! ]*}"}"
        break
    fi
done
