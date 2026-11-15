#!/usr/bin/env bash
# JoeOS Bluetooth helper for the hub's Bluetooth page (uses bluetoothctl).
#   bt.sh status                 powered: yes/no
#   bt.sh list                   one device per line: mac<TAB>name<TAB>paired<TAB>connected<TAB>icon<TAB>battery
#   bt.sh scan                   look for new devices for 25 seconds
#   bt.sh pair MAC               pair, trust and connect a new device (controllers, headphones...)
#   bt.sh connect|disconnect|remove MAC
#   bt.sh power on|off
set -u
cmd="${1:-}"; mac="${2:-}"

case "$cmd" in
    status)
        bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo yes || echo no
        ;;
    list)
        bluetoothctl devices 2>/dev/null | while read -r _ m name; do
            [ -n "$m" ] || continue
            info="$(bluetoothctl info "$m" 2>/dev/null)"
            get() { printf '%s\n' "$info" | sed -n "s/^[[:space:]]*$1: //p" | head -n1; }
            bat="$(printf '%s\n' "$info" | sed -n 's/.*Battery Percentage: .*(\([0-9]*\)).*/\1/p' | head -n1)"
            alias_="$(get Alias)"
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$m" "${alias_:-$name}" "$(get Paired)" "$(get Connected)" "$(get Icon)" "$bat"
        done
        ;;
    scan)
        bluetoothctl power on >/dev/null 2>&1
        timeout 26 bluetoothctl --timeout 25 scan on >/dev/null 2>&1
        ;;
    pair)
        # bluetoothctl needs to stay open while pairing, so feed it the steps with pauses in between
        bluetoothctl power on >/dev/null 2>&1
        {
            printf 'agent NoInputNoOutput\ndefault-agent\n'
            sleep 1
            printf 'pair %s\n' "$mac"
            sleep 10
            printf 'trust %s\n' "$mac"
            sleep 1
            printf 'connect %s\n' "$mac"
            sleep 6
            printf 'quit\n'
        } | bluetoothctl >/dev/null 2>&1
        bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && echo ok || echo fail
        ;;
    connect)
        bluetoothctl power on >/dev/null 2>&1
        bluetoothctl connect "$mac" >/dev/null 2>&1
        bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && echo ok || echo fail
        ;;
    disconnect) bluetoothctl disconnect "$mac" >/dev/null 2>&1; echo ok ;;
    remove)     bluetoothctl remove "$mac" >/dev/null 2>&1; echo ok ;;
    power)      bluetoothctl power "${2:-on}" >/dev/null 2>&1; echo ok ;;
    *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
