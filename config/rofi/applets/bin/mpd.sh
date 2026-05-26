#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements (Using playerctl for Spotify/Amberol)
status="$(playerctl status 2>/dev/null)"
if [[ -z "$status" ]]; then
    prompt='Offline'
    mesg="No music playing"
else
    prompt="$(playerctl metadata --format '{{artist}}')"
    mesg="$(playerctl metadata --format '{{title}}')"
fi

# Set Layout
if [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
    list_col='6'
    list_row='1'
else
    list_col='1'
    list_row='6'
fi

# Options
if [[ ${status} == *"Playing"* ]]; then
    option_1=" Pause"
else
    option_1=" Play"
fi
option_2=" Stop"
option_3=" Previous"
option_4=" Next"
option_5="󰑖 Repeat"
option_6=" Random"

rofi_cmd() {
    rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
        -theme-str 'textbox-prompt-colon {str: "";}' \
        -dmenu -p "$prompt" -mesg "$mesg" -theme ${theme}
}

run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

run_cmd() {
    if [[ "$1" == '--opt1' ]]; then
        playerctl play-pause
    elif [[ "$1" == '--opt2' ]]; then
        playerctl stop
    elif [[ "$1" == '--opt3' ]]; then
        playerctl previous
    elif [[ "$1" == '--opt4' ]]; then
        playerctl next
    elif [[ "$1" == '--opt5' ]]; then
        playerctl loop
    elif [[ "$1" == '--opt6' ]]; then
        playerctl shuffle toggle
    fi
}

chosen="$(run_rofi)"
case ${chosen} in
    $option_1) run_cmd --opt1 ;;
    $option_2) run_cmd --opt2 ;;
    $option_3) run_cmd --opt3 ;;
    $option_4) run_cmd --opt4 ;;
    $option_5) run_cmd --opt5 ;;
    $option_6) run_cmd --opt6 ;;
esac
