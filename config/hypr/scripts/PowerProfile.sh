#!/usr/bin/env bash
# Gestione profilo energetico per waybar custom module

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

get_profile_info() {
    local profile
    profile=$(powerprofilesctl get)
    case "$profile" in
        performance)
            echo '{"text":"  ", "tooltip":"⚡ Prestazioni massime", "class":"performance"}'
            ;;
        balanced)
            echo '{"text":"  ", "tooltip":"⚖️ Bilanciato", "class":"balanced"}'
            ;;
        power-saver)
            echo '{"text":"  ", "tooltip":"🔋 Risparmio energetico", "class":"power-saver"}'
            ;;
    esac
}

cycle_profile() {
    local current next label icon
    current=$(powerprofilesctl get)
    case "$current" in
        performance)
            next="balanced"
            label="Bilanciato"
            icon="⚖️"
            ;;
        balanced)
            next="power-saver"
            label="Risparmio energetico"
            icon="🔋"
            ;;
        power-saver)
            next="performance"
            label="Prestazioni massime"
            icon="⚡"
            ;;
    esac
    powerprofilesctl set "$next"
    notify-send -u low "$icon Profilo energetico" "$label"
}

case "${1:-}" in
    --cycle) cycle_profile ;;
    *)       get_profile_info ;;
esac
