-- #######################################################################################
-- HASHIM'S HYPRLAND MASTER CONFIGURATION (Lua)
-- Theme: Neon Cyberpunk (Cyan & Hot Red) | Optimized for Dual-Monitor 60Hz
-- Migrated from hyprlang to Lua for Hyprland 0.55+
-- #######################################################################################


--------------------
---- MONITORS ------
--------------------

-- External AOC Monitor (Primary) is locked to its hardware max of 60Hz. Placed on the left (0x0)
hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

-- Check laptop lid state every time this config is reloaded to prevent "ghost" rendering!
hl.exec_cmd("~/.config/hypr/clamshell.sh")


--------------------------
---- WORKSPACE RULES -----
--------------------------

-- Force Workspaces 1, 2, and 3 to ALWAYS open on the External Monitor
hl.workspace_rule({ workspace = 1, monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = 2, monitor = "DP-3" })
hl.workspace_rule({ workspace = 3, monitor = "DP-3" })

-- Send Workspaces 4 and 5 to the Laptop Screen
hl.workspace_rule({ workspace = 4, monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = 5, monitor = "eDP-1" })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local menu     = 'pkill rofi || rofi -show drun -theme ~/.config/rofi/launcher/type-7/style-1.rasi'


-------------------
---- AUTOSTART ----
-------------------

-- These background services boot up the second you log in
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")                                            -- Top status bar
    hl.exec_cmd("wl-paste --type text --watch cliphist store")       -- Text clipboard manager
    hl.exec_cmd("wl-paste --type image --watch cliphist store")      -- Image clipboard manager
    hl.exec_cmd("hypridle &")                                        -- Idle daemon (auto-lock screen)
    hl.exec_cmd("swaync &")                                          -- Notification center
    hl.exec_cmd("hyprpaper")                                         -- Wallpaper engine
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("sleep 1 && hyprpm reload -n")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")

-- ─── GPU: INTEL-PRIMARY RENDERING ───
-- Both displays are wired to the Intel iGPU; the MUX + Hyprland auto-detection
-- pick Intel as the primary renderer. Do NOT inject AQ_DRM_DEVICES /
-- WLR_DRM_DEVICES here: hardcoded DRM device paths make Aquamarine abort
-- (SIGABRT / "IOT instruction core dumped"). NVIDIA-forcing vars stay disabled
-- (LIBVA=nvidia also breaks HW video decode — no nvidia-vaapi-driver installed,
-- so the working Intel iHD driver is used instead).
hl.env("XDG_SESSION_TYPE", "wayland")
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("AQ_DRM_DEVICES", ...)   -- never hardcode; crashes Aquamarine
-- hl.env("WLR_DRM_DEVICES", ...)  -- never hardcode; crashes Aquamarine


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,

        -- The Neon Cyberpunk Borders (Cyan fading into Hot Red)
        col = {
            active_border   = { colors = { "rgba(00e5ffee)", "rgba(ff003cee)" }, angle = 45 },
            inactive_border = "rgba(1a1a26cc)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Cyan glowing shadow under floating windows
        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color        = "rgba(00ffff44)",
        },

        -- Glassmorphism Settings (Optimized for GPU Performance)
        blur = {
            enabled  = true,
            size     = 5,       -- Size 5 provides clean blur without heavy GPU tax
            passes   = 2,       -- Two passes for quality glassmorphism
            vibrancy = 0.1696,
        },
    },

    -- ==========================================
    -- Group (Tab) Bar Styling
    -- ==========================================
    group = {
        col = {
            border_active   = { colors = { "rgba(00e5ffee)", "rgba(ff003cee)" }, angle = 45 },
            border_inactive = "rgba(1a1a26cc)",
        },

        groupbar = {
            font_family    = "JetBrainsMono Nerd Font",
            font_size      = 10,
            text_color     = "rgba(e0e0e0ff)",
            height         = 16,
            gradients      = false,
            render_titles  = true,

            -- Muted Midnight Purple for the active tab
            col = {
                active   = "rgba(3a1f5dff)",
                inactive = "rgba(1a1a26cc)",
            },
        },
    },
})

-- Apply blur to top bars and menus
hl.layer_rule({
    name  = "blur-waybar",
    match = { namespace = "waybar" },
    blur  = true,
    ignorezero = true,
})

