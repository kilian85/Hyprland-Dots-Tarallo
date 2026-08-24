#!/usr/bin/env bash
# Modalita' gioco: spegne animazioni ed effetti.
# Dalla 0.55 la configurazione e' in Lua: si usa `hyprctl eval`.

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

HYPRGAMEMODE=$(hyprctl -j getoption animations.enabled | jq -r '.int // .set')
if [ "$HYPRGAMEMODE" = 1 ] || [ "$HYPRGAMEMODE" = "true" ]; then
    hyprctl eval '
        hl.config({
            animations = { enabled = false },
            decoration = {
                shadow   = { enabled = false },
                blur     = { enabled = false },
                rounding = 0,
            },
            general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
        })'

    # Regola con nome: viene rimossa dal `hyprctl reload` all'uscita
    hyprctl eval '
        hl.window_rule({
            name    = "gamemode-opacity",
            match   = { class = ".*" },
            opacity = "1 override 1 override 1 override",
        })'

    awww kill
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
	awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
	sleep 0.1
	${SCRIPTSDIR}/WallustSwww.sh
	sleep 0.5
  hyprctl reload
	${SCRIPTSDIR}/Refresh.sh
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
hyprctl reload
