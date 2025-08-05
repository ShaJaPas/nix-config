#!/usr/bin/env bash

# Function to get and format notifications using jq
get_notifications() {
    dunstctl history | jq -c '.data[0] | map({summary: .summary.data, body: .body.data, appname: .appname.data, icon: (if .icon_path.data == "" or .icon_path.data == null then null else .icon_path.data end), id: .id.data, timestamp: (.timestamp.data / 1000000 | floor)})' || echo "[]"
}

# Initial output
get_notifications

# Listen for changes on the D-Bus
dbus-monitor --session "interface='org.freedesktop.Notifications'" |
while read -r _; do
    # Every time a signal is received on the interface, we refresh the list.
    # This is simpler and more reliable than trying to parse the dbus-monitor output.
    get_notifications
    eww update current_uptime="$(awk '{print int($1)}' /proc/uptime)" &
done 