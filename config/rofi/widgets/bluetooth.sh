#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Bluetooth menu — power, scan, connect/disconnect, pair, trust, remove.
#  Modern rofi list; handles the rfkill soft-block + power-on automatically.
#  Wired to the Waybar bluetooth icon and SUPER+B.
# ─────────────────────────────────────────────────────────────
THEME="$HOME/.config/rofi/widgets/widget.rasi"
US=$'\x1f'

rofi_menu() { rofi -dmenu -i -p "Bluetooth" -theme "$THEME" "$@"; }
notify()    { notify-send -t 2500 -i bluetooth "Bluetooth" "$1"; }
ctl()       { bluetoothctl "$@"; }
powered()   { ctl show 2>/dev/null | grep -q "Powered: yes"; }

# Make sure the adapter is unblocked + powered, prompting once if it's off.
ensure_power() {
    if ! ctl show 2>/dev/null | grep -q "Controller"; then
        rfkill unblock bluetooth 2>/dev/null; sleep 0.5
    fi
    powered && return 0
    local ch; ch=$(printf '󰂯  Power on Bluetooth\n  Cancel' | rofi_menu)
    [[ "$ch" == *"Power on"* ]] || exit 0
    rfkill unblock bluetooth 2>/dev/null
    ctl power on >/dev/null 2>&1; sleep 1
    powered || { notify "Couldn't power on the adapter.\nTry: sudo rfkill unblock bluetooth"; exit 1; }
    notify "Adapter powered on"
}

# Per-device actions
device_menu() {
    local mac="$1" name="$2" info opts ch
    info=$(ctl info "$mac" 2>/dev/null)
    opts=""
    grep -q "Connected: yes" <<< "$info" && opts+="󰂲  Disconnect\n" || opts+="󰂱  Connect\n"
    grep -q "Paired: yes"    <<< "$info" || opts+="  Pair\n"
    grep -q "Trusted: yes"   <<< "$info" && opts+="  Untrust\n" || opts+="  Trust\n"
    opts+="󰩹  Remove\n  Back"
    ch=$(printf "%b" "$opts" | rofi -dmenu -i -p "$name" -theme "$THEME")
    case "$ch" in
        *Disconnect) ctl disconnect "$mac" >/dev/null 2>&1; notify "Disconnected: $name" ;;
        *Connect)    ctl connect "$mac" >/dev/null 2>&1 && notify "Connected: $name" || notify "Failed to connect: $name" ;;
        *Pair)       ctl pair "$mac" >/dev/null 2>&1 && ctl trust "$mac" >/dev/null 2>&1 && notify "Paired: $name" ;;
        *Untrust)    ctl untrust "$mac" >/dev/null 2>&1; notify "Untrusted: $name" ;;
        *Trust)      ctl trust "$mac" >/dev/null 2>&1; notify "Trusted: $name" ;;
        *Remove)     ctl remove "$mac" >/dev/null 2>&1; notify "Removed: $name" ;;
        *Back)       exec "$0" ;;
    esac
}

ensure_power

# Build the list: header actions + known/paired devices
declare -a ROWS
ROWS+=("󰂲  Turn off Bluetooth${US}__off__")
ROWS+=("  Scan for new devices${US}__scan__")
while read -r _ mac name; do
    [ -z "$mac" ] && continue
    if ctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        ROWS+=("  ${name}${US}${mac}")     # connected
    else
        ROWS+=("󰂯  ${name}${US}${mac}")     # known, not connected
    fi
done < <(ctl devices 2>/dev/null)

CHOICE=$(for r in "${ROWS[@]}"; do printf '%s\n' "${r%%${US}*}"; done | rofi_menu)
[ -z "$CHOICE" ] && exit 0

target=""
for r in "${ROWS[@]}"; do
    IFS="$US" read -r label data <<< "$r"
    [ "$label" = "$CHOICE" ] && { target="$data"; break; }
done

case "$target" in
    __off__)  ctl power off >/dev/null 2>&1; notify "Bluetooth turned off"; exit 0 ;;
    __scan__) notify "Scanning for 8s…"; ctl --timeout 8 scan on >/dev/null 2>&1; exec "$0" ;;
    "")       exit 0 ;;
    *)        device_menu "$target" "${CHOICE#*  }" ;;   # strip leading glyph+spaces
esac
