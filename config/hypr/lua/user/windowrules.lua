-- user/windowrules.lua — regole di finestra personali (ex UserConfigs/WindowRules.conf)
--
-- Questo file non viene toccato dagli aggiornamenti delle dotfiles.
-- Viene caricato dopo lua/windowrules.lua, quindi qui si sovrascrive quello che
-- serve. Documentazione: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local rule = hl.window_rule

rule({ match = { tag = "KooL_Cheat" }, size = { 900, 700 } })

-- Esempi:
--   rule({ match = { class = "^(mpv)$" }, fullscreen = true })
--   rule({ match = { class = "^(eden)$" }, float = true, size = { 1920, 1080 }, center = true })
