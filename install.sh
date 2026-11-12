#!/usr/bin/env bash
# JoeOS installer: shows what's missing on this machine, then installs it and links your dotfiles.
#
#   ./install.sh                 interactive (asks before changing anything)
#   ./install.sh --check         only show what's installed / missing, change nothing
#   ./install.sh --yes           answer yes to every question
#   ./install.sh --dotfiles-only just link the config files, skip package installs
#   ./install.sh --no-flatpak    skip Flatpak apps
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ui.sh
source "$REPO_DIR/lib/ui.sh"

CHECK_ONLY=0
ASSUME_YES=0
SKIP_FLATPAK=0
DOTFILES_ONLY=0

usage() {
    sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
    case "$arg" in
        --check)          CHECK_ONLY=1 ;;
        --yes|-y)         ASSUME_YES=1 ;;
        --no-flatpak)     SKIP_FLATPAK=1 ;;
        --dotfiles-only)  DOTFILES_ONLY=1 ;;
        -h|--help)        usage; exit 0 ;;
        *) echo "Unknown option: $arg"; usage; exit 1 ;;
    esac
done
export ASSUME_YES

if [ -t 1 ]; then CLR=$'\r\033[K'; else CLR=$'\n'; fi

declare -a MISSING_NATIVE=() MISSING_AUR=() MISSING_FLATPAK=() FAILED=()
declare -A SEEN=()
INSTALLED_FLATPAKS=""
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ---------- small helpers ----------
# Names of the packages in a list file (comments and blank lines removed)
read_list() {
    [ -f "$1" ] || return 0
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^$' || true
}

# pacman -T prints nothing when the package (or something that provides it) is installed
pkg_present() { [ -z "$(pacman -T "$1" 2>/dev/null)" ]; }

flatpak_present() { printf '%s\n' "$INSTALLED_FLATPAKS" | grep -qx "$1"; }

add_missing() {   # add_missing native|aur|flatpak name
    local key="$1:$2"
    [ -n "${SEEN[$key]:-}" ] && return 0
    SEEN[$key]=1
    case "$1" in
        native)  MISSING_NATIVE+=("$2") ;;
        aur)     MISSING_AUR+=("$2") ;;
        flatpak) MISSING_FLATPAK+=("$2") ;;
    esac
}

run_step() {   # run_step "Label" command...
    local label="$1"; shift
    printf '  %s…%s %s' "$C_CYAN" "$C_RESET" "$label"
    if "$@" >>"$LOG" 2>&1; then
        printf '%s' "$CLR"; ok "$label"; return 0
    fi
    printf '%s' "$CLR"; err "$label  (see $LOG)"; return 1
}

# ---------- checks ----------
check_group() {   # check_group "Title" file native|aur
    local title="$1" file="$2" kind="$3" pkg
    local -a pkgs=()
    mapfile -t pkgs < <(read_list "$file")
    [ "${#pkgs[@]}" -eq 0 ] && return 0
    section "$title"
    for pkg in "${pkgs[@]}"; do
        if pkg_present "$pkg"; then
            item_line installed "$pkg"
        else
            item_line missing "$pkg"
            add_missing "$kind" "$pkg"
        fi
    done
}

# For long lists (everything you installed by hand): only print what's missing
check_bulk() {   # check_bulk "Title" file native|aur
    local title="$1" file="$2" kind="$3" pkg total=0 have=0 shown=0
    local -a pkgs=() gone=()
    mapfile -t pkgs < <(read_list "$file")
    [ "${#pkgs[@]}" -eq 0 ] && return 0
    section "$title"
    for pkg in "${pkgs[@]}"; do
        total=$((total + 1))
        if pkg_present "$pkg"; then
            have=$((have + 1))
        else
            gone+=("$pkg")
            add_missing "$kind" "$pkg"
        fi
    done
    ok "$have of $total already installed"
    for pkg in "${gone[@]}"; do
        shown=$((shown + 1))
        [ "$shown" -le 15 ] && item_line missing "$pkg"
    done
    [ "${#gone[@]}" -gt 15 ] && note "…and $(( ${#gone[@]} - 15 )) more"
}

check_flatpak() {
    local app total=0 have=0
    local -a apps=()
    mapfile -t apps < <(read_list "$REPO_DIR/packages/flatpak.txt")
    [ "${#apps[@]}" -eq 0 ] && return 0
    section "Flatpak apps"
    if ! command -v flatpak >/dev/null 2>&1; then
        for app in "${apps[@]}"; do add_missing flatpak "$app"; done
        warn "flatpak itself isn't installed yet (it's in core.txt, so it will be installed first)"
        return 0
    fi
    for app in "${apps[@]}"; do
        total=$((total + 1))
        if flatpak_present "$app"; then
            have=$((have + 1)); item_line installed "$app"
        else
            item_line missing "$app"; add_missing flatpak "$app"
        fi
    done
}

