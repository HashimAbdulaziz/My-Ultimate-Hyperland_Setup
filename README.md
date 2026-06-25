# My Ultimate Hyprland Setup

A Hyprland rice that treats the mouse as a last resort, the wallpaper as a UI
element, and "it works on my machine" as a personality trait.

This is my daily driver. It has been poked, broken, un-broken, over-engineered,
and lovingly debugged at 3 AM more times than I will admit in a public README.
If you are here to steal config, welcome. Take what you like. Leave the bugs.

---

## The Manifesto (a.k.a. why my windows never touch)

Three rules run this whole machine. Everything else is decoration.

**1. Everything is a tile.**
Windows are not free-floating balloons that drift around the screen and pile up
in the corner like junk mail. They are tiles. They snap into a grid, they share
the space, and they behave. When a new window opens it takes its slot and gets
in line. Floating windows exist only as a punishment for badly-behaved dialogs,
and even those get pinned and put in their place.

**2. I hate overlapping windows.**
If a window is covering another window, something has gone wrong. I want to see
everything I am working on at once, all the time, no shuffling, no alt-tab
archaeology, no "which of these seven identical terminals is the right one." The
whole layout is built so nothing ever hides behind anything else. Stacks are
tabbed (so they are one tile, not a mess), the file manager tiles, the settings
dialogs tile, the terminal tiles. The day a window overlaps another window is the
day I open the config and fix it.

**3. The keyboard is the interface. The mouse is for emergencies.**
Hands stay on the home row. Switching workspaces, launching apps, moving windows,
toggling layouts, connecting to WiFi, switching audio output, locking the screen,
firing up Mission Control - all of it is a chord away. If a task needs the mouse,
that is a bug in my muscle memory, and I will bind it to a key. Reaching for the
trackpad should feel like getting up to change the TV channel by hand.

Everything below exists to serve those three rules.

---

## The Power Features

### The bar is the wallpaper (Liquid-Glass Waybar)
There is no opaque bar. There are floating frosted-glass "islands" that hover over
the wallpaper, blurred by the compositor so the desktop bleeds through them. CPU,
RAM, temp, and disk live in one segmented pill; network, bluetooth, audio,
brightness, and battery in another. Hover lifts them with a soft neon glow. The
glass opacity and blur are tuned so it looks like frosted acrylic, not a sticker.

### Mission Control (hyprexpo)
`SUPER + S` (or a four-finger swipe) zooms the whole desktop out into a grid of
every workspace, macOS-Mission-Control style, click to jump. Loaded straight from
the prebuilt plugin and re-bound on every reload so it survives theme swaps. Yes,
getting this to persist was a saga. No, I will not elaborate. (It binds by
physical keycode so it works on both the US and Arabic keyboard layouts.)

### Everything-is-a-rofi-menu (no settings apps allowed)
The mouse-driven settings apps have been evicted. In their place, glassy rofi
menus that match the theme:
- **WiFi menu** - scan, signal bars, lock icons, type the password, connect. nmcli
  doing the work, rofi doing the looks.
- **Bluetooth menu** - powers the adapter on (un-blocks rfkill for you), scans,
  connects, pairs, trusts, removes. Bound to `SUPER + B`.
- **Audio output switcher** - flip between Speakers and Headphones (yes, the
  separate ports of the same card) and any Bluetooth/HDMI sink, and it moves your
  running audio streams over with you.
- **Favourites dock** - the `#M` button opens a horizontal dock of big app icons
  (your most-used apps) you can click or type to launch.

### Prayer times that actually behave (Salah module)
A Waybar module that shows the next prayer and a live countdown in 12-hour time.
It caches the daily timetable so it is not hammering an API every minute, works
offline the rest of the day, and **blinks red when you are within 30 minutes** of
the next prayer so you do not lose track of time inside a compile.

### Two layouts, one keystroke
`SUPER + SHIFT + R` flips the whole session between classic **dwindle** tiling and
**scrolling** mode (PaperWM-style, via hyprscrolling). Window-routing rules and
auto-grouping get swapped out cleanly in the background so the two modes do not
fight each other.

### Tabbed groups, because stacks should be one tile
`SUPER + G` groups windows into a tabbed stack that occupies a single tile (see
rule 2). The group indicator is a slim gradient pill bar - no chunky title bars,
just enough to know a tile has friends hiding behind it. `ALT + Tab` flips through
the tabs, and there is a small bit of trickery (`smart_tab.sh`) that preserves
fullscreen state as you cycle so it does not flicker.

### Glass everywhere
The frosted treatment is not just the bar. pavucontrol, blueman, the network
editor, GTK file dialogs, the file manager - all of them get a dark translucent
blur so the desktop looks like one coherent thing instead of a pile of mismatched
toolkits.

