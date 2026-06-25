#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  power-mode.sh — laptop power modes + a battery "slider" picker.
#
#    menu          rofi 3-segment slider (Low / Balanced / Max) with a battery
#                  time estimate under each. Picking one applies it.
#    performance | saver | balanced | cycle   set a mode directly.
#    est <mode>    print a mode's time estimate (debug).
#
#  ── Accuracy ──────────────────────────────────────────────────────────────
#  RAPL is root-only here, so we can't read CPU power on AC. Instead the script
#  SELF-CALIBRATES: whenever you're on battery, current_now × voltage_now gives
#  your REAL total system draw (CPU + screen + everything) for the active mode,
#  and we store it (exponential moving average) in ~/.cache/power-mode-watts.
#  Estimates then use your real measured watts-per-mode. The more you use each
#  mode unplugged, the more accurate it becomes. Until a mode is calibrated, it
#  is scaled from a calibrated mode (or a heuristic) so you still get a number.
#
#  No sudo: powerprofilesctl uses polkit; compositor + brightness are user-level.
# ─────────────────────────────────────────────────────────────
STATE="$HOME/.cache/power-mode"
BSAVE="$HOME/.cache/power-mode-brightness"
CALIB="$HOME/.cache/power-mode-watts"
THEME="$HOME/.config/rofi/widgets/powerslider.rasi"
B="/sys/class/power_supply/BAT0"

# Fallback relative draw per mode, only used before a mode is ever calibrated.
ratio() { case "$1" in saver) echo 0.55 ;; performance) echo 1.7 ;; *) echo 1.0 ;; esac; }
BASE_W=16   # last-resort Balanced wattage if nothing is calibrated yet

fx_on()  { hyprctl --batch "keyword decoration:blur:enabled 1; keyword decoration:shadow:enabled 1; keyword animations:enabled 1" >/dev/null 2>&1; }
fx_off() { hyprctl --batch "keyword decoration:blur:enabled 0; keyword decoration:shadow:enabled 0; keyword animations:enabled 0" >/dev/null 2>&1; }
save_brightness()    { [ -f "$BSAVE" ] || brightnessctl -q get > "$BSAVE" 2>/dev/null; }
restore_brightness() { [ -f "$BSAVE" ] && { brightnessctl -q set "$(cat "$BSAVE")" 2>/dev/null; rm -f "$BSAVE"; }; }

current() {
    local m; m=$(cat "$STATE" 2>/dev/null)
    if [ -z "$m" ]; then
        case "$(powerprofilesctl get 2>/dev/null)" in
            performance) m=performance ;; power-saver) m=saver ;; *) m=balanced ;;
        esac
    fi
    echo "$m"
}

apply() {
    local mode="$1"
    case "$mode" in
        performance)
            powerprofilesctl set performance 2>/dev/null
            restore_brightness; fx_on
            notify-send -t 2000 -i battery-full-charging "Power: MAX" "Full clocks + turbo, all effects on." ;;
        saver)
            powerprofilesctl set power-saver 2>/dev/null
            save_brightness; brightnessctl -q set 20% 2>/dev/null; fx_off
            notify-send -t 2000 -i battery-caution "Power: LOW (saver)" "Min clocks, effects off, screen dimmed." ;;
        balanced|*)
            mode=balanced
            powerprofilesctl set balanced 2>/dev/null
            restore_brightness; fx_on
            notify-send -t 1800 -i battery-good "Power: Balanced" "Sane defaults." ;;
    esac
    echo "$mode" > "$STATE"
}

# ── battery + calibration helpers ──────────────────────────────────────────
batt_wh()  { awk -v c="$(cat "$B/charge_now" 2>/dev/null||echo 0)" -v v="$(cat "$B/voltage_now" 2>/dev/null||echo 0)" 'BEGIN{printf "%.4f", c*v/1e12}'; }
live_w()   { awk -v i="$(cat "$B/current_now" 2>/dev/null||echo 0)" -v v="$(cat "$B/voltage_now" 2>/dev/null||echo 0)" 'BEGIN{printf "%.4f", i*v/1e12}'; }
get_w()    { awk -v m="$1" '$1==m{print $2; exit}' "$CALIB" 2>/dev/null; }
set_w() {  # $1 mode, $2 watts → EMA into the calib file
    local old new; old=$(get_w "$1")
    if [ -n "$old" ]; then new=$(awk -v o="$old" -v n="$2" 'BEGIN{printf "%.2f", 0.6*o+0.4*n}')
    else new=$(awk -v n="$2" 'BEGIN{printf "%.2f", n}'); fi
    { grep -v "^$1 " "$CALIB" 2>/dev/null; echo "$1 $new"; } > "$CALIB.tmp" 2>/dev/null && mv "$CALIB.tmp" "$CALIB"
}
calibrate() {  # if discharging, record the REAL watts of the current mode
    [ "$(cat "$B/status" 2>/dev/null)" = "Discharging" ] || return
    local w; w=$(live_w)
    awk -v w="$w" 'BEGIN{exit !(w>0.5)}' && set_w "$(current)" "$w"
}

watts_for() {  # $1 mode → best watts estimate (real if calibrated, else scaled)
    local mode="$1" w anchor aw
    w=$(get_w "$mode"); [ -n "$w" ] && { echo "$w"; return; }
    for anchor in balanced performance saver; do aw=$(get_w "$anchor"); [ -n "$aw" ] && break; done
    if [ -n "$aw" ]; then
        awk -v a="$aw" -v ra="$(ratio "$anchor")" -v rm="$(ratio "$mode")" 'BEGIN{printf "%.2f", a/ra*rm}'
    else
        awk -v b="$BASE_W" -v rm="$(ratio "$mode")" 'BEGIN{printf "%.2f", b*rm}'
    fi
}

est() {  # $1 mode → "Xh Ym"
    awk -v e="$(batt_wh)" -v w="$(watts_for "$1")" 'BEGIN{
        if(w<=0||e<=0){print "--";exit}
        h=e/w; printf "%dh %02dm", int(h), int((h-int(h))*60+0.5)
    }'
}

menu() {
    calibrate   # learn the current mode's real draw if we are on battery
    local cap st cur sel idx note
    cap=$(cat "$B/capacity" 2>/dev/null); st=$(cat "$B/status" 2>/dev/null); cur=$(current)
    case "$cur" in saver) sel=0 ;; performance) sel=2 ;; *) sel=1 ;; esac
    note="estimated runtime"; [ "$st" = "Discharging" ] && note="time remaining"

    idx=$(printf '%s\n%s\n%s\n' \
            "▁   <b>Low</b>      <span foreground='#8b93a7'>$(est saver)</span>" \
            "▄   <b>Balanced</b>      <span foreground='#8b93a7'>$(est balanced)</span>" \
            "█   <b>Max</b>      <span foreground='#8b93a7'>$(est performance)</span>" \
        | rofi -dmenu -i -markup-rows -format i -selected-row "$sel" -theme "$THEME" \
               -mesg "Battery $cap% · $st          $note per mode")
    [ -z "$idx" ] && exit 0
    case "$idx" in 0) apply saver ;; 2) apply performance ;; *) apply balanced ;; esac
}

case "$1" in
    menu)             menu ;;
    est)              est "${2:-balanced}"; echo ;;
    performance|perf) apply performance ;;
    saver|save)       apply saver ;;
    balanced|bal)     apply balanced ;;
    cycle)            case "$(current)" in saver) apply balanced ;; balanced) apply performance ;; *) apply saver ;; esac ;;
    *)                menu ;;
esac