hl.layer_rule({
    name  = "blur-rofi",
    match = { namespace = "rofi" },
    blur  = true,
    ignorezero = true,
})


-- ==========================================
-- Animations (Fast & Smooth)
-- ==========================================

hl.config({
    animations = {
        enabled = true,
    },
})

-- Bezier curves
hl.curve("macEase",      { type = "bezier", points = { {0.16, 1},    {0.3, 1}    } })
hl.curve("snappy",       { type = "bezier", points = { {0.15, 0.9},  {0.1, 1.0}  } })
hl.curve("slideEase",    { type = "bezier", points = { {0.25, 1},    {0.5, 1}    } })
hl.curve("slideEaseOut", { type = "bezier", points = { {0.16, 1},    {0.3, 1}    } })

-- Windows
hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "snappy",  style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "snappy",  style = "popin 90%" })
hl.animation({ leaf = "border",     enabled = true, speed = 2, bezier = "snappy" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2, bezier = "snappy" })

-- Workspaces
hl.animation({ leaf = "workspaces",       enabled = true, speed = 4, bezier = "macEase", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "snappy",  style = "fade" })

-- Rofi drop-down animations (Dynamic Island style)
hl.animation({ leaf = "layers",        enabled = true, speed = 3, bezier = "slideEase",    style = "slide" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3, bezier = "slideEase",    style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2, bezier = "slideEaseOut", style = "slide" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3, bezier = "slideEase" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "slideEaseOut" })


-- ================================================================
--  Rofi window rules — pins rofi to top of screen so slide works
-- ================================================================
hl.window_rule({
    name  = "rofi-rules",
    match = { class = "^(rofi)$" },
    float       = true,
    pin         = true,
    stayfocused = true,
    noborder    = true,
    noshadow    = true,
})


--------------------------
---- LAYOUT SETTINGS -----
--------------------------

hl.config({
    dwindle = {
        pseudotile    = true,
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us, ara",
        kb_options = "grp:win_space_toggle",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- ─── Core System ───
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- ─── Waybar Controls ───
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))       -- Toggle Hide/Show
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("killall waybar; waybar &"))      -- Panic restart

-- ─── Fullscreen Modes ───
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = 1 }))           -- macOS Maximize
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 0 }))           -- True Fullscreen

-- ─── Window Tiling Controls ───
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin())                              -- Pin floating window
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/toggle-scroll.sh scrolling"))  -- Toggle Scrolling Layout

-- Move Focus (Arrow Keys)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Swap Physical Window Positions (Shift + Arrow Keys)
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))

-- ─── Workspace Navigation ───
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))  -- Quick-toggle to last workspace

for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end

-- Mouse Controls (Scroll workspaces, Drag to move/resize)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- ─── Utilities & Tools ───
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("~/.scripts/theme-swapper.sh cyberpunk"))                               -- Theme: Cyberpunk
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("~/.scripts/theme-swapper.sh undertale"))                               -- Theme: Undertale
hl.bind("SUPER + Y", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))   -- Clipboard History
hl.bind("SUPER + O", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))                             -- Screenshot to Clipboard
hl.bind("SUPER + D", hl.dsp.exec_cmd('sh -c \'grim -g "$(slurp)" - | swappy -f -\''))               -- Screenshot to Editor
hl.bind("SUPER + B", hl.dsp.exec_cmd("blueman-manager"))                                             -- Bluetooth
hl.bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t -sw"))                                        -- Notifications
hl.bind("SUPER + A", hl.dsp.exec_cmd("pavucontrol"))                                                 -- Audio Mixer

-- ─── Floating Terminal Apps ───
hl.bind("SUPER + E",      hl.dsp.exec_cmd("kitty --class ranger -e ranger"))                         -- Ranger File Manager
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("kitty --class btop -e btop"))                             -- Btop System Monitor

-- ─── Dropdown Scratchpad ───
hl.bind("SUPER + grave", hl.dsp.workspace.toggle_special("scratchpad"))                              -- Toggle with `~` key

