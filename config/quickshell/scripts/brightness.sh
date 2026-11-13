#!/usr/bin/env bash
# JoeOS brightness helper, used by the right-side bar.
#
#   brightness.sh list           one line per screen:  id|connector|name|value|max
#                                (prints NODDC if ddcutil isn't installed)
#   brightness.sh set <id> <0-100>
#
# Desktop monitors are controlled over DDC/CI with ddcutil.
# A laptop's built-in screen (if any) uses brightnessctl and has the id "bl".
set -u

case "${1:-}" in
    list)
        # built-in screen
        if command -v brightnessctl >/dev/null 2>&1 && brightnessctl -l -c backlight 2>/dev/null | grep -q "Device"; then
            pct="$(brightnessctl -m -c backlight 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%')"
            echo "bl|eDP-1|Built-in screen|${pct:-50}|100"
        fi

        command -v ddcutil >/dev/null 2>&1 || { echo "NODDC"; exit 0; }

        # "Display N" blocks: pick out the number, the connector (DP-1, HDMI-A-1...) and the model
        ddcutil detect --brief 2>/dev/null | awk '
            function flush() { if (d != "") print d "|" conn "|" mon; d = ""; conn = ""; mon = "" }
            /^[^ \t]/              { flush(); if ($1 == "Display" && $2 ~ /^[0-9]+$/) d = $2 }   # every block starts at column 0
            /DRM connector:/       { conn = $NF; sub(/^card[0-9]+-/, "", conn) }
            /Monitor:/             { m = $0; sub(/.*Monitor:[ \t]*/, "", m); n = split(m, p, ":"); mon = (n >= 2 ? p[2] : m) }
            /^[ \t]+Model:/        { if (mon == "") { m = $0; sub(/.*Model:[ \t]*/, "", m); mon = m } }
            END                    { flush() }
        ' | while IFS='|' read -r d conn mon; do
            # "VCP 10 C 50 100"  ->  current 50, max 100
            read -r tag code kind cur max <<< "$(ddcutil getvcp 10 --brief --display "$d" 2>/dev/null)"
            if [ "${tag:-}" = "VCP" ]; then
                echo "$d|$conn|${mon:-Monitor $d}|${cur:-0}|${max:-100}"
            fi
        done
        ;;

    set)
        id="${2:-}"; pct="${3:-50}"
        if [ "$id" = "bl" ]; then
            brightnessctl set "${pct}%" >/dev/null 2>&1
        else
            ddcutil setvcp 10 "$pct" --display "$id" --noverify >/dev/null 2>&1
        fi
        ;;

    *)
        sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
