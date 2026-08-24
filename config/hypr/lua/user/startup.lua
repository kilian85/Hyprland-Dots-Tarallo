-- user/startup.lua — programmi personali avviati con la sessione
-- (ex UserConfigs/Startup_Apps.conf)
--
-- Questo file non viene toccato dagli aggiornamenti delle dotfiles: quello che
-- aggiungi qui resta anche dopo un aggiornamento.

local helpers = require("lua/helpers")

local confdir     = helpers.confdir
local userScripts = helpers.userscripts

hl.on("hyprland.start", function()
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("[ -f " .. confdir .. "/.biometrics_configured ] || " .. userScripts .. "/BiometricsSetup.sh")

    -- I tuoi programmi vanno qui, per esempio:
    --   hl.exec_cmd("brave --no-startup-window")
    --   hl.exec_cmd("systemctl --user start rustdesk")
end)
