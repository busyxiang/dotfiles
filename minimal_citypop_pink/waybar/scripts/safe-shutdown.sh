#!/usr/bin/env bash

LOCK="/tmp/shutdown_cancel"

# Clean old cancel flag
rm -f "$LOCK"

# Create a cancel file — if user moves, Hypridle will delete it
touch "$LOCK"

# Show countdown using Mako
for i in 5 4 3 2 1; do
    notify-send "Shutdown" "System will power off in $i seconds…\nMove mouse or press any key to cancel." -t 1000

    # If cancelled, stop the process
    if [[ ! -f "$LOCK" ]]; then
        notify-send "Shutdown Cancelled" "User activity detected. Shutdown aborted." -t 3000
        exit 0
    fi

    sleep 1
done

# Final check before shutdown
if [[ -f "$LOCK" ]]; then
    systemctl poweroff
fi
