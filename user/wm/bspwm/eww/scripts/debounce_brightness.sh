#!/usr/bin/env bash

# This script waits for a period of inactivity before setting the brightness.
# It's used to "debounce" the input from a slider.

# The brightness value is passed as the first argument.
if [ -z "$1" ]; then
    # Exit if no brightness value is provided.
    exit 1
fi
BRIGHTNESS_VALUE=$1
DELAY=0.3
PID_FILE="/tmp/eww_brightness_debounce.pid"

# If a previous debouncer is running, kill it.
if [ -f "$PID_FILE" ]; then
    # The stored PID is for the backgrounded `( sleep ... )` subshell.
    # Killing it prevents the previous brightness value from being set.
    kill "$(cat "$PID_FILE")" >/dev/null 2>&1
fi

# Start a new background process that will set the brightness after a delay.
# This process runs in a subshell `(...)` and is backgrounded with `&`.
(
    sleep "$DELAY"
    # Use the value that was passed to this script instance.
    # We use an absolute path to the brightness script for reliability.
    "$HOME/.config/eww/scripts/brightness" set "$BRIGHTNESS_VALUE"
) &

# Store the PID of our new background process so it can be killed by the next one.
echo $! > "$PID_FILE" 