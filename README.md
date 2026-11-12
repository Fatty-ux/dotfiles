# JoeOS dotfiles

My Hyprland + Quickshell setup for Arch / CachyOS, with a one-paste installer.

## Fresh install (new machine)

Open a terminal and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/Fatty-ux/dotfiles/main/bootstrap.sh | bash
```

It downloads this repo to `~/dotfiles`, shows what is installed and what is missing, asks before
installing anything, then links the config files into place.

Already have the repo? Run `~/dotfiles/install.sh`. Useful options:

| Command | What it does |
|---|---|
| `./install.sh --check` | only show what's missing, change nothing |
| `./install.sh --yes` | don't ask questions |
| `./install.sh --dotfiles-only` | just link the config files |
| `./install.sh --no-flatpak` | skip Flatpak apps |

## Saving your current setup to the repo

```bash
cd ~/dotfiles
./backup.sh --link     # copies configs and package lists in, then links the originals to the repo
git add -A && git commit -m "Update dotfiles" && git push
```

`backup.sh` also scans for anything that looks like a password or key before you upload.

## What's in here

```
install.sh            checklist + installer
backup.sh             system -> repo
bootstrap.sh          the one-line entry point
lib/ui.sh             colours, banner, helpers
packages/             package lists (core, terminal, fonts-theme, apps, aur, flatpak)
config/               linked into ~/.config  (hypr, quickshell, kitty, fastfetch, gtk, ...)
bin/                  linked into ~/.local/bin  (pokefetch)
scripts/              helpers (remove-noctalia.sh, fish greeting)
state/                Quickshell's saved state: pinned apps, wallpaper, desktops
```

## Terminal

kitty is the default terminal. Its colours are regenerated from the wallpaper by Quickshell
(`config/kitty/colors-wallpaper.conf`), the window is transparent, and opening it shows
fastfetch with a random Pokémon as the logo and the system name set to JoeOS.
