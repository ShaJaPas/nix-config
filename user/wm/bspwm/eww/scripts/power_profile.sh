#!/bin/bash

# This script uses the CPU scaling governor to control power profiles.
# It may require passwordless sudo for the tee command to change the governor.

function get_current_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

function get_icon() {
    case "$1" in
        "powersave")
            echo "assets/power_profile_power_saver"
            ;;
        "schedutil" | "ondemand") # Mapped from 'balanced'
            echo "assets/power_profile_balanced"
            ;;
        "performance")
            echo "assets/power_profile_performance"
            ;;
        *)
            echo ""
            ;;
    esac
}

function output_json() {
    local governor=$1
    local icon=$(get_icon $governor)
    local is_active="false"
    if [ "$governor" == "performance" ]; then
        is_active="true"
    fi

    local sub_text=""
    case "$governor" in
        "powersave")
            sub_text="Power Saver"
            ;;
        "schedutil" | "ondemand")
            sub_text="Balanced"
            ;;
        "performance")
            sub_text="Performance"
            ;;
        *)
            sub_text="Unknown"
            ;;
    esac

    echo "{\"profile\": \"$governor\", \"icon\": \"$icon\", \"is_active\": $is_active, \"sub_text\": \"$sub_text\"}"
}

function set_governor() {
    local governor=$1
    echo "$governor" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
}

function toggle_governor() {
    current_governor=$(get_current_governor)
    next_governor=""

    case "$current_governor" in
        "powersave")
            next_governor="ondemand"
            ;;
        "schedutil" | "ondemand")
            next_governor="performance"
            ;;
        "performance")
            next_governor="powersave"
            ;;
        *)
            # Fallback to ondemand if something is wrong
            next_governor="ondemand"
            ;;
    esac
    
    set_governor "$next_governor"
    output_json "$next_governor"
}

if [ "$1" == "toggle" ]; then
    toggle_governor
else
    output_json "$(get_current_governor)"
fi 