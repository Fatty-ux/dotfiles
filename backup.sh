#!/usr/bin/env bash
# Copies your current settings into this repo so you can commit them to GitHub.
#
#   ./backup.sh                 copy configs + package lists into the repo
#   ./backup.sh --link          also replace the originals with links into the repo,
#                               so editing a file on your system edits the repo copy
#   ./backup.sh --wallpapers    also copy ~/Pictures/Wallpapers into the repo
#
# Nothing is deleted: when --link is used the old copy is moved to ~/.dotfiles-backup/.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ui.sh
source "$REPO_DIR/lib/ui.sh"

LINK=0
WALLPAPERS=0
for arg in "$@"; do
    case "$arg" in
        --link)       LINK=1 ;;
        --wallpapers) WALLPAPERS=1 ;;
        -h|--help)    sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) err "Unknown option: $arg"; exit 1 ;;
    esac
done

# Things in ~/.config that belong in the repo. Add your own names here.
# (kitty, fastfetch and xdg-terminals.list are not listed: they already live in this repo and are linked out of it)
CONFIG_ITEMS=(
    hypr quickshell fish
    gtk-3.0 gtk-4.0 qt5ct qt6ct nwg-look
    mimeapps.list
)

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

copy_into_repo() {   # copy_into_repo source destination
    local src="$1" dest="$2"
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    if [ -d "$src" ] && command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude '*.bak' --exclude '*.save' --exclude '*.log' --exclude '.git' --exclude 'fish_variables' "$src/" "$dest/"
    else
        cp -a "$src" "$dest"
    fi
}

banner
printf '%sBacking up your setup into %s%s\n' "$C_BOLD" "${REPO_DIR/#$HOME/~}" "$C_RESET"

section "Config files"
for item in "${CONFIG_ITEMS[@]}"; do
    src="$HOME/.config/$item"
    dest="$REPO_DIR/config/$item"
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        note "$item: not found, skipped"
        continue
    fi
    if [ -L "$src" ] && [ "$(readlink -f "$src")" = "$(readlink -f "$dest")" ]; then
        item_line installed "$item (already linked to the repo)"
        continue
    fi
    copy_into_repo "$src" "$dest"
    ok "copied $item"
    if [ "$LINK" -eq 1 ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$src" "$BACKUP_DIR/$item"
        ln -s "$dest" "$src"
        note "linked ~/.config/$item to the repo (old copy in ${BACKUP_DIR/#$HOME/~}/$item)"
    fi
done

section "Your scripts"
mkdir -p "$REPO_DIR/bin"
note "scripts in ~/.local/bin are not copied automatically, put the ones you want in $REPO_DIR/bin"

section "Quickshell state (pinned apps, wallpaper, desktops)"
if [ -f "$HOME/.local/state/quickshell-pins.json" ]; then
    mkdir -p "$REPO_DIR/state"
    cp "$HOME/.local/state/quickshell-pins.json" "$REPO_DIR/state/quickshell-pins.json"
    ok "saved quickshell-pins.json"
else
    note "no saved state yet"
fi

section "Installed software"
mkdir -p "$REPO_DIR/packages"
if command -v pacman >/dev/null 2>&1; then
    pacman -Qqen > "$REPO_DIR/packages/explicit-native.txt"
    pacman -Qqem > "$REPO_DIR/packages/explicit-aur.txt"
    ok "$(wc -l < "$REPO_DIR/packages/explicit-native.txt") repo packages and $(wc -l < "$REPO_DIR/packages/explicit-aur.txt") AUR packages listed"
fi
if command -v flatpak >/dev/null 2>&1; then
    {
        echo "# Flatpak apps, one application ID per line (written by backup.sh)"
        flatpak list --app --columns=application 2>/dev/null | grep -E '^[A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+$' || true
    } > "$REPO_DIR/packages/flatpak.txt"
    ok "$(grep -vc '^#' "$REPO_DIR/packages/flatpak.txt") Flatpak apps listed"
fi

if [ "$WALLPAPERS" -eq 1 ] && [ -d "$HOME/Pictures/Wallpapers" ]; then
    section "Wallpapers"
    mkdir -p "$REPO_DIR/wallpapers"
    cp -a "$HOME/Pictures/Wallpapers/." "$REPO_DIR/wallpapers/"
    ok "copied $(find "$REPO_DIR/wallpapers" -type f | wc -l) images (large files make the repo slow, consider skipping this)"
fi

# ---------- safety check: look for things that look like passwords or keys ----------
section "Checking for secrets before you upload"
hits="$(grep -rIlE '(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|BEGIN [A-Z ]*PRIVATE KEY|api[_-]?key|secret|password|passwd|token)' \
        "$REPO_DIR/config" "$REPO_DIR/state" 2>/dev/null | grep -v '/quickshell/shell.qml$' || true)"
if [ -n "$hits" ]; then
    warn "These files contain words like password / token / secret. Open them and make sure nothing private is inside:"
    while IFS= read -r f; do note "${f/#$REPO_DIR\//}"; done <<< "$hits"
else
    ok "nothing suspicious found"
fi

echo
ok "Backup finished. Next:  cd ${REPO_DIR/#$HOME/~} && git add -A && git commit -m \"Update dotfiles\" && git push"
echo