check_desktop() {
    section "Desktop session"
    if command -v Hyprland >/dev/null 2>&1 || pkg_present hyprland; then
        item_line installed "Hyprland"
    else
        item_line missing "Hyprland" "not installed (it will be added next to ${XDG_CURRENT_DESKTOP:-your current desktop})"
    fi
    if pkg_present quickshell; then item_line installed "Quickshell"; else item_line missing "Quickshell"; fi
    if pkg_present kitty; then item_line installed "kitty (default terminal)"; else item_line missing "kitty (default terminal)"; fi
    if pkg_present fastfetch; then item_line installed "fastfetch"; else item_line missing "fastfetch"; fi
    if command -v pokemon-colorscripts >/dev/null 2>&1; then item_line installed "pokemon-colorscripts (random Pokémon logo)"; else item_line missing "pokemon-colorscripts (random Pokémon logo)"; fi
    local noct
    noct="$(pacman -Qq 2>/dev/null | grep -i noctalia || true)"
    if [ -n "$noct" ]; then
        item_line missing "noctalia" "still installed, run ./scripts/remove-noctalia.sh to remove it"
    fi
}

# ---------- installing ----------
AUR_HELPER=""
find_aur_helper() {
    local h
    for h in paru yay; do
        if command -v "$h" >/dev/null 2>&1; then AUR_HELPER="$h"; return 0; fi
    done
    return 1
}

bootstrap_paru() {
    local tmp
    tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin" &&
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
}

install_native() {
    local pkg
    for pkg in "$@"; do
        if run_step "Installing $pkg" sudo pacman -S --needed --noconfirm "$pkg"; then
            :
        else
            add_missing aur "$pkg"
        fi
    done
}

install_aur() {
    local pkg
    [ "$#" -eq 0 ] && return 0
    if ! find_aur_helper; then
        warn "No AUR helper found (paru or yay), installing paru first"
        if ! run_step "Installing paru" bootstrap_paru; then
            FAILED+=("$@"); return 1
        fi
        find_aur_helper || { FAILED+=("$@"); return 1; }
    fi
    for pkg in "$@"; do
        run_step "Installing $pkg from the AUR" "$AUR_HELPER" -S --needed --noconfirm "$pkg" || FAILED+=("$pkg")
    done
}

install_flatpaks() {
    local app
    [ "${#MISSING_FLATPAK[@]}" -eq 0 ] && return 0
    command -v flatpak >/dev/null 2>&1 || { FAILED+=("${MISSING_FLATPAK[@]}"); return 1; }
    run_step "Adding the Flathub store" flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    for app in "${MISSING_FLATPAK[@]}"; do
        run_step "Installing $app (Flatpak)" flatpak install --user -y flathub "$app" || FAILED+=("$app")
    done
}

# ---------- dotfiles ----------
link_item() {   # link_item source target backup_dir
    local src="$1" target="$2" bk="$3"
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
        item_line installed "${target/#$HOME/~} (already linked)"
        return 0
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$(dirname "$bk/${target#"$HOME"/}")"
        mv "$target" "$bk/${target#"$HOME"/}"
        note "old copy moved to ${bk/#$HOME/~}/${target#"$HOME"/}"
    fi
    mkdir -p "$(dirname "$target")"
    if ln -s "$src" "$target"; then ok "linked ${target/#$HOME/~}"; else err "could not link $target"; fi
}

