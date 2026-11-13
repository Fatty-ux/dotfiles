#!/usr/bin/env bash
# JoeOS capture helper, used by the Capture tab in the top hub.
#
#   capture.sh shot area|window|screen|all [delay-seconds] [monitor]
#   capture.sh rec  area|screen [none|system|mic] [monitor]
#   capture.sh stop
#
# Screenshots go to ~/Pictures/Screenshots (and the clipboard).
# Recordings go to ~/Videos/Recordings (needs wf-recorder).
set -u

SHOTS="$HOME/Pictures/Screenshots"
VIDS="$HOME/Videos/Recordings"

stamp() { date +%Y-%m-%d_%H-%M-%S; }
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
        mode="${2:-area}"; audio="${3:-none}"; mon="${4:-}"
        command -v wf-recorder >/dev/null 2>&1 || { notify "Can't record" "Install wf-recorder first"; exit 1; }
        pgrep -x wf-recorder >/dev/null && exit 0
        mkdir -p "$VIDS"
        f="$VIDS/$(stamp).mp4"
        args=(-f "$f")
        case "$mode" in
            area)   g="$(slurp)" || exit 1; args+=(-g "$g") ;;
            screen) args+=(-o "$mon") ;;
        esac
        case "$audio" in
            system) args+=("--audio=$(pactl get-default-sink 2>/dev/null).monitor") ;;
            mic)    args+=("--audio=$(pactl get-default-source 2>/dev/null)") ;;
        esac
        wf-recorder "${args[@]}"
        [ -s "$f" ] && notify "Recording saved" "$f"
        ;;

    stop)
        pkill -INT -x wf-recorder
        ;;

    *)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
