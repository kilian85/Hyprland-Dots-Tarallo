-- settings.lua — impostazioni generali (ex configs/SystemSettings.conf)

local helpers = require("lua/helpers")

hl.config({
    dwindle = {
        preserve_split       = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact      = 0.5,
    },

    general = {
        resize_on_border = true,
        layout           = "dwindle",
    },

    input = {
        kb_layout    = "it",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        repeat_rate  = 50,
        repeat_delay = 300,

        sensitivity                = 0, -- sensibilita' del mouse
        numlock_by_default         = true,
        left_handed                = false,
        follow_mouse               = 1,
        float_switch_override_focus = false,

        touchpad = {
            disable_while_typing   = true,
            natural_scroll         = true,
            clickfinger_behavior   = false,
            middle_button_emulation = false,
            tap_to_click           = true,
            drag_lock              = false,
        },

        -- dispositivi touch (touchscreen)
        touchdevice = {
            enabled = true,
        },

        tablet = {
            transform   = 0,
            left_handed = false,
        },
    },

    gestures = {
        workspace_swipe_distance           = 500,
        workspace_swipe_invert             = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio       = 0.5,
        workspace_swipe_create_new         = true,
        workspace_swipe_forever            = true,
    },

    misc = {
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        vrr                       = 2,
        mouse_move_enables_dpms   = true,
        enable_swallow            = false,
        swallow_regex             = "^(kitty)$",
        focus_on_activate         = false,
        initial_workspace_tracking = 0,
        middle_click_paste        = false,
        enable_anr_dialog         = true, -- Application Not Responding
        anr_missed_pings          = 15,   -- il default 1 e' troppo basso
        allow_session_lock_restore = true, -- evita il crash del lockscreen al risveglio
        -- 0 nessun cambiamento, 1 la nuova finestra prende il fullscreen (stile Alt-Tab
        -- di Windows), 2 la nuova finestra resta dietro a quella a schermo intero
        on_focus_under_fullscreen = 1,
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    -- utile con la scalatura, evita la sfocatura delle app XWayland
    xwayland = {
        enabled            = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = 0,
    },

    cursor = {
        sync_gsettings_theme   = true,
        no_hardware_cursors    = 2, -- 1 per disabilitarli del tutto
        enable_hyprcursor      = true,
        warp_on_change_workspace = 2,
        no_warps               = true,
    },
})

--------------------------------------------------------------------
-- Gesti del touchpad
--------------------------------------------------------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Zoom del desktop con quattro dita
hl.gesture({ fingers = 4, direction = "up",   action = "cursor_zoom", zoom_level = 1.5, mode = "mult" })
hl.gesture({ fingers = 4, direction = "down", action = "cursor_zoom", zoom_level = 1 / 1.5, mode = "mult" })

-- Panoramica del desktop con tre dita verso l'alto
hl.gesture({
    fingers   = 3,
    direction = "up",
    action    = function()
        hl.dispatch(hl.dsp.exec_cmd(helpers.scripts .. "/OverviewToggle.sh"))
    end,
})
