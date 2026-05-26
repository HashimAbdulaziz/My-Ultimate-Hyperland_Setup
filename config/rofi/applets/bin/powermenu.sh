#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements
prompt="`hostname`"
mesg="Uptime : `uptime -p | sed -e 's/up //g'`"

if [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
    list_col='6'
    list_row='1'
else
    list_col='1'
    list_row='6'
fi

# Options (Nerd Font)
option_1=" Lock"
option_2="󰍃 Logout"
option_3="󰤄 Suspend"
option_4="󰋊 Hibernate"
option_5=" Reboot"
option_6=" Shutdown"

rofi_cmd() {
    rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
        -theme-str 'textbox-prompt-colon {str: "";}' \
        -dmenu -p "$prompt" -mesg "$mesg" -theme ${theme}
}

run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

run_cmd() {
    if [[ "$1" == '--opt1' ]]; then
        hyprlock
    elif [[ "$1" == '--opt2' ]]; then
        hyprctl dispatch exit
    elif [[ "$1" == '--opt3' ]]; then
        systemctl suspend
    elif [[ "$1" == '--opt4' ]]; then
        systemctl hibernate
    elif [[ "$1" == '--opt5' ]]; then
        systemctl reboot
    elif [[ "$1" == '--opt6' ]]; then
        systemctl poweroff
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
