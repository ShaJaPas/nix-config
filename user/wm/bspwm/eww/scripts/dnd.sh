#!/bin/bash

case "$1" in
    get)
        dunstctl is-paused
        ;;
    toggle)
        dunstctl set-paused toggle
        ;;
    *)
        echo "Usage: $0 {get|toggle}"
        exit 1
        ;;
esac