### A file manager that does not look like 2009
Nemo, themed dark (adw-gtk3-dark), wearing a macOS-style WhiteSur icon set, made
translucent and blurred by the compositor, with your project folders pinned to the
sidebar and a right-click "Quick Look" that previews images/video/PDFs in fast,
Wayland-native viewers. (Quick Look is right-click and not Spacebar because the
Spacebar previewer is held together by a deprecated toolkit that segfaults on
modern Wayland. We do not speak of nemo-preview here.)

### Dual-theme hot-swap
The entire OS pivots its look on one keystroke, no logout, no restart:
- **Neon Cyberpunk** (`SUPER + SHIFT + Q`) - cyan and hot-red, glassmorphism,
  glow for days.
- **Undertale Monochrome** (`SUPER + SHIFT + E`) - 1-bit grayscale pixel focus
  mode for when the neon is too much.

`theme-swapper.sh` assembles the modular palette/base/override files and reloads
Waybar, Hyprland, swaync, kitty/ghostty, GTK, VS Code, and Obsidian in place by
signalling them (`SIGUSR1`/`SIGUSR2`) instead of killing them. Change one theme,
the whole machine changes its mind instantly.

### Solar Zen Mode
`SUPER + I` toggles a focus mode driven by an astroterm rotation - because
sometimes the rice needs to chill out and look at the stars.

### Taskwarrior, but make it ambient
A Waybar timer wired to Taskwarrior/Timewarrior shows what you are tracking. Step
away for five minutes and it auto-pauses the timer; come back and it resumes. Your
time tracking babysits itself.

---

## The Hardware War Story (performance notes)

This runs on an Optimus laptop: an Intel iGPU wired to the displays and an NVIDIA
Quadro P2000 hanging off the side. The setup is deliberately **Intel-primary** -
the desktop renders on the iGPU that actually owns the screens, so there is no
per-frame GPU-to-GPU copy, the dGPU can nap, and the laptop stays cool and quiet.

Hard-won lessons baked into the config so you do not repeat them:
- **Never inject `AQ_DRM_DEVICES` / `WLR_DRM_DEVICES` into the config.** Hardcoding
  DRM device paths makes the Aquamarine backend abort on launch (the classic
  "IOT instruction core dumped"). Let the hardware MUX and auto-detection pick.
- **Hardware cursors on the iGPU**, not software cursors - moving the mouse no
  longer forces a full-screen blur recompute every frame.
- **VFR on**, blur tuned to "glassy but not a space heater," and a cava visualizer
  that sleeps when there is no audio so it idles near zero CPU instead of cooking a
  core to render silence.

If your fan is loud, it is probably your apps, not your compositor. Ask me how I
know.

---

## Keybind Cheat Sheet

`SUPER` is the mod key. If you have to read this table you are not yet living rule 3.

| Keys | Does the thing |
|---|---|
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + R` | App launcher (rofi) |
| `SUPER + E` | File manager (Nemo) |
| `SUPER + SHIFT + E` | File manager, terminal flavour (ranger) |
| `SUPER + C` | Close window |
| `SUPER + F` / `SHIFT + F` | Fullscreen / maximize-in-tile |
| `SUPER + V` | Toggle floating (use sparingly, see rule 1) |
| `SUPER + G` | Group windows into a tabbed tile |
| `ALT + Tab` | Cycle tabs within a group |
| `SUPER + S` | Mission Control (workspace overview) |
| `SUPER + SHIFT + R` | Toggle dwindle <-> scrolling layout |
| `SUPER + 1..5` | Go to workspace |
| `SUPER + SHIFT + 1..5` | Throw window to workspace |
| `SUPER + arrows` | Move focus |
| `SUPER + SHIFT + arrows` | Move/swap window |
| `SUPER + B` | Bluetooth menu |
| `SUPER + A` | Audio mixer |
| `SUPER + N` | Notification center |
| `SUPER + L` | Lock screen |
| `SUPER + grave` | Scratchpad terminal |
| `SUPER + ESCAPE` | btop (system monitor) |
| `SUPER + O` / `SUPER + D` | Screenshot region / annotate |
| `SUPER + I` | Solar Zen Mode |
| `SUPER + SHIFT + Q` / `SHIFT + E` | Theme: Cyberpunk / Undertale |

---

## Structure

```
config/
  hypr/        compositor config, layout modes, window rules, keybinds,
               mission-control loader, layout-toggle + smart-tab scripts
  waybar/      the liquid-glass bar (structure) + salah module + base CSS
  rofi/        launchers, applets, and the new glassy widgets/ (wifi, bt, audio)
  cava/        audio visualizer config (the one that sleeps when silent)
  themes/      cyberpunk + undertale palettes for every app in the stack
  nemo/        Quick Look action + script for the file manager
  swaync/ kitty/   notification center + terminal theming
