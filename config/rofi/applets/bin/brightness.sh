#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Brightness Info
backlight="$(brightnessctl g)"
max="$(brightnessctl m)"
percentage=$(( $backlight * 100 / $max ))

# Options
option_1="󰃠 Increase"
option_2="󰃟 Optimal (25%)"
option_3="󰃞 Decrease"
option_4="󰓅 Settings"

if [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
	list_col='4'
	list_row='1'
	win_width='550px'
else
	list_col='1'
	list_row='4'
	win_width='400px'
fi

rofi_cmd() {
    formatted_msg="<b>Brightness: ${percentage}%</b>"
    
    rofi -dmenu \
        -theme ~/.config/rofi/mac-applet.rasi \
        -mesg "$formatted_msg"
}

run_rofi() {
	echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd
}

chosen="$(run_rofi)"
case ${chosen} in
    $option_1) brightnessctl s +5% ;;
    $option_2) brightnessctl s 25% ;;
    $option_3) brightnessctl s 5%- ;;
    $option_4) pavucontrol ;; # Or your preferred settings app
esac
