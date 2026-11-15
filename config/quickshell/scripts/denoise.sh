#!/usr/bin/env bash
# JoeOS mic noise removal (Capture tab -> Microphone).
#
#   denoise.sh on [light|normal|strong]   start it and make the clean mic the default
#   denoise.sh off                        stop it and go back to the normal mic
#   denoise.sh status                     prints: missing, on or off
#
# Uses RNNoise (package: noise-suppression-for-voice) in a small PipeWire filter that
# runs on its own, so PipeWire itself never needs restarting.
set -u

PLUGIN=/usr/lib/ladspa/librnnoise_ladspa.so
CONF="$HOME/.config/pipewire/joeos-denoise.conf"
STATE="$HOME/.local/state/joeos-denoise-mic"     # the real mic, to go back to
NODE=joeos_clean_mic

running() { pgrep -f "pipewire -c $CONF" >/dev/null; }
notify() { command -v notify-send >/dev/null 2>&1 && notify-send "$@"; true; }

stop_filter() {
    pkill -f "pipewire -c $CONF" 2>/dev/null
    for _ in $(seq 1 20); do running || break; sleep 0.1; done
}

case "${1:-}" in
    status)
        [ -f "$PLUGIN" ] || { echo missing; exit 0; }
        running && echo on || echo off
        ;;

    on)
        [ -f "$PLUGIN" ] || { notify "Noise removal" "Install it first: sudo pacman -S noise-suppression-for-voice"; exit 1; }
        case "${2:-normal}" in
            light)  vad=40 ;;
            strong) vad=90 ;;
            *)      vad=70 ;;
        esac
        # the real mic: whatever is default now, unless that's already our clean one
        cur="$(pactl get-default-source 2>/dev/null)"
        if [ "$cur" != "$NODE" ] && [ -n "$cur" ]; then
            mkdir -p "$(dirname "$STATE")"; echo "$cur" > "$STATE"
        fi
        mic="$(cat "$STATE" 2>/dev/null)"
        [ -n "$mic" ] || { notify "Noise removal" "Couldn't find your microphone"; exit 1; }

        stop_filter
        mkdir -p "$(dirname "$CONF")"
        cat > "$CONF" <<CONFEOF
# Made by the JoeOS bar (Capture tab -> Microphone). Do not edit by hand.
context.properties = { log.level = 0 }
context.spa-libs = {
    audio.convert.* = audioconvert/libspa-audioconvert
    support.*       = support/libspa-support
}
context.modules = [
    { name = libpipewire-module-rt args = { nice.level = -11 } flags = [ ifexists nofail ] }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-filter-chain
        args = {
            node.description = "Clean mic (noise removed)"
            media.name       = "Clean mic (noise removed)"
            filter.graph = {
                nodes = [
                    {
                        type   = ladspa
                        name   = rnnoise
                        plugin = $PLUGIN
                        label  = noise_suppressor_mono
                        control = {
                            "VAD Threshold (%)" = $vad.0
                            "VAD Grace Period (ms)" = 200
                            "Retroactive VAD Grace (ms)" = 0
                        }
                    }
                ]
            }
            capture.props = {
                node.name      = "capture.$NODE"
                node.passive   = true
                audio.rate     = 48000
                target.object  = "$mic"
            }
            playback.props = {
                node.name      = "$NODE"
                media.class    = Audio/Source
                audio.rate     = 48000
            }
        }
    }
]
CONFEOF
        setsid -f pipewire -c "$CONF" >/dev/null 2>&1
        for _ in $(seq 1 40); do
            pactl list short sources 2>/dev/null | grep -q "	$NODE	" && break
            sleep 0.1
        done
        if pactl list short sources 2>/dev/null | grep -q "	$NODE	"; then
            pactl set-default-source "$NODE"
        else
            stop_filter
            notify "Noise removal didn't start" "Your normal mic is still in use"
            exit 1
        fi
        ;;

    off)
        mic="$(cat "$STATE" 2>/dev/null)"
        [ -n "$mic" ] && pactl set-default-source "$mic" 2>/dev/null
        stop_filter
        ;;

    *)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
