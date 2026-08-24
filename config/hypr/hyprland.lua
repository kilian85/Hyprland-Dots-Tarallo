-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Configurazione di Hyprland in Lua (dalla 0.55 il formato .conf è deprecato).
-- Documentazione: https://wiki.hypr.land/  ·  note locali: LEGGIMI-lua.md
--
-- I moduli in lua/ sono quelli predefiniti e vengono SOVRASCRITTI dagli
-- aggiornamenti delle dotfiles. Quelli in lua/user/ sono tuoi e non vengono
-- toccati: dato che si caricano dopo, quello che scrivi lì ha la precedenza.

require("lua/env")               -- variabili d'ambiente
require("lua/user/env")

require("lua/settings")          -- impostazioni generali, input, gesti
require("lua/user/settings")

require("lua/user/decorations")  -- bordi, ombre, sfocatura (colori da wallust)
require("lua/animations")        -- animazioni (preset scelto con SUPER SHIFT A)

require("lua/keybinds")          -- scorciatoie predefinite
require("lua/laptops")           -- tasti funzione e touchpad del portatile
require("lua/user/laptops")
require("lua/user/touchscreen")  -- schermo tattile e penna
require("lua/user/keybinds")     -- scorciatoie personali

require("lua/windowrules")       -- regole di finestra predefinite
require("lua/user/windowrules")

require("lua/monitors")          -- monitor e workspace (nwg-displays, auto-rotate)

require("lua/startup")           -- programmi avviati con la sessione
require("lua/user/startup")
