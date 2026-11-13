#!/usr/bin/env bash
# JoeOS: link signal-cli to your Signal account as an extra device (the same way Signal Desktop
# is linked), so the right-side panel can show your chats and send messages.
# Run once in a terminal:  ~/.config/quickshell/scripts/signal-setup.sh
set -u

for c in signal-cli qrencode; do
    if ! command -v "$c" >/dev/null 2>&1; then
        echo "Missing $c. Install it first:  paru -S signal-cli qrencode"
        exit 1
    fi
done

CONF="$HOME/.config/joeos"
mkdir -p "$CONF"

account() { signal-cli listAccounts 2>/dev/null | grep -o '+[0-9]\+' | head -n1; }

acct="$(account)"
if [ -n "$acct" ]; then
    echo "Already linked as $acct"
else
    echo
    echo "On your phone open Signal > Settings > Linked devices > Link new device,"
    echo "then scan this QR code:"
    echo
    # signal-cli prints a sgnl:// link; turn it into a QR code in the terminal and wait for the scan
    signal-cli link -n "JoeOS bar" | tee >(grep --line-buffered '^sgnl://' | xargs -L 1 qrencode -t ansiutf8)
    acct="$(account)"
fi

if [ -z "$acct" ]; then
    echo "Linking didn't finish. Run this script again and scan the code."
    exit 1
fi

echo "$acct" > "$CONF/signal-account"
echo
echo "Linked as $acct. Getting your contacts and groups (this can take a minute)..."
signal-cli -a "$acct" sendSyncRequest >/dev/null 2>&1
signal-cli -a "$acct" receive -t 20 >/dev/null 2>&1
echo "All done! Restart the bar:  pkill quickshell; setsid -f quickshell"
