#!/bin/bash

# 1. Read the state of the CURRENT window
OLD_STATE=$(hyprctl activewindow -j | jq -r '.fullscreen')

# 2. THE NINJA TRICK: Turn off the animation engine temporarily!
hyprctl keyword animations:enabled 0

# 3. Switch the tab
hyprctl dispatch changegroupactive "$1"

# 4. Wait a tiny micro-second for the focus to shift
sleep 0.02

# 5. Read the state of the NEW window
NEW_STATE=$(hyprctl activewindow -j | jq -r '.fullscreen')

# 6. Apply the fullscreen state instantly (Because animations are off, it just snaps!)
if [[ "$OLD_STATE" != "0" && "$OLD_STATE" != "false" && "$OLD_STATE" != "null" ]]; then
    if [[ "$NEW_STATE" == "0" || "$NEW_STATE" == "false" || "$NEW_STATE" == "null" ]]; then
        if [[ "$OLD_STATE" == "1" ]]; then
            hyprctl dispatch fullscreen 1
        else
            hyprctl dispatch fullscreen 0
        fi
    fi
fi

# 7. Turn the animation engine back on so the rest of your system stays smooth!
hyprctl keyword animations:enabled 1
