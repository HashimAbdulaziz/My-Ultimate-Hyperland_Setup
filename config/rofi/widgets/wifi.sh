#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Wi-Fi menu — scan, connect, disconnect, toggle radio.
#  Modern rofi list with live signal bars + lock + connected markers.
#  Wired to the Waybar network icon (left click).
# ─────────────────────────────────────────────────────────────
THEME="$HOME/.config/rofi/widgets/widget.rasi"
US=$'\x1f'

rofi_menu() { rofi -dmenu -i -p "Wi-Fi" -theme "$THEME" "$@"; }
notify()    { notify-send -t 2500 -i network-wireless "Wi-Fi" "$1"; }

# 1. Radio off → offer to enable
if [ "$(nmcli -t -f WIFI radio 2>/dev/null)" != "enabled" ]; then
    CH=$(printf '󰖩  Enable Wi-Fi\n  Cancel' | rofi_menu)
    [[ "$CH" == *Enable* ]] && { nmcli radio wifi on; notify "Radio enabled"; }
    exit 0
fi

# 2. Kick off a fresh scan (ignore "too soon" errors), then read the list
nmcli dev wifi rescan 2>/dev/null
sleep 1

signal_glyph() {
    local s=${1:-0}
    if   [ "$s" -ge 75 ]; then echo "󰤨"
    elif [ "$s" -ge 50 ]; then echo "󰤥"
    elif [ "$s" -ge 25 ]; then echo "󰤢"
    else                       echo "󰤟"; fi
}

declare -a ROWS
# Header actions first
ROWS+=("󰖪  Disable Wi-Fi${US}__disable__${US}")
ROWS+=("  Rescan networks${US}__rescan__${US}")

# Networks: IN-USE,SIGNAL,SECURITY,SSID (SSID last so we can take the tail)
while IFS= read -r line; do
    inuse=$(cut -d: -f1 <<< "$line")
    signal=$(cut -d: -f2 <<< "$line")
    security=$(cut -d: -f3 <<< "$line")
    ssid=$(cut -d: -f4- <<< "$line")
    ssid=${ssid//\\:/:}                 # unescape any colons in the SSID
    [ -z "$ssid" ] && continue          # skip hidden / blank
    mark="   "; [ "$inuse" = "*" ] && mark=" "
    lock=" "; [ -n "$security" ] && [ "$security" != "--" ] && lock="  "
    label="$mark$(signal_glyph "$signal")  ${ssid}${lock}"
    ROWS+=("$label${US}${ssid}${US}${security}")
done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null \
         | sort -t: -k1,1r -k2,2nr | awk '!seen[$0]++')

# 3. Show menu
CHOICE=$(
    for r in "${ROWS[@]}"; do printf '%s\n' "${r%%${US}*}"; done | rofi_menu
)
[ -z "$CHOICE" ] && exit 0

# 4. Resolve choice → ssid + security
ssid=""; security=""
for r in "${ROWS[@]}"; do
    IFS="$US" read -r label rssid rsec <<< "$r"
    [ "$label" = "$CHOICE" ] && { ssid="$rssid"; security="$rsec"; break; }
done

case "$ssid" in
    __disable__) nmcli radio wifi off; notify "Radio disabled"; exit 0 ;;
    __rescan__)  exec "$0" ;;                         # re-run for a fresh scan
    "")          exit 0 ;;
esac

# Already connected to this one → offer disconnect
ACTIVE=$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes"{print $2; exit}')
if [ "$ssid" = "$ACTIVE" ]; then
    CH=$(printf '󰖪  Disconnect\n  Stay connected' | rofi_menu)
    [[ "$CH" == *Disconnect* ]] && { nmcli con down id "$ssid" 2>/dev/null; notify "Disconnected from $ssid"; }
    exit 0
fi

# 5. Connect. Use a saved profile if one exists, else connect fresh.
if nmcli -t -f NAME con show | grep -Fxq "$ssid"; then
    nmcli con up id "$ssid" 2>/dev/null && notify "Connected to $ssid" || notify "Failed to connect to $ssid"
    exit 0
fi

if [ -n "$security" ] && [ "$security" != "--" ]; then
    PW=$(rofi -dmenu -password -p "Password" -theme "$THEME" -mesg "Password for $ssid")
    [ -z "$PW" ] && exit 0
    nmcli dev wifi connect "$ssid" password "$PW" 2>/dev/null \
        && notify "Connected to $ssid" || notify "Wrong password or out of range"
else
    nmcli dev wifi connect "$ssid" 2>/dev/null \
        && notify "Connected to $ssid" || notify "Failed to connect to $ssid"
fi
