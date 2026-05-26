#!/usr/bin/env bash

if grep -q open /proc/acpi/button/lid/*/state; then
    hyprctl keyword monitor "eDP-1,1920x1080@60,1920x0,1"
else
    hyprctl keyword monitor "eDP-1,disable"
fi
