#!/usr/bin/env bash
# Saluto vocale all'avvio di Hyprland
[ -f "$HOME/.config/hypr/.benvenuto_disabled" ] && exit 0
sleep 3
paplay "$HOME/.cache/benvenuto.wav" 2>/dev/null
