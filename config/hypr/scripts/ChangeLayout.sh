#!/usr/bin/env bash
# Cambia al volo la disposizione delle finestre di Hyprland (Master o Dwindle).
# Dalla 0.55 la configurazione e' in Lua: si usa `hyprctl eval` al posto del
# vecchio `hyprctl keyword`.

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general.layout | jq -r '.str')

# All'avvio inverte il valore letto, cosi' la logica di scambio qui sotto
# lascia la disposizione com'era invece di cambiarla.
if [ "$1" = "init" ]; then
  if [ "$LAYOUT" = "master" ]; then
    LAYOUT="dwindle"
  else
    LAYOUT="master"
  fi
fi

case $LAYOUT in
"master")
  hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
  hyprctl eval 'hl.unbind("SUPER + J")' >/dev/null 2>&1
  hyprctl eval 'hl.unbind("SUPER + K")' >/dev/null 2>&1
  hyprctl eval 'hl.bind("SUPER + J", hl.dsp.window.cycle_next(), { description = "finestra successiva" })'
  hyprctl eval 'hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }), { description = "finestra precedente" })'
  hyprctl eval 'hl.bind("SUPER + O", hl.dsp.layout("togglesplit"), { description = "alterna la divisione" })'
  notify-send -e -u low -i "$notif" " Tarallo Layout"
  ;;
"dwindle")
  hyprctl eval 'hl.config({ general = { layout = "master" } })'
  hyprctl eval 'hl.unbind("SUPER + J")' >/dev/null 2>&1
  hyprctl eval 'hl.unbind("SUPER + K")' >/dev/null 2>&1
  hyprctl eval 'hl.unbind("SUPER + O")' >/dev/null 2>&1
  hyprctl eval 'hl.bind("SUPER + J", hl.dsp.layout("cyclenext"), { description = "finestra successiva" })'
  hyprctl eval 'hl.bind("SUPER + K", hl.dsp.layout("cycleprev"), { description = "finestra precedente" })'
  notify-send -e -u low -i "$notif" " Master Layout"
  ;;
*) ;;

esac
