#!/usr/bin/env bash
# JoeOS: makes apps installed as Flatpaks show up in the launcher (search, pinning, taskbar).
#
# Flatpak keeps its app shortcuts in its own folders, which the bar only sees if the session was
# started with them on its search list. This copies each one into ~/.local/share/applications
# (which is always searched), with the icon pointed straight at the picture so it shows too.
# Copies are marked X-JoeOS-Flatpak=true; they're updated and removed with the app.
# Run by the bar at startup and after the Store installs or removes a Flatpak.
set -u
dest="$HOME/.local/share/applications"
mkdir -p "$dest"
exports=("$HOME/.local/share/flatpak/exports/share" "/var/lib/flatpak/exports/share")

for exp in "${exports[@]}"; do
    [ -d "$exp/applications" ] || continue
    for f in "$exp"/applications/*.desktop; do
        [ -e "$f" ] || continue
        name="$(basename "$f")"
        out="$dest/$name"
        # never touch a shortcut you (or another program) made yourself
        if [ -e "$out" ] && ! grep -q '^X-JoeOS-Flatpak=true' "$out"; then continue; fi
        icon="$(sed -n 's/^Icon=//p' "$f" | head -n1)"
        pic=""
        if [ -n "$icon" ] && [ "${icon#/}" = "$icon" ]; then
            for size in scalable 512x512 256x256 128x128 96x96 64x64 48x48; do
                for ext in svg png; do
                    c="$exp/icons/hicolor/$size/apps/$icon.$ext"
                    if [ -f "$c" ]; then pic="$c"; break 2; fi
                done
            done
        fi
        tmp="$(mktemp)"
        if [ -n "$pic" ]; then sed "s|^Icon=.*|Icon=$pic|" "$f" > "$tmp"; else cat "$f" > "$tmp"; fi
        printf 'X-JoeOS-Flatpak=true\n' >> "$tmp"
        if cmp -s "$tmp" "$out"; then rm -f "$tmp"; else mv "$tmp" "$out"; chmod 644 "$out"; fi
    done
done

# remove the copies of apps that were uninstalled
for out in "$dest"/*.desktop; do
    [ -e "$out" ] || continue
    grep -q '^X-JoeOS-Flatpak=true' "$out" || continue
    n="$(basename "$out")"
    found=0
    for exp in "${exports[@]}"; do [ -e "$exp/applications/$n" ] && found=1; done
    [ "$found" = 1 ] || rm -f "$out"
done
command -v update-desktop-database >/dev/null && update-desktop-database "$dest" >/dev/null 2>&1
exit 0
