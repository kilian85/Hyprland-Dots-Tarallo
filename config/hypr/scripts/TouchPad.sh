#!/usr/bin/env bash
# For disabling touchpad.
# Edit the Touchpad_Device on ~/.config/hypr/UserConfigs/Laptops.conf according to your system
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

set -euo pipefail

notif="$HOME/.config/swaync/images/ja.png"
laptops_conf="$HOME/.config/hypr/UserConfigs/Laptops.conf"

touchpad_device="${TOUCHPAD_DEVICE:-}"
if [[ -z "$touchpad_device" && -f "$laptops_conf" ]]; then
    touchpad_device="$(
        awk -F= '/^\$Touchpad_Device/ {
            gsub(/[[:space:]]*/, "", $1);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
            print $2;
            exit
        }' "$laptops_conf"
    )"
fi

if [[ -z "$touchpad_device" ]]; then
    notify-send -u low -i "$notif" " Touchpad" " Device name not set (check Laptops.conf)"
    exit 1
fi

status_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.status"

# Dalla 0.55 la configurazione e' in Lua: si usa `hyprctl eval` al posto del
# vecchio `hyprctl keyword device:NOME:enabled`.
set_touchpad() {
    hyprctl eval -r "hl.device({ name = \"${touchpad_device}\", enabled = $1 })"
}

enable_touchpad() {
    printf "true" >"$status_file"
    notify-send -u low -i "$notif" " Enabling" " touchpad"
    set_touchpad true
}

disable_touchpad() {
    printf "false" >"$status_file"
    notify-send -u low -i "$notif" " Disabling" " touchpad"
    set_touchpad false
}

current_state="false"
if [[ -f "$status_file" ]]; then
    current_state="$(<"$status_file")"
fi

if [[ "$current_state" == "true" ]]; then
    disable_touchpad
else
    enable_touchpad
fi