deploy_dotfiles() {
    section "Linking your dotfiles"
    local backup="$BACKUP_DIR"
    local src name

    # the wallpaper-driven kitty colours are generated, make sure there is a starting file
    if [ ! -e "$REPO_DIR/config/kitty/colors-wallpaper.conf" ] && [ -e "$REPO_DIR/config/kitty/colors-default.conf" ]; then
        cp "$REPO_DIR/config/kitty/colors-default.conf" "$REPO_DIR/config/kitty/colors-wallpaper.conf"
    fi

    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/state"
    for src in "$REPO_DIR"/config/*; do
        [ -e "$src" ] || continue
        name="$(basename "$src")"
        link_item "$src" "$HOME/.config/$name" "$backup"
    done
    for src in "$REPO_DIR"/bin/*; do
        [ -e "$src" ] || continue
        chmod +x "$src"
        name="$(basename "$src")"
        link_item "$src" "$HOME/.local/bin/$name" "$backup"
    done

    # Quickshell's saved state (pinned apps, wallpaper, desktops) is copied, not linked
    if [ -f "$REPO_DIR/state/quickshell-pins.json" ] && [ ! -e "$HOME/.local/state/quickshell-pins.json" ]; then
        cp "$REPO_DIR/state/quickshell-pins.json" "$HOME/.local/state/quickshell-pins.json"
        ok "restored Quickshell state (pinned apps, wallpaper, desktops)"
    fi
}

apply_settings() {
    section "Dark theme, terminal and shell"

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' >>"$LOG" 2>&1 \
            && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >>"$LOG" 2>&1 \
            && ok "GTK apps set to dark (adw-gtk3-dark)" || warn "couldn't set the GTK theme (log in to a desktop session and re-run)"
    fi

    local lua="$HOME/.config/hypr/hyprland.lua"
    if [ -f "$lua" ] && ! grep -q 'QT_QPA_PLATFORMTHEME' "$lua"; then
        printf '\nhl.env("QT_QPA_PLATFORMTHEME", "qt6ct")\n' >> "$lua"
        ok "Qt apps will use qt6ct (log out and in to apply)"
    fi

    # greeting: random Pokémon + fastfetch whenever a kitty window opens (fish)
    mkdir -p "$HOME/.config/fish/conf.d"
    link_item "$REPO_DIR/scripts/joeos.fish" "$HOME/.config/fish/conf.d/joeos.fish" "$BACKUP_DIR"

    if command -v kitty >/dev/null 2>&1; then
        ok "kitty is installed and set as the default terminal ($(kitty --version | head -1))"
    else
        warn "kitty isn't installed yet"
    fi
    if command -v fastfetch >/dev/null 2>&1; then ok "fastfetch is installed (run  pokefetch  for a random Pokémon)"; fi

    if [ "$(basename "${SHELL:-}")" != "fish" ] && command -v fish >/dev/null 2>&1; then
        if ask "Make fish your login shell?" N; then
            chsh -s "$(command -v fish)" && ok "login shell changed to fish (applies next login)"
        fi
    fi
}

# ---------- main ----------
banner
system_summary

if [ "$(id -u)" -eq 0 ]; then
    err "Please run this as your normal user (not root). It will ask for sudo when needed."
    exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
    err "This installer is for Arch-based systems (Arch, CachyOS, EndeavourOS…). pacman wasn't found."
    exit 1
fi

if [ "$DOTFILES_ONLY" -eq 1 ]; then
    deploy_dotfiles
    apply_settings
    echo; ok "Done."; exit 0
fi

INSTALLED_FLATPAKS="$(flatpak list --app --columns=application 2>/dev/null || true)"

printf '%sChecking what is installed on this machine…%s\n' "$C_BOLD" "$C_RESET"
check_desktop
check_group "Core desktop (Hyprland, Quickshell, audio, portals)" "$REPO_DIR/packages/core.txt" native
check_group "Terminal and command-line tools"                    "$REPO_DIR/packages/terminal.txt" native
check_group "Fonts and dark theme"                               "$REPO_DIR/packages/fonts-theme.txt" native
check_group "Apps"                                               "$REPO_DIR/packages/apps.txt" native
check_group "AUR extras"                                         "$REPO_DIR/packages/aur.txt" aur
check_bulk  "Everything else you installed by hand (repo)"       "$REPO_DIR/packages/explicit-native.txt" native
check_bulk  "Everything else you installed by hand (AUR)"        "$REPO_DIR/packages/explicit-aur.txt" aur
[ "$SKIP_FLATPAK" -eq 0 ] && check_flatpak

TOTAL_MISSING=$(( ${#MISSING_NATIVE[@]} + ${#MISSING_AUR[@]} + ${#MISSING_FLATPAK[@]} ))
section "Summary"
if [ "$TOTAL_MISSING" -eq 0 ]; then
    ok "Everything on your list is already installed."
else
    warn "${#MISSING_NATIVE[@]} repo packages, ${#MISSING_AUR[@]} AUR packages and ${#MISSING_FLATPAK[@]} Flatpak apps are missing."
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo; info "Check only, nothing was changed."; exit 0
fi

if [ "$TOTAL_MISSING" -gt 0 ]; then
    ask "Install the missing items now?" Y || { info "Skipping installs."; TOTAL_MISSING=0; MISSING_NATIVE=(); MISSING_AUR=(); MISSING_FLATPAK=(); }
fi

if [ "$TOTAL_MISSING" -gt 0 ]; then
    info "Asking for your password once so installs can run unattended…"
    sudo -v || { err "sudo is needed to install packages."; exit 1; }
    ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &

    if ask "Update the whole system first? (recommended on Arch)" Y; then
        section "Updating the system"
        run_step "pacman -Syu" sudo pacman -Syu --noconfirm
    fi

    section "Installing packages"
    install_native "${MISSING_NATIVE[@]}"
    # anything pacman couldn't find was added to the AUR list by install_native
    install_aur "${MISSING_AUR[@]}"
    [ "$SKIP_FLATPAK" -eq 0 ] && { section "Installing Flatpak apps"; install_flatpaks; }
fi

deploy_dotfiles
apply_settings

section "All done"
if [ "${#FAILED[@]}" -gt 0 ]; then
    warn "These couldn't be installed (they may not exist on this distro):"
    for pkg in "${FAILED[@]}"; do note "$pkg"; done
    note "Details are in $LOG"
else
    ok "Everything installed without errors."
fi

if ! command -v Hyprland >/dev/null 2>&1; then
    warn "Hyprland isn't installed, check the log above."
elif [ "${XDG_CURRENT_DESKTOP:-}" != "Hyprland" ]; then
    info "Log out, and on the login screen pick the Hyprland session (your current desktop stays installed)."
fi
info "Open a new kitty window to see the Pokémon + fastfetch greeting."
echo
