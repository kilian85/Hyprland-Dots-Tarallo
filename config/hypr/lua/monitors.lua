-- monitors.lua — monitor e regole dei workspace
--
-- nwg-displays e scripts/auto-rotate.sh continuano a scrivere monitors.conf,
-- workspaces.conf e auto-rotate-monitor.conf nel vecchio formato hyprlang:
-- qui vengono letti e tradotti, cosi' quegli strumenti funzionano come prima.

local helpers = require("lua/helpers")

-- Impostazione di partenza, se nessun file dice altro
if not helpers.apply_monitors(helpers.confdir .. "/monitors.conf") then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end

helpers.apply_workspaces(helpers.confdir .. "/workspaces.conf")

-- Rotazione automatica dello schermo (scritta da scripts/auto-rotate.sh):
-- va letta per ultima, cosi' vince sul resto.
helpers.apply_monitors(helpers.confdir .. "/auto-rotate-monitor.conf")
