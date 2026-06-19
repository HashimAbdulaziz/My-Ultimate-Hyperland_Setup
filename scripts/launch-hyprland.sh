#!/usr/bin/env bash

# ─── GPU: INTEL-PRIMARY (hardware MUX + auto-detection) ────────────────────
# Both displays (DP-3 + eDP-1) are wired to the Intel iGPU, so Hyprland's
# Aquamarine backend auto-selects Intel as the primary renderer with no help.
#
# We deliberately DO NOT export AQ_DRM_DEVICES / WLR_DRM_DEVICES. Hardcoding DRM
# device paths is brittle: kernel cardN ordering can change between boots, and a
# literal device list that doesn't match the backend's runtime state makes
# Aquamarine abort (SIGABRT / "IOT instruction core dumped"). When the system
# profile is Intel-primary via the MUX, no explicit device selection is needed.
export XDG_SESSION_TYPE="wayland"

# ─── NVIDIA-forcing vars intentionally DISABLED for Intel-primary ──────────
# Re-enabling these pushes the whole session onto the NVIDIA. LIBVA=nvidia also
# breaks HW video decode (no nvidia-vaapi-driver installed) — leaving it unset
# lets the working Intel iHD VAAPI driver run.
# export LIBVA_DRIVER_NAME="nvidia"
# export GBM_BACKEND="nvidia-drm"
# export __GLX_VENDOR_LIBRARY_NAME="nvidia"
# export NVD_BACKEND="direct"

# ─── Run a single app on the NVIDIA dGPU (no prime-run installed) ───────────
#   __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
#   __VK_LAYER_NV_optimus=NVIDIA_only <command>
# (or install `nvidia-prime` for the `prime-run` wrapper; needs nvidia-drm.modeset=1)

# Launch the window manager
exec Hyprland
