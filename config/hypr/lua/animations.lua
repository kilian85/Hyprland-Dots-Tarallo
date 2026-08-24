-- animations.lua — animazioni
--
-- Il menu Animazioni (SUPER SHIFT A) copia uno dei preset di ~/.config/hypr/animations/
-- dentro UserConfigs/UserAnimations.conf, nel vecchio formato hyprlang.
-- Qui quel file viene letto e tradotto, cosi' il menu continua a funzionare.
-- Se il file manca si usano le animazioni qui sotto come riserva.

local helpers = require("lua/helpers")

if helpers.apply_animations(helpers.userconfigs .. "/UserAnimations.conf") then
    return
end

hl.config({ animations = { enabled = true } })

hl.curve("wind",      { type = "bezier", points = { { 0.05, 0.9 },  { 0.1, 1.05 } } })
hl.curve("winIn",     { type = "bezier", points = { { 0.1, 1.1 },   { 0.1, 1.1 } } })
hl.curve("winOut",    { type = "bezier", points = { { 0.3, -0.3 },  { 0, 1 } } })
hl.curve("liner",     { type = "bezier", points = { { 1, 1 },       { 1, 1 } } })
hl.curve("overshot",  { type = "bezier", points = { { 0.05, 0.9 },  { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 },     { 0.99, 0.99 } } })
hl.curve("smoothIn",  { type = "bezier", points = { { 0.5, -0.5 },  { 0.68, 1.5 } } })

hl.animation({ leaf = "windows",       enabled = true, speed = 6,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3,   bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "border",        enabled = true, speed = 1,   bezier = "liner" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 180, bezier = "liner",     style = "loop" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "smoothOut" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,   bezier = "overshot" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5,   bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5,   bezier = "winOut",    style = "slide" })
