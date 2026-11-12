#!/usr/bin/env bash
# Finds and removes Noctalia so your setup runs on Quickshell alone.
# It shows everything it found first and asks before removing anything.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/ui.sh
source "$REPO_DIR/lib/ui.sh"

banner
section "Looking for Noctalia"

mapfile -t PKGS < <(pacman -Qq 2>/dev/null | grep -i noctalia || true)
declare -a DIRS=()
for d in "$HOME/.config/noctalia" "$HOME/.cache/noctalia" "$HOME/.local/share/noctalia" "$HOME/.local/state/noctalia"; do
    [ -e "$d" ] && DIRS+=("$d")
done

if [ "${#PKGS[@]}" -eq 0 ]; then ok "no Noctalia packages installed"; else for p in "${PKGS[@]}"; do item_line missing "$p" "package installed"; done; fi
if [ "${#DIRS[@]}" -eq 0 ]; then ok "no Noctalia folders found"; else for d in "${DIRS[@]}"; do item_line missing "${d/#$HOME/~}" "folder found"; done; fi
pgrep -fa noctalia >/dev/null 2>&1 && warn "Noctalia is running right now"

section "Lines in your Hyprland config that mention Noctalia"
HITS="$(grep -rn -i noctalia "$HOME/.config/hypr" 2>/dev/null || true)"
if [ -n "$HITS" ]; then
    printf '%s\n' "$HITS" | sed 's/^/    /'
    warn "I won't edit your Hyprland config blindly. Remove or comment those lines yourself,"
    note "or paste them to Claude and ask for the exact edit."
else
    ok "nothing in ~/.config/hypr mentions it"
fi

if [ "${#PKGS[@]}" -eq 0 ] && [ "${#DIRS[@]}" -eq 0 ]; then echo; exit 0; fi

if ask "Remove the Noctalia packages and move its folders to a backup?" N; then
    pkill -f noctalia 2>/dev/null || true
    [ "${#PKGS[@]}" -gt 0 ] && sudo pacman -Rns --noconfirm "${PKGS[@]}"
    BK="$HOME/.dotfiles-backup/noctalia-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BK"
    for d in "${DIRS[@]}"; do mv "$d" "$BK/"; done
    ok "Noctalia removed. Its folders are saved in ${BK/#$HOME/~} in case you want anything back."
    info "Now start Quickshell:  pkill quickshell; setsid quickshell >/dev/null 2>&1 &"
fi
echo
