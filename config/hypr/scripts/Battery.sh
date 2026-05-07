#!/usr/bin/env bash

for i in {0..3}; do
  if [ -f /sys/class/power_supply/BAT$i/capacity ]; then
    battery_level=$(cat /sys/class/power_supply/BAT$i/status)
    battery_capacity=$(cat /sys/class/power_supply/BAT$i/capacity)
    case "$battery_level" in
      Charging)    battery_level="In carica" ;;
      Discharging) battery_level="In scarica" ;;
      Full)        battery_level="Carica" ;;
      "Not charging") battery_level="Non in carica" ;;
    esac
    echo "Batteria: $battery_capacity% ($battery_level)"
  fi
done
