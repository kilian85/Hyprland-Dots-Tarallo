#!/usr/bin/env bash
# Script for keyboard backlights (if supported) using brightnessctl + SwayOSD

KBD_DEVICE="*::kbd_backlight"

# Get keyboard brightness
get_kbd_backlight() {
	echo $(brightnessctl -d '*::kbd_backlight' -m | cut -d, -f4)
}

# Execute accordingly
case "$1" in
	"--get")
		get_kbd_backlight
		;;
	"--inc")
		swayosd-client --brightness raise --device "$KBD_DEVICE"
		;;
	"--dec")
		swayosd-client --brightness lower --device "$KBD_DEVICE"
		;;
	*)
		get_kbd_backlight
		;;
esac
