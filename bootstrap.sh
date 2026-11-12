#!/usr/bin/env bash
# The one-line entry point for a brand-new install. Paste this into a terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/Fatty-ux/dotfiles/main/bootstrap.sh | bash
#
# It installs git, downloads this repo to ~/dotfiles and starts the installer.
set -euo pipefail

REPO_URL="${JOEOS_REPO:-https://github.com/Fatty-ux/dotfiles.git}"
TARGET="${JOEOS_DIR:-$HOME/dotfiles}"

echo "Getting things ready…"
if ! command -v git >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm git
fi

if [ -d "$TARGET/.git" ]; then
    git -C "$TARGET" pull --ff-only
else
    git clone "$REPO_URL" "$TARGET"
fi

exec bash "$TARGET/install.sh" "$@"
