#!/bin/bash
# ─── Hyprland Layout Toggle: Dwindle ↔ Scrolling ───
# Usage: toggle-scroll.sh [scroll_layout_name]
#   "scroller"  → hyprscrolling plugin (v0.51)
#   "scrolling" → built-in (v0.55+)
#
# When entering scrolling mode, this script:
#   1. Locks groups (prevents auto-grouping rules from firing)
#   2. Ungroups all currently grouped windows
#   3. Removes workspace-routing windowrules so new apps open on the current workspace
#   4. Switches layout to scrolling
#
# When returning to dwindle mode, it reverses everything.

SCROLL_LAYOUT="${1:-scrolling}"
CURRENT=$(hyprctl -j getoption general:layout | jq -r '.str')

if [ "$CURRENT" = "dwindle" ]; then
    # ═══════════════════════════════════════
    # Switch to Scrolling
    # ═══════════════════════════════════════

    # 1. Lock groups — prevents auto-grouping window rules from firing
    hyprctl dispatch lockgroups lock

    # 2. Ungroup ALL grouped windows (batched into one IPC call for speed)
    BATCH=""
    for addr in $(hyprctl -j clients | jq -r '.[] | select(.grouped | length > 0) | .address'); do
        BATCH="${BATCH}dispatch focuswindow address:${addr}; dispatch moveoutofgroup; "
    done
    [ -n "$BATCH" ] && hyprctl --batch "$BATCH"

    # 3. Remove workspace-routing & auto-group window rules
    #    Uses hyprctl keyword to override the workspace and group properties to "unset"
    hyprctl --batch "\
keyword windowrulev2 workspace unset, class:^(google-chrome|firefox)$; \
keyword windowrulev2 group unset, class:^(google-chrome|firefox)$; \
keyword windowrulev2 workspace unset, class:^(code|jetbrains-idea|codeblocks)$; \
keyword windowrulev2 group unset, class:^(code|jetbrains-idea|codeblocks)$; \
keyword windowrulev2 workspace unset, class:^(kitty)$; \
keyword windowrulev2 group unset, class:^(kitty)$; \
keyword windowrulev2 workspace unset, class:^(discord|org\.telegram\.desktop|com\.ktechpit\.whatsie|Spotify)$; \
keyword windowrulev2 group unset, class:^(discord|org\.telegram\.desktop|com\.ktechpit\.whatsie|Spotify)$"

    # 4. Switch layout
    hyprctl keyword general:layout "$SCROLL_LAYOUT"

    notify-send -t 2000 "Layout" "⇢ Scrolling Mode"
else
    # ═══════════════════════════════════════
    # Switch to Dwindle
    # ═══════════════════════════════════════

    # 1. Switch layout first
    hyprctl keyword general:layout dwindle

    # 2. Re-apply workspace-routing & auto-group rules
    hyprctl --batch "\
keyword windowrulev2 workspace 1, class:^(google-chrome|firefox)$; \
keyword windowrulev2 group set, class:^(google-chrome|firefox)$; \
keyword windowrulev2 workspace 2, class:^(code|jetbrains-idea|codeblocks)$; \
keyword windowrulev2 group set, class:^(code|jetbrains-idea|codeblocks)$; \
keyword windowrulev2 workspace 3, class:^(kitty)$; \
keyword windowrulev2 group set, class:^(kitty)$; \
keyword windowrulev2 workspace 4, class:^(discord|org\.telegram\.desktop|com\.ktechpit\.whatsie|Spotify)$; \
keyword windowrulev2 group set, class:^(discord|org\.telegram\.desktop|com\.ktechpit\.whatsie|Spotify)$"

    # 3. Unlock groups — auto-grouping window rules resume
    hyprctl dispatch lockgroups unlock

    notify-send -t 2000 "Layout" "⊞ Dwindle Mode"
fi
