-- user/decorations.lua — bordi, ombre, sfocatura (ex UserConfigs/UserDecorations.conf)
-- Questo file non viene toccato dagli aggiornamenti delle dotfiles.
--
-- I colori arrivano da wallust, che continua a scrivere il suo file nel vecchio
-- formato perche' lo legge anche hyprlock: helpers.wallust_colors() lo traduce.

local helpers = require("lua/helpers")
local c = helpers.wallust_colors()

hl.config({
    general = {
        border_size = 2,
        gaps_in     = 2,
        gaps_out    = 4,

        col = {
            active_border   = c.color12,
            inactive_border = c.color10,
        },
    },

    decoration = {
        rounding = 10,

        active_opacity     = 1.0,
        inactive_opacity   = 0.9,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.1,
        dim_special  = 0.8,

        shadow = {
            enabled        = true,
            range          = 3,
            render_power   = 1,
            color          = c.color12,
            color_inactive = c.color10,
        },

        blur = {
            enabled          = true,
            size             = 6,
            passes           = 3,
            new_optimizations = true,
            xray             = true,
            ignore_opacity   = true,
            special          = true,
            popups           = true,
        },
    },

    group = {
        col = {
            border_active = c.color15,
        },
        groupbar = {
            col = {
                active = c.color0,
            },
        },
    },
})
