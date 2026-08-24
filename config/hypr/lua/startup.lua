-- startup.lua — programmi avviati con la sessione (ex configs/Startup_Apps.conf)
--
-- Questo file viene sovrascritto dagli aggiornamenti delle dotfiles.
-- I programmi personali vanno in lua/user/startup.lua.

local helpers = require("lua/helpers")

local confdir     = helpers.confdir
local scriptsDir  = helpers.scripts
local userScripts = helpers.userscripts

hl.on("hyprland.start", function()
    -- Primo avvio: applica sfondi, tema e impostazioni iniziali.
    -- Finche' esiste ~/.config/hypr/.initial_startup_done lo script non fa nulla.
    hl.exec_cmd(confdir .. "/initial-boot.sh")

    -- Portali XDG
    hl.exec_cmd("/usr/lib/xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal --replace")

    -- Sfondo
    hl.exec_cmd("awww-daemon --format xrgb")

    -- Ambiente di sessione
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Servizi e applet
    hl.exec_cmd(scriptsDir .. "/Dropterminal.sh kitty")
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("swaync")
    hl.exec_cmd("waybar")
    hl.exec_cmd("qs -c overview") -- panoramica Quickshell
    hl.exec_cmd("hypridle")
    hl.exec_cmd(scriptsDir .. "/Hyprsunset.sh init")
    hl.exec_cmd(scriptsDir .. "/battery-monitor.sh")
    hl.exec_cmd(scriptsDir .. "/Benvenuto.sh")

    -- Schermata di benvenuto al primo avvio
    hl.exec_cmd("sleep 3 && " .. userScripts .. "/WelcomeTarallo.sh --autostart")

    -- Appunti
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Bordi arcobaleno (si accendono e spengono dal menu impostazioni rapide)
    hl.exec_cmd(userScripts .. "/RainbowBorders.sh")

    -- Assegna J e K in base alla disposizione attiva (master o dwindle)
    hl.exec_cmd(scriptsDir .. "/ChangeLayout.sh init")
    hl.exec_cmd(scriptsDir .. "/KeybindsLayoutInit.sh")
end)

-- Cose disponibili ma spente di serie:
--   hl.exec_cmd("nm-tray")   -- applet di rete alternativo (serve su Ubuntu)
--   hl.exec_cmd("ags")
--   hl.exec_cmd("rog-control-center")
--   sfondo che cambia da solo:
--     hl.exec_cmd(userScripts .. "/WallpaperAutoChange.sh " .. helpers.home .. "/Pictures/wallpapers")
--   sfondo fisso:
--     hl.exec_cmd("awww img " .. helpers.home .. "/Pictures/wallpapers/mecha-nostalgia.png")
