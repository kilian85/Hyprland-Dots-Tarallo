-- user/keybinds.lua — scorciatoie personali (ex UserConfigs/UserKeybinds.conf)
--
-- Questo file non viene toccato dagli aggiornamenti delle dotfiles.
-- Le scorciatoie qui sotto vengono caricate DOPO quelle predefinite, quindi
-- per rimpiazzarne una basta ridefinirla con la stessa combinazione di tasti.

local helpers = require("lua/helpers")

local mainMod    = helpers.mainMod
local scriptsDir = helpers.scripts

hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd(scriptsDir .. "/PowerProfile.sh --cycle"),
    { description = "cambia profilo energetico" })

-- SUPER G apre il Game Launcher, quindi il raggruppamento finestre passa a SUPER CTRL G
hl.unbind(mainMod .. " + G")
hl.bind(mainMod .. " + CTRL + G", hl.dsp.group.toggle(),
    { description = "raggruppa/separa le finestre" })
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(scriptsDir .. "/gamelauncher.sh"),
    { description = "Game Launcher" })

-- Per passare la tastiera a una macchina virtuale:
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
-- hl.define_submap("passthru", function()
--     hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)
