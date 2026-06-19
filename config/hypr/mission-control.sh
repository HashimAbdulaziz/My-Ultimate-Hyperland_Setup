#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Mission Control (hyprexpo) — idempotent loader + binder.
#  hyprpm's enable is broken on this box (root-owned state file), so the plugin
#  is loaded directly. Runtime binds/plugin-config are wiped by `hyprctl reload`
#  (theme-swaps do this), so this script is called on EVERY reload (exec) as well
#  as at boot (exec-once) to re-apply them. Safe to run repeatedly.
# ─────────────────────────────────────────────────────────────

# load the prebuilt .so if it isn't already loaded
if ! hyprctl plugins list 2>/dev/null | grep -qi hyprexpo; then
    SO=$(find /var/cache/hyprpm -name 'hyprexpo.so' 2>/dev/null | head -1)
    [ -n "$SO" ] && hyprctl plugin load "$SO" >/dev/null 2>&1
fi

# nothing to do if it still isn't loaded (e.g. IPC not ready yet at early boot)
hyprctl plugins list 2>/dev/null | grep -qi hyprexpo || exit 0

# look & feel
hyprctl keyword plugin:hyprexpo:columns 3            >/dev/null 2>&1
hyprctl keyword plugin:hyprexpo:gap_size 6           >/dev/null 2>&1
hyprctl keyword plugin:hyprexpo:bg_col "rgb(0a0a12)" >/dev/null 2>&1
hyprctl keyword plugin:hyprexpo:enable_gesture true  >/dev/null 2>&1   # 4-finger swipe
hyprctl keyword plugin:hyprexpo:gesture_fingers 4    >/dev/null 2>&1

# the keybind. Bind the physical KEYCODE (code:39 = S; Hyprland uses xkb codes =
# evdev+8, so S = 31+8 = 39) instead of the keysym, so it works on BOTH the us
# and ara layouts (on Arabic the S key sends a different keysym, which breaks a
# "SUPER, S" bind). Clear any existing first so repeated reloads don't STACK
# duplicate binds (stacked binds fire the toggle several times → they cancel out
# → looks like "nothing happens").
for _ in 1 2 3 4 5 6; do
    hyprctl keyword unbind "SUPER, code:39" >/dev/null 2>&1
    hyprctl keyword unbind "SUPER, code:31" >/dev/null 2>&1
    hyprctl keyword unbind "SUPER, S"       >/dev/null 2>&1
done
hyprctl keyword bind "SUPER, code:39, hyprexpo:expo, toggle" >/dev/null 2>&1
