# My Ultimate Hyprland Setup

## Overview

This repository contains my personal, highly customized Hyprland desktop configuration. Designed from the ground up, this setup represents my signature approach to Linux tiling window management, emphasizing robust architecture, modularity, and aesthetic excellence. It is engineered for a seamless, dual-monitor workflow and heavily leverages hot-reloading to ensure maximum productivity without system interruptions.

The core philosophy of this implementation is the ability to maintain multiple distinct, comprehensive visual profiles that can be hot-swapped dynamically.

## Key Features

- **Custom Dual-Theme Architecture**: Seamlessly swap between two meticulously crafted visual profiles:
  - **Neon Cyberpunk**: A vibrant, high-contrast aesthetic utilizing Cyan and Hot Red accents.
  - **Undertale Monochrome**: A 1-bit, grayscale pixelated aesthetic for deep focus.
- **Dynamic Hot-Reloading**: Changes to the theme propagate instantly across the system. The provided `theme-swapper.sh` script orchestrates the assembly of modular configuration files and signals (`SIGUSR1`/`SIGUSR2`) UI components like Waybar and terminal emulators to reload without terminating processes.
- **Optimized Window Management**: Custom Hyprland rules tuned for a 60Hz dual-monitor setup. Includes dynamic layout switching (e.g., standard dwindling vs. scrolling mode), smart grouping, tab management, and floating scratchpads for monitoring tools like `btop`.
- **Integrated Ecosystem**: Pre-configured integration for essential system components:
  - **Hyprland**: Core Wayland compositor.
  - **Waybar**: Highly customized, modular status bar.
  - **Rofi**: Application launcher and clipboard history manager.
  - **SwayNC**: Notification center matching the current aesthetic.
  - **Ghostty / Kitty**: Terminal emulators styled to match active profiles.

## Architecture and Structure

This repository provides the exact modular structure I use to decouple presentation logic from structural configuration:

* `config/hypr/` - Main compositor configuration, layout modes, window rules, and shortcut bindings.
* `config/themes/` - Houses the distinct visual palettes, GTK overrides, Waybar CSS palettes, and terminal color schemes.
* `config/waybar/` - Structural status bar layout, dynamically styled by the active theme.
* `config/rofi/` - Application launcher layouts.
* `scripts/` - Custom shell scripts that drive the logic of the environment. Most notably, the `theme-swapper.sh` which dynamically parses and swaps JSON/CSS files across applications including GTK, VS Code, and Obsidian.

## Installation and Usage

To apply these configurations to your environment, place the respective directories into your `~/.config/` path. The logic within `hyprland.conf` automatically sources theme files based on the state maintained by the `theme-swapper.sh` script.

To switch themes seamlessly, execute the swapper script:
```sh
~/.scripts/theme-swapper.sh cyberpunk
# or
~/.scripts/theme-swapper.sh undertale
```
For convenience, I map these directly to hotkeys (e.g., `SUPER + SHIFT + Q` and `SUPER + SHIFT + E`) to pivot the entire operating system's visual state instantly.

## Author

**Hashim Abdulaziz**
This configuration is a reflection of my personal computing methodology, blending high performance with dynamic, programmatic aesthetics.
