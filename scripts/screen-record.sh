#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Copyright (c) 2026 Hashim Abdulaziz
#  https://www.linkedin.com/in/hashim-abdulaziz/
#  They call me Hashing — feel free to use this, just keep my name in the code.
# ─────────────────────────────────────────────────────────────
# Screen recorder — video via wf-recorder, audio via parecord (output only, no mic)
# Merges both with ffmpeg on stop.

CACHE="$HOME/.cache/screen-record"
mkdir -p "$CACHE" "$HOME/Videos"

VPID_F="$CACHE/video_pid"
APID_F="$CACHE/audio_pid"
STATE_F="$CACHE/state"
OUT_F="$CACHE/outfile"
VTMP="$CACHE/video_tmp.mp4"
ATMP="$CACHE/audio_tmp.wav"
SINK_F="$CACHE/sink_state"   # "sink_name:was_muted"

_state() { cat "$STATE_F" 2>/dev/null || echo "idle"; }

# ── start ──────────────────────────────────────────────────────────────────
start_rec() {
    local area
    area=$(slurp -d 2>/dev/null) || exit 0

    local outfile="$HOME/Videos/rec_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    echo "$outfile" > "$OUT_F"

    local sink monitor was_muted
    sink=$(pactl get-default-sink 2>/dev/null)
    monitor="${sink}.monitor"
    was_muted=$(pactl get-sink-mute "$sink" 2>/dev/null | grep -c "yes")
    echo "${sink}:${was_muted}" > "$SINK_F"

    # Unmute output so the monitor source captures audio
    # (PipeWire monitor sees silence when sink is muted — unavoidable)
    [ "$was_muted" -gt 0 ] && pactl set-sink-mute "$sink" 0

    pactl set-source-volume "$monitor" 130% 2>/dev/null

    # Audio: parecord from output monitor — explicitly named, no mic path
    parecord --device="$monitor" --file-format=wav --channels=2 --rate=48000 "$ATMP" &
    echo $! > "$APID_F"

    # Video: wf-recorder with NO -a flag — zero chance of mic involvement
    wf-recorder -g "$area" -f "$VTMP" &
    echo $! > "$VPID_F"

    sleep 0.6
    if kill -0 "$(cat "$VPID_F" 2>/dev/null)" 2>/dev/null; then
        echo "recording" > "$STATE_F"
        notify-send -t 2000 -i media-record "Recording started" \
            "● REC +  output audio   $(basename "$outfile")"
    else
        _restore_audio
        echo "idle" > "$STATE_F"
        notify-send -t 3000 -i dialog-error "Recorder" "wf-recorder failed to start"
    fi
}

# ── restore audio state ────────────────────────────────────────────────────
_restore_audio() {
    local sink_state sink was_muted monitor
    sink_state=$(cat "$SINK_F" 2>/dev/null)
    sink="${sink_state%%:*}"
    was_muted="${sink_state##*:}"
    monitor="${sink}.monitor"
    pactl set-source-volume "$monitor" 100% 2>/dev/null
    [ "$was_muted" = "1" ] && pactl set-sink-mute "$sink" 1 2>/dev/null
    rm -f "$SINK_F"
}

# ── stop ───────────────────────────────────────────────────────────────────
stop_rec() {
    local vpid apid outfile
    vpid=$(cat "$VPID_F" 2>/dev/null)
    apid=$(cat "$APID_F" 2>/dev/null)
    outfile=$(cat "$OUT_F" 2>/dev/null)

    [ -n "$vpid" ] && kill -CONT "$vpid" 2>/dev/null && kill -INT "$vpid" 2>/dev/null
    [ -n "$apid" ] && kill -INT  "$apid" 2>/dev/null

    # wait can't wait for non-child PIDs — poll until both processes exit
    local deadline=$(( $(date +%s) + 8 ))
    while { kill -0 "$vpid" 2>/dev/null || kill -0 "$apid" 2>/dev/null; } \
          && [ "$(date +%s)" -lt "$deadline" ]; do
        sleep 0.15
    done

    _restore_audio
    echo "idle" > "$STATE_F"
    rm -f "$VPID_F" "$APID_F"

    # Merge video + audio — only after both processes have fully exited
    if [ -f "$VTMP" ] && [ -f "$ATMP" ]; then
        notify-send -t 2000 "Recorder" "Saving…"
        ffmpeg -y -i "$VTMP" -i "$ATMP" \
               -c:v copy -c:a aac -b:a 192k -shortest \
               "$outfile" 2>/dev/null
        rm -f "$VTMP" "$ATMP"
        if [ -f "$outfile" ]; then
            local size; size=$(du -h "$outfile" 2>/dev/null | cut -f1)
            notify-send -t 6000 -i video-x-generic "Recording saved  ($size)" \
                "$(basename "$outfile")\n~/Videos/"
        else
            notify-send -t 5000 -i dialog-error "Recorder" "ffmpeg merge failed — raw files kept in ~/.cache/screen-record/"
        fi
    elif [ -f "$VTMP" ]; then
        mv "$VTMP" "$outfile"
        notify-send -t 4000 -i video-x-generic "Saved (no audio)" "$(basename "$outfile")"
    else
        notify-send -t 4000 -i dialog-warning "Recorder" "No recording found — did it start correctly?"
    fi
}

# ── pause / resume ─────────────────────────────────────────────────────────
pause_toggle() {
    local vpid apid
    vpid=$(cat "$VPID_F" 2>/dev/null); apid=$(cat "$APID_F" 2>/dev/null)
    [ -z "$vpid" ] && exit 0
    case "$(_state)" in
        recording)
            kill -STOP "$vpid" "$apid" 2>/dev/null
            echo "paused" > "$STATE_F"
            notify-send -t 1200 -i media-playback-pause "Recording paused" ""
            ;;
        paused)
            kill -CONT "$vpid" "$apid" 2>/dev/null
            echo "recording" > "$STATE_F"
            notify-send -t 1200 -i media-record "Recording resumed" ""
            ;;
    esac
}

# ── waybar status ──────────────────────────────────────────────────────────
status() {
    case "$(_state)" in
        recording) printf '{"text":"● REC ","class":"recording","tooltip":"Recording — left: stop · right: pause"}\n' ;;
        paused)    printf '{"text":"⏸ REC","class":"paused","tooltip":"Paused — left: stop · right: resume"}\n' ;;
        *)         printf '{"text":"","class":"idle"}\n' ;;
    esac
}

case "$1" in
    start)        start_rec ;;
    stop)         stop_rec ;;
    toggle)       [ "$(_state)" = "idle" ] && start_rec || stop_rec ;;
    pause-toggle) pause_toggle ;;
    status)       status ;;
    *)            [ "$(_state)" = "idle" ] && start_rec || stop_rec ;;
esac
