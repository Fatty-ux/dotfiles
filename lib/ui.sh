#!/usr/bin/env bash
# Shared look-and-feel helpers for the JoeOS scripts: colours, banner, checklist lines, questions.
# This file is sourced by the other scripts, it doesn't do anything on its own.

# ---------- colours (plain text when the output isn't a terminal) ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\033[0m';  C_BOLD=$'\033[1m';  C_DIM=$'\033[2m'
    C_GREEN=$'\033[38;2;80;250;123m'
    C_RED=$'\033[38;2;255;85;85m'
    C_YELLOW=$'\033[38;2;241;250;140m'
    C_CYAN=$'\033[38;2;139;233;253m'
    C_PURPLE=$'\033[38;2;189;147;249m'
    C_PINK=$'\033[38;2;255;121;198m'
else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_GREEN=""; C_RED=""; C_YELLOW=""; C_CYAN=""; C_PURPLE=""; C_PINK=""
fi

LOG="${LOG:-$HOME/.cache/joeos-install.log}"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

# ---------- banner ----------
BANNER_LINES=(
    '     ██╗ ██████╗ ███████╗ ██████╗ ███████╗'
    '     ██║██╔═══██╗██╔════╝██╔═══██╗██╔════╝'
    '     ██║██║   ██║█████╗  ██║   ██║███████╗'
    '██   ██║██║   ██║██╔══╝  ██║   ██║╚════██║'
    '╚█████╔╝╚██████╔╝███████╗╚██████╔╝███████║'
    ' ╚════╝  ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝'
)
BANNER_COLORS=("190;120;255" "165;130;255" "140;150;255" "110;180;255" "90;210;245" "75;235;230")

banner() {
    local i
    echo
    for i in "${!BANNER_LINES[@]}"; do
        if [ -n "$C_RESET" ]; then
            printf '\033[38;2;%sm%s\033[0m\n' "${BANNER_COLORS[$i]}" "${BANNER_LINES[$i]}"
        else
            printf '%s\n' "${BANNER_LINES[$i]}"
        fi
    done
    printf '  %sHyprland  •  Quickshell  •  kitty  •  your whole setup, one paste%s\n' "$C_DIM" "$C_RESET"
    echo
}

system_summary() {
    local distro="unknown"
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        distro="$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")"
    fi
    printf '  %sUser%s     %s@%s\n'    "$C_PURPLE" "$C_RESET" "${USER:-$(id -un)}" "$(hostname 2>/dev/null || echo localhost)"
    printf '  %sSystem%s   %s\n'       "$C_PURPLE" "$C_RESET" "$distro"
    printf '  %sDesktop%s  %s\n'       "$C_PURPLE" "$C_RESET" "${XDG_CURRENT_DESKTOP:-not running a desktop}"
    printf '  %sLog%s      %s\n'       "$C_PURPLE" "$C_RESET" "$LOG"
    echo
}

# ---------- message helpers ----------
section() { printf '\n%s%s▍ %s%s\n' "$C_BOLD" "$C_PINK" "$1" "$C_RESET"; }
info()    { printf '  %s•%s %s\n' "$C_CYAN" "$C_RESET" "$1"; }
ok()      { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn()    { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
err()     { printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; }
note()    { printf '    %s%s%s\n' "$C_DIM" "$1" "$C_RESET"; }

# One line of a checklist: item_line installed|missing name [extra]
item_line() {
    case "$1" in
        installed) printf '  %s✓%s %s%s%s\n' "$C_GREEN" "$C_RESET" "$C_DIM" "$2" "$C_RESET" ;;
        missing)   printf '  %s✗%s %s %s%s%s\n' "$C_RED" "$C_RESET" "$2" "$C_YELLOW" "${3:-missing}" "$C_RESET" ;;
    esac
}

# ask "Question?" [Y|N]  ->  success when the answer is yes. Reads from the terminal even when piped (curl | bash).
ask() {
    local prompt="$1" def="${2:-Y}" reply hint="[Y/n]"
    [ "${ASSUME_YES:-0}" = 1 ] && return 0
    [ "$def" = "N" ] && hint="[y/N]"
    printf '\n%s? %s%s %s ' "$C_CYAN" "$prompt" "$C_RESET" "$hint" > /dev/tty
    read -r reply < /dev/tty || reply=""
    reply="${reply:-$def}"
    [[ "$reply" =~ ^[Yy] ]]
}

pause_for_enter() {
    [ "${ASSUME_YES:-0}" = 1 ] && return 0
    printf '\n%sPress Enter to continue…%s' "$C_DIM" "$C_RESET" > /dev/tty
    read -r _ < /dev/tty || true
}