scripts/
  theme-swapper.sh     the conductor: assembles + hot-reloads every theme
  launch-hyprland.sh   session entry (GPU selection lives here, read the comments)
  waybar-timer.sh      taskwarrior/timewarrior bridge for the bar
  solar-*.sh           solar zen mode machinery
```

---

## Installation (the "works on my machine" clause)

These are personal dotfiles, not a distro. They assume Hyprland 0.51+, a Nerd
Font, and a pile of tools (rofi-wayland, nmcli, bluetoothctl, wpctl, brightnessctl,
cava, swaync, Nemo, jq, etc.). Paths are hardcoded to `/home/hashim` in a few
places because past-me was in a hurry - grep and adjust.

```sh
# back up your own config first, obviously
cp -r config/hypr   ~/.config/
cp -r config/waybar ~/.config/
cp -r config/rofi   ~/.config/
cp -r config/themes ~/.config/
cp -r config/cava   ~/.config/
cp    scripts/*     ~/.scripts/

# pick a vibe
~/.scripts/theme-swapper.sh cyberpunk
```

Then read `config/hypr/hyprland.conf` top to bottom. It is commented like a
person who has been burned before, because it is.

---

## Changelog

Every entry is something I actually use daily. Nothing gets added because it
looked cool in a screenshot. If it does not survive a week of real use, it gets
deleted. These entries did.

---

### 2026-06-25 — Smart Tools Update (feat/smart-tools)

**QR Code Scanner** (`SUPER+SHIFT+Q`)
Snip any area of the screen, zbar decodes the QR. Handles both normal and
inverted (white-on-dark) codes automatically. If the URL goes through an ad
redirect (like me-qr.com), it parses the HTML and jumps straight to the real
destination — no "watch an ad to continue" nonsense.
Dependencies: `zbarimg`, `grim`, `slurp`, `imagemagick`

**OCR Text Extractor** (`SUPER+SHIFT+X`)
Snip any text on screen — PDF in a browser, video subtitle, photo, anything —
and it lands on your clipboard. Auto-detects dark/light backgrounds and inverts
accordingly. Upscales 3× before feeding to Tesseract so it actually reads
screen-resolution text instead of guessing. Supports Arabic + English in the
same snip.
Dependencies: `tesseract`, `tesseract-langpack-ara`, `grim`, `slurp`, `imagemagick`

**Screen Recorder** (`SUPER+CTRL+SHIFT+R` start/stop · `SUPER+CTRL+SHIFT+P` pause)
Records a selected area to `~/Videos/`. Audio comes from the output monitor
(what you hear through your device) — not the mic. Video and audio are captured
as separate processes and merged with ffmpeg on stop so neither one blocks the
other from finalizing cleanly. Waybar shows a pulsing red `● REC` while active
and a yellow `⏸ REC` when paused. Left-click the indicator to stop, right-click
to pause/resume.
Dependencies: `wf-recorder`, `parecord`, `ffmpeg`, `grim`, `slurp`

**LeetCode Daily Challenge** (Waybar, left of the clock group)
Shows today's challenge number and title next to the task timer. Pulses red
until solved. Clicks open the problem in Chrome. Auto-detects completion by
reading your Chrome session cookie (decrypted via gnome-keyring) and querying
the LeetCode API — no manual "mark as done." Turns solid green within 2 minutes
of your submission being accepted.
Dependencies: `python3-secretstorage`, `python3-cryptography`, `curl`

**Power Mode Slider** (click the battery icon)
Three-segment rofi slider: Low / Balanced / Max. Shows estimated runtime per
mode next to each option. Self-calibrates by measuring real wattage
(`current_now × voltage_now`) while on battery — the longer you use it unplugged,
the more accurate the numbers get. Low mode dims the screen to 20% and kills
blur/shadows/animations. Max mode turns everything back on.

**Keybind fixes in this update:**
- `SUPER+SHIFT+C` → Cyberpunk theme (was `SUPER+SHIFT+Q`, which clashed with the QR scanner)
- `SUPER+SHIFT+X` → OCR extract (X = eXtract, easy to remember)
- `SUPER+CTRL+SHIFT+R` → Record toggle
- `SUPER+CTRL+SHIFT+P` → Record pause/resume

---

## Author

**Hashim Abdulaziz**
[linkedin.com/in/hashim-abdulaziz](https://www.linkedin.com/in/hashim-abdulaziz/)

They call me Hashing. A reflection of a personal computing philosophy that can
be summarized as: tile everything, overlap nothing, and never reach for the mouse
if a key will do. The neon is non-negotiable.
