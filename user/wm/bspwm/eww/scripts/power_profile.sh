#!/bin/bash

# This script uses systemd services to control power profiles.

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
    local profile=$1
    case "$profile" in
        "powersave")
            systemctl start set-power-profile-powersave.service
            ;;
        "balanced")
            systemctl start set-power-profile-balanced.service
            ;;
        "performance")
            systemctl start set-power-profile-performance.service
            ;;
    esac
}

function toggle_governor() {
    current_governor=$(get_current_governor)
    next_governor_name=""

    case "$current_governor" in
        "powersave")
            next_governor_name="balanced"
            ;;
        "schedutil" | "ondemand")
            next_governor_name="performance"
            ;;
        "performance")
            next_governor_name="powersave"
            ;;
        *)
            # Fallback to balanced if something is wrong
            next_governor_name="balanced"
            ;;
    esac

    set_governor "$next_governor_name"
    # Wait a bit for the governor to change
    sleep 0.1
    output_json "$(get_current_governor)"
}

if [ "$1" == "toggle" ]; then
    toggle_governor
else
    output_json "$(get_current_governor)"
fi 