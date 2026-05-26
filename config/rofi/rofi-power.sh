#!/bin/bash

Shutdown_command="systemctl poweroff"
Reboot_command="systemctl reboot"
Logout_command="hyprctl dispatch exit"
Hibernate_command="systemctl hibernate"
Suspend_command="systemctl suspend"
Back_command=""

# Pointing exactly to YOUR new folder!
rofi_command="rofi -theme ~/.config/rofi/launcherSmoll.rasi"
options=$'Back\nShutdown\nLogout\nReboot\nHibernate\nSuspend'

eval \$"$(echo "$options" | $rofi_command -dmenu -p "")_command"

