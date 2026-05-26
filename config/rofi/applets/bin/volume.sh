#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Volume Info (WPCTL for PipeWire)
speaker="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100 "%"}')"
mic="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | awk '{print $2 * 100 "%"}')"

active=""
urgent=""

# Speaker Status
if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "[MUTED]"; then
    urgent="-u 1"
    stext='Muted'
    sicon='󰝟'
else
    active="-a 1"
    stext='Active'
    sicon=''
fi

# Microphone Status
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "[MUTED]"; then
    [ -n "$urgent" ] && urgent+=",3" || urgent="-u 3"
    mtext='Muted'
    micon='󰍭'
else
    [ -n "$active" ] && active+=",3" || active="-a 3"
    mtext='Active'
    micon='󰍮'
fi

# Theme Elements
prompt="Vol: $speaker"
mesg="Speaker: $stext ($speaker) | Mic: $mtext ($mic)"

# Define column/row based on your chosen type
if [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
    list_col='5'
    list_row='1'
    win_width='670px'
else
    list_col='1'
    list_row='5'
    win_width='400px'
fi

# Options
option_1="󰝝 Increase"
option_2="$sicon $stext"
option_3="󰝞 Decrease"
option_4="$micon Toggle Mic"
option_5="󰓅 Settings"

rofi_cmd() {
    rofi -theme-str "window {width: $win_width;}" \
        -theme-str "listview {columns: $list_col; lines: $list_row;}" \
        -theme-str 'textbox-prompt-colon {str: "";}' \
        -dmenu -p "$prompt" -mesg "$mesg" ${active} ${urgent} -theme ${theme}
}

run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

rofi_cmd() {
    # We pass the prompt and message directly to the new island theme
    formatted_msg="<b>${prompt}</b>\n<span color='#e6457b' size='small'>${mesg}</span>"
    
    rofi -dmenu \
        -theme ~/.config/rofi/mac-applet.rasi \
        -mesg "$formatted_msg" \
        ${active} ${urgent}
}

chosen="$(run_rofi)"
case ${chosen} in
    $option_1) run_cmd --opt1 ;;
    $option_2) run_cmd --opt2 ;;
    $option_3) run_cmd --opt3 ;;
    $option_4) run_cmd --opt4 ;;
    $option_5) run_cmd --opt5 ;;
esac
