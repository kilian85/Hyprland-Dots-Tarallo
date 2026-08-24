-- laptops.lua — tasti e dispositivi del portatile (ex configs/Laptops.conf + UserConfigs/Laptops.conf)

local helpers = require("lua/helpers")

local mainMod    = helpers.mainMod
local scriptsDir = helpers.scripts

-- Nome del touchpad: resta nei .conf perche' lo legge anche scripts/TouchPad.sh.
-- Vale prima quello personale, poi quello predefinito. Si ricava con
-- `hyprctl devices`.
local TOUCHPAD = helpers.parse_vars(helpers.userconfigs .. "/Laptops.conf").Touchpad_Device
    or helpers.parse_vars(helpers.confdir .. "/configs/Laptops.conf").Touchpad_Device

hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"),
    { repeating = true, description = "meno luce sulla tastiera" })
hl.bind("xf86KbdBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"),
    { repeating = true, description = "piu' luce sulla tastiera" })
hl.bind("xf86Launch1", hl.dsp.exec_cmd("rog-control-center"),
    { description = "ASUS Armoury Crate" })
hl.bind("xf86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"),
    { description = "profilo RGB della tastiera" })
hl.bind("xf86Launch4", hl.dsp.exec_cmd("asusctl profile -n"),
    { description = "profilo delle ventole" })
hl.bind("xf86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"),
    { repeating = true, description = "abbassa la luminosita'" })
hl.bind("xf86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"),
    { repeating = true, description = "alza la luminosita'" })
hl.bind("xf86TouchpadToggle", hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh"),
    { description = "attiva/disattiva il touchpad" })

-- Schermate con F6, per le tastiere senza tasto Stamp
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"),
    { description = "schermata immediata" })
hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"),
    { description = "schermata di un'area" })
hl.bind(mainMod .. " + CTRL + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"),
    { description = "schermata fra 5 secondi" })
hl.bind(mainMod .. " + ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"),
    { description = "schermata fra 10 secondi" })
hl.bind("ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"),
    { description = "schermata della finestra attiva" })

if TOUCHPAD then
    hl.device({ name = TOUCHPAD, enabled = true })
end
