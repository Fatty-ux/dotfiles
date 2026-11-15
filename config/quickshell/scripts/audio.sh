#!/usr/bin/env bash
# JoeOS sound output helper (hub: Choose sound output).
#   audio.sh hdmi                    connected monitor/TV speakers that aren't switched on yet:
#                                    card<TAB>profile<TAB>description
#   audio.sh use CARD PROFILE        switch that card to the monitor output, then make it the default
#   audio.sh sink NAME               make NAME the default output, and move everything playing to it
set -u

move_all() {        # send every sound that's playing to the new output, and make sure it isn't muted
    local s="$1"
    pactl set-default-sink "$s" 2>/dev/null
    pactl set-sink-mute "$s" 0 2>/dev/null
    pactl list short sink-inputs 2>/dev/null | cut -f1 | while read -r i; do
        pactl move-sink-input "$i" "$s" 2>/dev/null
    done
    # a monitor output that's at 0% looks like "nothing comes through"
    v="$(pactl get-sink-volume "$s" 2>/dev/null | grep -o '[0-9]*%' | head -n1 | tr -d %)"
    [ -n "$v" ] && [ "$v" -lt 5 ] && pactl set-sink-volume "$s" 60%
}

case "${1:-}" in
    hdmi)
        command -v jq >/dev/null || exit 0
        pactl -f json list cards 2>/dev/null | jq -r '
            .[] | . as $c
            | ($c.ports // {}) as $ports
            | ($c.profiles // {}) | to_entries[]
            | select(.key | test("hdmi|displayport|iec958"; "i"))
            | select(.key | test("input"; "i") | not)
            | select(.value.available != false and .value.available != "no")
            | select(.key != $c.active_profile)
            | [$c.name, .key, .value.description] | @tsv' 2>/dev/null
        ;;
    use)
        card="$2"; prof="$3"
        pactl set-card-profile "$card" "$prof" || { echo fail; exit 0; }
        # wait for the monitor's output to show up, then use it
        for _ in $(seq 1 30); do
            s="$(pactl -f json list sinks 2>/dev/null | jq -r --arg c "$card" '.[] | select(.properties["device.name"] == $c) | .name' | head -n1)"
            [ -n "$s" ] && break
            sleep 0.1
        done
        [ -n "$s" ] && { move_all "$s"; echo ok; } || echo fail
        ;;
    sink)
        move_all "$2"; echo ok
        ;;
    *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
