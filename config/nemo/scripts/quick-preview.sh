#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Quick Look for Nemo (right-click → "Quick Look").
#  Prefers GNOME Sushi (one unified preview popup for images/video/pdf/text/code,
#  the closest thing to macOS Quick Look on Wayland). Falls back to fast,
#  Wayland-native per-type viewers if sushi isn't installed.
# ─────────────────────────────────────────────────────────────
f="$1"
[ -z "$f" ] && exit 0

# Reliable, Wayland-native per-type viewers (sushi/nemo-preview are broken on
# Fedora 43, so we don't use them). imv = instant image preview: q closes it,
# arrow keys flip through the folder — the closest thing to macOS Quick Look.
mime=$(xdg-mime query filetype "$f" 2>/dev/null)
case "$mime" in
    image/gif)                          exec mpv --loop --quiet "$f" ;;
    image/*)                            command -v imv >/dev/null && exec imv "$f" || exec loupe "$f" ;;
    video/*|audio/*)                    exec mpv --quiet "$f" ;;
    application/pdf|application/epub+zip) exec evince "$f" ;;
    *)                                  exec xdg-open "$f" ;;
esac
