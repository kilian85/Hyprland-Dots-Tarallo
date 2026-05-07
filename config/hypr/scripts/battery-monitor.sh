#!/bin/bash
# Low Battery Notification Script
# Monitors battery level and sends notifications + sound alerts

# Configuration
LOW_BATTERY_THRESHOLD=20
CRITICAL_BATTERY_THRESHOLD=10
CHECK_INTERVAL=60  # Check every 60 seconds

SOUND_LOW="/usr/share/sounds/freedesktop/stereo/service-login.oga"
SOUND_CRITICAL="/usr/share/sounds/freedesktop/stereo/service-logout.oga"

play_sound() {
    paplay --volume=45000 "$1" 2>/dev/null &
}

# Track notification state to avoid spam
NOTIFIED_LOW=false
NOTIFIED_CRITICAL=false

# Attendi che acpi sia pronto all'avvio
sleep 15

while true; do
    # Se l'alimentatore è collegato non notificare mai
    AC_ONLINE=$(cat /sys/class/power_supply/AC/online 2>/dev/null)
    if [[ "$AC_ONLINE" == "1" ]]; then
        NOTIFIED_LOW=false
        NOTIFIED_CRITICAL=false
        sleep "$CHECK_INTERVAL"
        continue
    fi

    # Ignora batterie che riportano "rate information unavailable" (batteria assente/fantasma)
    BATTERY_LEVEL=$(acpi -b | grep Discharging | grep -v 'rate information unavailable' | grep -P -o '[0-9]+(?=%)' | sort -n | head -1)
    BATTERY_STATUS=$(acpi -b | grep -v 'rate information unavailable' | grep -o 'Discharging\|Charging\|Full' | head -1)

    # Only send notifications when discharging
    if [ "$BATTERY_STATUS" = "Discharging" ] && [[ "$BATTERY_LEVEL" =~ ^[0-9]+$ ]]; then
        if [ "$BATTERY_LEVEL" -le "$CRITICAL_BATTERY_THRESHOLD" ] && [ "$NOTIFIED_CRITICAL" = false ]; then
            notify-send -u critical -i battery-caution "⚠️ Batteria critica" "Livello batteria al ${BATTERY_LEVEL}%! Collega il caricatore immediatamente."
            play_sound "$SOUND_CRITICAL"
            NOTIFIED_CRITICAL=true
            NOTIFIED_LOW=true
        elif [ "$BATTERY_LEVEL" -le "$LOW_BATTERY_THRESHOLD" ] && [ "$NOTIFIED_LOW" = false ]; then
            notify-send -u normal -i battery-low "🔋 Batteria scarica" "Livello batteria al ${BATTERY_LEVEL}%. Considera di collegare il caricatore."
            play_sound "$SOUND_LOW"
            NOTIFIED_LOW=true
        fi
    else
        # Reset notification flags when charging or full
        NOTIFIED_LOW=false
        NOTIFIED_CRITICAL=false
    fi

    sleep "$CHECK_INTERVAL"
done