-- ─── Hardware Media Keys ───
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Disable laptop screen when lid is closed, re-enable when open
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("~/.config/hypr/clamshell.sh"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/clamshell.sh"), { locked = true })

-- ─── Taskwarrior Hotkeys ───
hl.bind("SUPER + T",         hl.dsp.exec_cmd("~/.scripts/task-toggle.sh"))
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("kitty --class task-manager env HIDE_FETCH=1 zsh -c 'clear; task; exec zsh'"))


-- ==========================================
-- Tabbed Group & Override Controls
-- ==========================================
hl.bind("ALT + Tab",         hl.dsp.exec_cmd("~/.config/hypr/smart_tab.sh f"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("~/.config/hypr/smart_tab.sh b"))

hl.bind("SUPER + G",         hl.dsp.group.toggle())                               -- Turn active window into a group
hl.bind("SUPER + SHIFT + G", hl.dsp.group.move_out())                             -- Rip active tab out of the group

-- Push current window into an adjacent group
hl.bind("SUPER + CTRL + left",  hl.dsp.group.move_into({ direction = "left" }))
hl.bind("SUPER + CTRL + right", hl.dsp.group.move_into({ direction = "right" }))
hl.bind("SUPER + CTRL + up",    hl.dsp.group.move_into({ direction = "up" }))
hl.bind("SUPER + CTRL + down",  hl.dsp.group.move_into({ direction = "down" }))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Core XWayland and Focus fixes
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- App-specific Opacity
hl.window_rule({
    name  = "obsidian-opacity",
    match = { class = "^(obsidian)$" },
    opacity = { active = 0.92, inactive = 0.75 },
})

hl.window_rule({
    name  = "kitty-opacity",
    match = { class = "^(kitty)$" },
    opacity = { active = 0.97, inactive = 0.70 },
})

-- ─── Floating Tool Rules (Ranger & Btop) ───
hl.window_rule({
    name  = "ranger-float",
    match = { class = "^(ranger)$" },
    float  = true,
    size   = "70% 70%",
    center = true,
})

hl.window_rule({
    name  = "btop-float",
    match = { class = "^(btop)$" },
    float  = true,
    size   = "70% 70%",
    center = true,
})

-- ─── Floating Task Manager Rules ───
hl.window_rule({
    name  = "task-manager-float",
    match = { class = "^(task-manager)$" },
    float     = true,
    size      = "60% 50%",
    center    = true,
    animation = "popin 80%",
})

-- ─── Drop-down Scratchpad Rules ───
hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "kitty --class kitty-scratchpad" })

hl.window_rule({
    name  = "scratchpad-rules",
    match = { class = "^(kitty-scratchpad)$" },
    float    = true,
    size     = "60% 50%",
    center   = true,
    noborder = true,
    opacity  = { active = 1.0, inactive = 1.0 },
    workspace = "special:scratchpad silent",
})

-- ==========================================
-- The Mental Map: Smart Workspace Routing
-- ==========================================

-- 1. Web Browsers -> Workspace 1 (Auto-Tabbed)
hl.window_rule({
    name  = "browsers-ws1",
    match = { class = "^(google-chrome|firefox)$" },
    workspace = 1,
    group     = "set",
})

-- 2. Code Editors -> Workspace 2 (Auto-Tabbed)
hl.window_rule({
    name  = "editors-ws2",
    match = { class = "^(code|jetbrains-idea|codeblocks)$" },
    workspace = 2,
    group     = "set",
})

-- 3. Standard Terminals -> Workspace 3 (Auto-Tabbed)
hl.window_rule({
    name  = "terminals-ws3",
    match = { class = "^(kitty)$" },
    workspace = 3,
    group     = "set",
})

-- 4. Comms & Audio -> Workspace 4 (Auto-Tabbed)
hl.window_rule({
    name  = "comms-ws4",
    match = { class = "^(discord|org\\.telegram\\.desktop|com\\.ktechpit\\.whatsie|Spotify)$" },
    workspace = 4,
    group     = "set",
})


-- ==========================================
-- Cursor Plugin (macOS Shake to Find)
-- ==========================================
hl.config({
    plugin = {
        ["dynamic-cursors"] = {
            enabled = true,
            mode    = "none",

            shake = {
                enabled   = true,
                nearest   = false,
                threshold = 4.5,
                base      = 1.0,
                speed     = 3.5,
                influence = 5.5,
                limit     = 0.0,
            },
        },
    },
})
