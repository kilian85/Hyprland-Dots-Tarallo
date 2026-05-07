#!/usr/bin/env bash

msg=""
for bat in /sys/class/power_supply/BAT*; do
    name=$(basename "$bat")
    cap=$(cat "$bat/capacity" 2>/dev/null)
    status=$(cat "$bat/status" 2>/dev/null)

    [[ -z "$cap" || "$cap" == "0" ]] && continue

    case "$status" in
        Charging)      icon="󰂄"; label_status="In carica"      ;;
        Discharging)   icon="󰂁"; label_status="In scarica"     ;;
        Full)          icon="󰁹"; label_status="Carica"         ;;
        "Not charging") icon="󰂑"; label_status="Non in carica" ;;
        *)             icon="󰂑"; label_status="$status"        ;;
    esac

    case "$name" in
        BAT0) label="Interna" ;;
        BAT1) label="Esterna" ;;
        *)    label="$name"   ;;
    esac

    msg+="$icon  $label ($name): $cap%  ($label_status)\n"
done

notify-send -u normal "Batterie" "$(echo -e "$msg")"
