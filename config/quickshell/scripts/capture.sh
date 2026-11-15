#!/usr/bin/env bash
# JoeOS capture helper, used by the Capture tab in the top hub.
#
#   capture.sh shot area|window|screen|all [delay-seconds] [monitor]
#   capture.sh rec  area|screen [none|system|mic|both] [monitor] [computer-sound-% for both]
#   capture.sh stop
#
# Screenshots go to ~/Pictures/Screenshots (and the clipboard).
# Recordings go to ~/Videos/Recordings (needs wf-recorder).
set -u

SHOTS="$HOME/Pictures/Screenshots"
VIDS="$HOME/Videos/Recordings"
LOG="$HOME/.cache/joeos/rec.log"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/joeos-rec.pid"

stamp() { date +%Y-%m-%d_%H-%M-%S; }
MODS="${XDG_RUNTIME_DIR:-/tmp}/joeos-rec.mods"

# "both": mix the computer sound and the mic into one temporary input for the recording
mix_start() {
    mix_stop
    local sink src m1 m2 m3
    sink="$(pactl get-default-sink 2>/dev/null)"; src="$(pactl get-default-source 2>/dev/null)"
    [ -n "$sink" ] && [ -n "$src" ] || return 1
    m1="$(pactl load-module module-null-sink sink_name=joeos_rec_mix sink_properties=device.description=JoeOS-Recording-Mix)" || return 1
    m2="$(pactl load-module module-loopback source="$sink.monitor" sink=joeos_rec_mix latency_msec=30)"
    m3="$(pactl load-module module-loopback source="$src" sink=joeos_rec_mix latency_msec=30)"
    echo "$m3 $m2 $m1" > "$MODS"
    # turn the computer sound down in the mix so your voice isn't drowned out
    local lvl="${SYSLVL:-100}" idx
    if [ "$lvl" != 100 ] && command -v jq >/dev/null; then
        sleep 0.3
        idx="$(pactl -f json list sink-inputs 2>/dev/null | jq -r --arg m "$m2" '.[] | select((.owner_module | tostring) == $m) | .index' | head -n1)"
        [ -n "$idx" ] && pactl set-sink-input-volume "$idx" "${lvl}%"
    fi
}
# take the temporary mix away again
mix_stop() {
    [ -f "$MODS" ] || return 0
    for m in $(cat "$MODS"); do pactl unload-module "$m" 2>/dev/null; done
    rm -f "$MODS"
}
notify() { command -v notify-send >/dev/null 2>&1 && notify-send "$@"; true; }

# Let the user click a window on the screens they can see; prints its geometry for grim
window_geom() {
    local ws
    ws="$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')"
    hyprctl -j clients \
        | jq -r --argjson ws "$ws" \
            '.[] | select(.mapped and (.workspace.id as $w | $ws | index($w))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
        | slurp -r
}

case "${1:-}" in
    shot)
        mode="${2:-area}"; delay="${3:-0}"; mon="${4:-}"
        [ -z "$mon" ] && mon="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
        mkdir -p "$SHOTS"
        f="$SHOTS/$(stamp).png"
        g=""
        case "$mode" in
            area)   g="$(slurp)" || exit 1 ;;
            window) g="$(window_geom)" || exit 1 ;;
        esac
        [ "$delay" -gt 0 ] 2>/dev/null && sleep "$delay"
        case "$mode" in
            area|window) [ -n "$g" ] && grim -g "$g" "$f" ;;
            screen)      grim -o "$mon" "$f" ;;
            *)           grim "$f" ;;
        esac || exit 1
        wl-copy < "$f"
        notify -i "$f" "Screenshot saved" "Also copied to the clipboard"
        ;;

    rec)
        mode="${2:-area}"; audio="${3:-none}"; mon="${4:-}"; SYSLVL="${5:-100}"
        [ -z "$mon" ] && mon="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
        command -v wf-recorder >/dev/null 2>&1 || { notify "Can't record" "Install wf-recorder first"; exit 1; }
        pgrep -f "^wf-recorder" >/dev/null && exit 0
        mkdir -p "$VIDS" "$(dirname "$LOG")"
        echo "$$" > "$PIDFILE"
        f="$VIDS/$(stamp).mp4"
        args=(-y -f "$f")
        case "$mode" in
            area)   g="$(slurp)" || { rm -f "$PIDFILE"; exit 1; }; args+=(-g "$g") ;;
            screen) [ -n "$mon" ] && args+=(-o "$mon") ;;
        esac
        case "$audio" in
            system) args+=("--audio=$(pactl get-default-sink 2>/dev/null).monitor") ;;
            mic)    args+=("--audio=$(pactl get-default-source 2>/dev/null)") ;;
            both)   if mix_start; then args+=("--audio=joeos_rec_mix.monitor")
                    else notify "Recording without sound" "Couldn't mix the mic and computer sound"; fi ;;
        esac
        echo "== $(date) wf-recorder ${args[*]}" >> "$LOG"
        # run the recorder in the background (with job control, so Ctrl+C still reaches it)
        set -m
        wf-recorder "${args[@]}" </dev/null >>"$LOG" 2>&1 &
        rp=$!
        echo "$rp" > "$PIDFILE.rec"
        trap 'kill -INT "$rp" 2>/dev/null' INT TERM
        while kill -0 "$rp" 2>/dev/null; do wait "$rp"; done
        code=$?
        rm -f "$PIDFILE" "$PIDFILE.rec"
        mix_stop
        echo "== exited ($code)" >> "$LOG"
        if [ -s "$f" ]; then
            notify "Recording saved" "$f" &
        else
            notify "Recording failed" "Nothing was saved. Details: ~/.cache/joeos/rec.log" &
        fi
        ;;

    stop)
        # cancel a box that's still being dragged
        pkill -x slurp 2>/dev/null
        rp="$(cat "$PIDFILE.rec" 2>/dev/null)"
        pids() { { [ -n "$rp" ] && kill -0 "$rp" 2>/dev/null && echo "$rp"; pgrep -f "^wf-recorder"; } | sort -u; }
        waitgone() { for _ in $(seq 1 "$1"); do [ -z "$(pids)" ] && return 0; sleep 0.1; done; return 1; }
        [ -z "$(pids)" ] && { rm -f "$PIDFILE" "$PIDFILE.rec"; exit 0; }
        # wf-recorder finishes the video on Ctrl+C (SIGINT): ask, ask again, then insist
        kill -INT $(pids) 2>/dev/null;  waitgone 25 && exit 0
        kill -INT $(pids) 2>/dev/null;  waitgone 25 && exit 0
        kill -TERM $(pids) 2>/dev/null; waitgone 30 && exit 0
        kill -KILL $(pids) 2>/dev/null
        mix_stop
        notify "Recording stopped" "It had to be forced, so the end of the video may be cut off" &
        ;;

    *)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
