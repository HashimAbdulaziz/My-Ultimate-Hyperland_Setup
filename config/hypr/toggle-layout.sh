#!/usr/bin/env bash

MODE_FILE="$HOME/.config/hypr/dynamic_mode.conf"
# Initialize the mode file if it doesn't exist to prevent hyprctl reload errors
if [ ! -f "$MODE_FILE" ]; then
    echo "general { layout = dwindle }" > "$MODE_FILE"
fi

# Check if we are currently in scroller mode
if grep -q "layout = scrolling" "$MODE_FILE"; then
    
    # ─── SWITCHING TO DEFAULT MODE ───
    cat << 'EOF' > "$MODE_FILE"
    general {
        layout = dwindle
    }
    
    # Restore Normal Movement
    bind = SUPER, left, movefocus, l
    bind = SUPER, right, movefocus, r
    bind = SUPER, up, movefocus, u
    bind = SUPER, down, movefocus, d
    
    bind = SUPER SHIFT, left, swapwindow, l
    bind = SUPER SHIFT, right, swapwindow, r
    bind = SUPER SHIFT, up, swapwindow, u
    bind = SUPER SHIFT, down, swapwindow, d

    # Restore Grouping Keys
    bind = SUPER, G, togglegroup
    bind = SUPER SHIFT, G, moveoutofgroup
    bind = SUPER CTRL, left, moveintogroup, l
    bind = SUPER CTRL, right, moveintogroup, r
    bind = SUPER CTRL, up, moveintogroup, u
    bind = SUPER CTRL, down, moveintogroup, d
    
    # Restore Strict Workspace Rules
    windowrulev2 = workspace 1, class:^(google-chrome|firefox)$
    windowrulev2 = group set, class:^(google-chrome|firefox)$
    
    windowrulev2 = workspace 2, class:^(code|jetbrains-idea|codeblocks)$
    windowrulev2 = group set, class:^(code|jetbrains-idea|codeblocks)$
    
    windowrulev2 = workspace 3, class:^(kitty)$
    windowrulev2 = group set, class:^(kitty)$
    
    windowrulev2 = workspace 4, class:^(discord|org\.telegram\.desktop|com\.ktechpit\.whatsie|Spotify)$
    windowrulev2 = group set, class:^(discord|org\.telegram\.desktop|com\.ktechpit\.whatsie|Spotify)$
EOF
    notify-send -t 2000 "Layout" "⊞ Dwindle Mode"

else
    
    # ─── SWITCHING TO SCROLLER MODE ───
    cat << 'EOF' > "$MODE_FILE"
    general {
        layout = scrolling
    }
    
    # Overwrite Movement Keys for Scrolling
    # With hyprscrolling plugin, the standard movefocus and movewindow work fine,
    # but we can omit the grouping and workspace routing completely.
    bind = SUPER, left, movefocus, l
    bind = SUPER, right, movefocus, r
    bind = SUPER, up, movefocus, u
    bind = SUPER, down, movefocus, d
    
    bind = SUPER SHIFT, left, movewindow, l
    bind = SUPER SHIFT, right, movewindow, r
    bind = SUPER SHIFT, up, movewindow, u
    bind = SUPER SHIFT, down, movewindow, d
    
    # NOTICE: Grouping keybinds and workspace windowrulev2s are entirely 
    # absent from this block, meaning they are fully disabled in this mode!
EOF
    notify-send -t 2000 "Layout" "⇢ Scrolling Mode"
fi

# We must manually ungroup existing windows before reloading, otherwise they stay stuck in groups
BATCH=""
for addr in $(hyprctl -j clients | jq -r '.[] | select(.grouped | length > 0) | .address'); do
    BATCH="${BATCH}dispatch focuswindow address:${addr}; dispatch moveoutofgroup; "
done
[ -n "$BATCH" ] && hyprctl --batch "$BATCH"

# Instantly apply the changes
hyprctl reload
