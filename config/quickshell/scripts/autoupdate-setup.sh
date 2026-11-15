#!/usr/bin/env bash
# JoeOS: set up automatic updates (run once; it asks for your password).
#
# Installs a small system service that updates pacman packages and Flatpak apps
# without asking, once a day (and whenever you press Update in the bar).
# AUR packages are NOT updated automatically, because they're built from scripts
# anyone can upload; the bar tells you when there are some and installs them when you click.
#
#   autoupdate-setup.sh           install (or update) it
#   autoupdate-setup.sh remove    take it all away again
set -eu

ME="$(id -un)"
BIN=/usr/local/bin/joeos-autoupdate
UNIT=/etc/systemd/system/joeos-update.service
TIMER=/etc/systemd/system/joeos-update.timer
RULE=/etc/polkit-1/rules.d/50-joeos-update.rules

if [ "${1:-}" = remove ]; then
    sudo systemctl disable --now joeos-update.timer 2>/dev/null || true
    sudo rm -f "$BIN" "$UNIT" "$TIMER" "$RULE"
    sudo systemctl daemon-reload
    echo "Automatic updates removed."
    exit 0
fi

echo "Setting up automatic updates (your password is needed once)..."

sudo tee "$BIN" >/dev/null <<'EOF'
#!/bin/bash
# JoeOS automatic update (run by joeos-update.service). Log: /var/log/joeos-update.log
STATE=/var/lib/joeos-update
mkdir -p "$STATE"
exec >>/var/log/joeos-update.log 2>&1
say() { echo "$1 $(date +%s)" > "$STATE/last"; chmod 644 "$STATE/last"; }
echo "== $(date) starting"
say running

# another install is going on: wait up to 10 minutes, then try again next time
for _ in $(seq 1 60); do [ -e /var/lib/pacman/db.lck ] || break; sleep 10; done
if [ -e /var/lib/pacman/db.lck ]; then echo "pacman is busy, skipping"; say busy; exit 0; fi

# keyrings first, so new package signatures are trusted
pacman -Sy --noconfirm --needed archlinux-keyring $(pacman -Qq cachyos-keyring 2>/dev/null) || true
pacman -Su --noconfirm
rc=$?

if command -v flatpak >/dev/null; then
    flatpak update -y --noninteractive --system || true
fi

# old package downloads: keep the last 2 versions so the disk doesn't fill up
command -v paccache >/dev/null && paccache -rk2 >/dev/null 2>&1

if [ $rc -eq 0 ]; then
    # a new kernel means a restart is needed to use it
    if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then say restart; else say ok; fi
else
    say failed
fi
echo "== $(date) finished ($rc)"
EOF
sudo chmod 755 "$BIN"

sudo tee "$UNIT" >/dev/null <<'EOF'
[Unit]
Description=JoeOS automatic update
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/joeos-autoupdate
Nice=10
IOSchedulingClass=idle
EOF

sudo tee "$TIMER" >/dev/null <<'EOF'
[Unit]
Description=JoeOS automatic update, once a day

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=45min
OnBootSec=20min

[Install]
WantedBy=timers.target
EOF

# let you start the update from the bar without typing a password
sudo tee "$RULE" >/dev/null <<EOF
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "joeos-update.service" &&
        action.lookup("verb") == "start" &&
        subject.user == "$ME") {
        return polkit.Result.YES;
    }
});
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now joeos-update.timer
echo
echo "Done! Your computer now updates itself once a day, and the Update button works without a password."
echo "Log: /var/log/joeos-update.log    To undo: $0 remove"
