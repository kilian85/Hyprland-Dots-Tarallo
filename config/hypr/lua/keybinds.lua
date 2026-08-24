-- keybinds.lua — scorciatoie predefinite (ex configs/Keybinds.conf)
-- Le scorciatoie personali vanno in lua/userkeybinds.lua, non qui.

local helpers = require("lua/helpers")

local mainMod     = helpers.mainMod
local scriptsDir  = helpers.scripts
local userScripts = helpers.userscripts

-- Terminale e file manager predefiniti: restano in 01-UserDefaults.conf perche'
-- quel file lo leggono anche i moduli di Waybar e alcuni script.
local defaults = helpers.parse_vars(helpers.userconfigs .. "/01-UserDefaults.conf")
local term     = defaults.term  or "kitty"
local files    = defaults.files or "thunar"

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

--------------------------------------------------------------------
-- Scorciatoie comuni
--------------------------------------------------------------------

hl.bind(mainMod .. " + D", exec("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"),
    { description = "menu applicazioni" })
hl.bind(mainMod .. " + B", exec('xdg-open "https://"'),
    { description = "apri il browser predefinito" })
hl.bind(mainMod .. " + A", exec(scriptsDir .. "/OverviewToggle.sh"),
    { description = "panoramica del desktop" })
hl.bind(mainMod .. " + Return", exec(term),
    { description = "apri il terminale" })
hl.bind(mainMod .. " + E", exec(files),
    { description = "gestore file" })

--------------------------------------------------------------------
-- Funzioni ed extra
--------------------------------------------------------------------

hl.bind(mainMod .. " + T", exec(scriptsDir .. "/ThemeChanger.sh"),
    { description = "cambio tema globale con Wallust" })
hl.bind(mainMod .. " + H", exec(scriptsDir .. "/KeyHints.sh"),
    { description = "aiuto / elenco scorciatoie" })
hl.bind(mainMod .. " + ALT + R", exec(scriptsDir .. "/Refresh.sh"),
    { description = "ricarica barra e menu" })
hl.bind(mainMod .. " + ALT + E", exec(scriptsDir .. "/RofiEmoji.sh"),
    { description = "menu emoji" })
hl.bind(mainMod .. " + S", exec(scriptsDir .. "/RofiSearch.sh"),
    { description = "ricerca sul web" })
hl.bind(mainMod .. " + CTRL + S", exec("rofi -show window"),
    { description = "selettore finestre" })
hl.bind(mainMod .. " + ALT + O", exec(scriptsDir .. "/ChangeBlur.sh"),
    { description = "attiva/disattiva sfocatura" })
hl.bind(mainMod .. " + SHIFT + G", exec(scriptsDir .. "/GameMode.sh"),
    { description = "modalita' gioco" })
hl.bind(mainMod .. " + ALT + L", exec(scriptsDir .. "/ChangeLayout.sh"),
    { description = "alterna disposizione master/dwindle" })
hl.bind(mainMod .. " + ALT + V", exec(scriptsDir .. "/ClipManager.sh"),
    { description = "gestore appunti" })
hl.bind(mainMod .. " + CTRL + R", exec(scriptsDir .. "/RofiThemeSelector.sh"),
    { description = "selettore temi rofi" })
hl.bind(mainMod .. " + CTRL + SHIFT + R", exec("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh"),
    { description = "selettore temi rofi (modificato)" })

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen(),
    { description = "schermo intero" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" }),
    { description = "massimizza la finestra" })
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float(),
    { description = "rendi flottante la finestra" })

-- Il vecchio dispatcher `workspaceopt allfloat` non esiste piu': lo rifacciamo
-- alternando lo stato flottante di tutte le finestre del workspace attivo.
hl.bind(mainMod .. " + ALT + SPACE", function()
    local ws = hl.get_active_workspace()
    if not ws then return end
    for _, w in ipairs(hl.get_workspace_windows(ws) or {}) do
        hl.dispatch(hl.dsp.window.float({ action = "toggle", window = w }))
    end
end, { description = "rendi flottanti tutte le finestre" })

hl.bind(mainMod .. " + SHIFT + Return", exec(scriptsDir .. "/Dropterminal.sh " .. term),
    { description = "terminale a scomparsa" })

--------------------------------------------------------------------
-- Zoom del desktop
--------------------------------------------------------------------

local function zoom(factor)
    return function()
        local current = hl.get_config("cursor.zoom_factor") or 1
        if type(current) ~= "number" or current < 1 then current = 1 end
        hl.config({ cursor = { zoom_factor = current * factor } })
    end
end

hl.bind(mainMod .. " + ALT + mouse_down", zoom(2.0), { description = "ingrandisci" })
hl.bind(mainMod .. " + ALT + mouse_up",   zoom(0.5), { description = "rimpicciolisci" })

--------------------------------------------------------------------
-- Waybar
--------------------------------------------------------------------

hl.bind(mainMod .. " + CTRL + ALT + B", exec("pkill -SIGUSR1 waybar"),
    { description = "mostra/nascondi waybar" })
hl.bind(mainMod .. " + CTRL + B", exec(scriptsDir .. "/WaybarStyles.sh"),
    { description = "menu stili waybar" })
hl.bind(mainMod .. " + ALT + B", exec(scriptsDir .. "/WaybarLayout.sh"),
    { description = "menu disposizione waybar" })

-- Luce notturna (hyprsunset)
hl.bind(mainMod .. " + N", exec(scriptsDir .. "/Hyprsunset.sh toggle"),
    { description = "luce notturna" })

--------------------------------------------------------------------
-- Funzioni degli script utente
--------------------------------------------------------------------

hl.bind(mainMod .. " + SHIFT + M", exec(userScripts .. "/RofiBeats.sh"),
    { description = "musica online" })
hl.bind(mainMod .. " + W", exec(userScripts .. "/WallpaperSelect.sh"),
    { description = "scegli lo sfondo" })
hl.bind(mainMod .. " + SHIFT + W", exec(userScripts .. "/WallpaperEffects.sh"),
    { description = "effetti sullo sfondo" })
hl.bind("CTRL + ALT + W", exec(userScripts .. "/WallpaperRandom.sh"),
    { description = "sfondo casuale" })
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }),
    { description = "opacita' della finestra attiva" })
hl.bind(mainMod .. " + SHIFT + K", exec(scriptsDir .. "/KeyBinds.sh"),
    { description = "cerca fra le scorciatoie" })
hl.bind(mainMod .. " + SHIFT + A", exec(scriptsDir .. "/Animations.sh"),
    { description = "menu animazioni" })
hl.bind(mainMod .. " + SHIFT + O", exec(userScripts .. "/ZshChangeTheme.sh"),
    { description = "cambia tema di oh-my-zsh" })
hl.bind("ALT + SHIFT_L", exec(scriptsDir .. "/KeyboardLayout.sh switch"),
    { locked = true, non_consuming = true, description = "cambia disposizione tastiera (globale)" })
hl.bind("SHIFT + ALT_L", exec(scriptsDir .. "/Tak0-Per-Window-Switch.sh"),
    { locked = true, non_consuming = true, description = "cambia disposizione tastiera (per finestra)" })
hl.bind(mainMod .. " + ALT + C", exec(userScripts .. "/RofiCalc.sh"),
    { description = "calcolatrice" })

--------------------------------------------------------------------
-- Sposta il workspace attivo su un altro monitor
--------------------------------------------------------------------

hl.bind(mainMod .. " + CTRL + F9",  hl.dsp.workspace.move({ monitor = "l" }),
    { description = "sposta il workspace sul monitor a sinistra" })
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }),
    { description = "sposta il workspace sul monitor a destra" })
hl.bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }),
    { description = "sposta il workspace sul monitor in alto" })
hl.bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }),
    { description = "sposta il workspace sul monitor in basso" })

--------------------------------------------------------------------
-- Sistema
--------------------------------------------------------------------

hl.bind("CTRL + ALT + Delete", hl.dsp.exit(),
    { description = "esci da Hyprland" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(),
    { description = "chiudi la finestra attiva" })
hl.bind(mainMod .. " + SHIFT + Q", exec(scriptsDir .. "/KillActiveProcess.sh"),
    { description = "termina il processo attivo" })
hl.bind("CTRL + ALT + L", exec(scriptsDir .. "/LockScreen.sh"),
    { description = "blocca lo schermo" })
hl.bind("CTRL + ALT + P", exec(scriptsDir .. "/Wlogout.sh"),
    { description = "menu di spegnimento" })
hl.bind(mainMod .. " + SHIFT + N", exec("swaync-client -t -sw"),
    { description = "pannello notifiche" })
hl.bind(mainMod .. " + SHIFT + E", exec(scriptsDir .. "/Kool_Quick_Settings.sh"),
    { description = "menu impostazioni rapide" })

--------------------------------------------------------------------
-- Disposizione master
--------------------------------------------------------------------

hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"),
    { description = "rimuovi master" })
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"),
    { description = "aggiungi master" })
-- NOTA: J e K sono assegnati dinamicamente da scripts/KeybindsLayoutInit.sh e
-- scripts/ChangeLayout.sh, per evitare conflitti fra le due disposizioni.
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"),
    { description = "scambia con il master" })

-- Disposizione dwindle
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"),
    { description = "alterna la divisione (dwindle)" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(),
    { description = "pseudo-affiancamento (dwindle)" })

-- Valido per entrambe le disposizioni
hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"),
    { description = "rapporto di divisione 0.3" })

--------------------------------------------------------------------
-- Rotazione fra le finestre
--------------------------------------------------------------------

hl.bind("ALT + tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "finestra successiva" })

--------------------------------------------------------------------
-- Tasti speciali
--------------------------------------------------------------------

hl.bind("xf86audioraisevolume", exec(scriptsDir .. "/Volume.sh --inc"),
    { repeating = true, locked = true, description = "alza il volume" })
hl.bind("xf86audiolowervolume", exec(scriptsDir .. "/Volume.sh --dec"),
    { repeating = true, locked = true, description = "abbassa il volume" })
hl.bind("ALT + xf86audioraisevolume", exec(scriptsDir .. "/Volume.sh --inc-precise"),
    { repeating = true, locked = true, description = "alza il volume (fine)" })
hl.bind("ALT + xf86audiolowervolume", exec(scriptsDir .. "/Volume.sh --dec-precise"),
    { repeating = true, locked = true, description = "abbassa il volume (fine)" })
hl.bind("xf86AudioMicMute", exec(scriptsDir .. "/Volume.sh --toggle-mic"),
    { locked = true, description = "muto microfono" })
hl.bind("xf86audiomute", exec(scriptsDir .. "/Volume.sh --toggle"),
    { locked = true, description = "muto" })
hl.bind("xf86Sleep", exec("systemctl suspend"),
    { locked = true, description = "sospendi" })
hl.bind("xf86Rfkill", exec(scriptsDir .. "/AirplaneMode.sh"),
    { locked = true, description = "modalita' aereo" })

-- Controlli multimediali
-- NOTA: xf86AudioPlayPause non esiste fra i keysym XKB e ora Hyprland lo
-- rifiuta; i due tasti separati qui sotto coprono lo stesso caso.
hl.bind("xf86AudioPause", exec(scriptsDir .. "/MediaCtrl.sh --pause"),
    { locked = true, description = "pausa" })
hl.bind("xf86AudioPlay", exec(scriptsDir .. "/MediaCtrl.sh --pause"),
    { locked = true, description = "riproduci" })
hl.bind("xf86AudioNext", exec(scriptsDir .. "/MediaCtrl.sh --nxt"),
    { locked = true, description = "brano successivo" })
hl.bind("xf86AudioPrev", exec(scriptsDir .. "/MediaCtrl.sh --prv"),
    { locked = true, description = "brano precedente" })
hl.bind("xf86audiostop", exec(scriptsDir .. "/MediaCtrl.sh --stop"),
    { locked = true, description = "ferma" })

--------------------------------------------------------------------
-- Schermate
--------------------------------------------------------------------

hl.bind(mainMod .. " + Print", exec(scriptsDir .. "/ScreenShot.sh --now"),
    { description = "schermata immediata" })
hl.bind(mainMod .. " + SHIFT + Print", exec(scriptsDir .. "/ScreenShot.sh --area"),
    { description = "schermata di un'area" })
hl.bind(mainMod .. " + CTRL + Print", exec(scriptsDir .. "/ScreenShot.sh --in5"),
    { description = "schermata fra 5 secondi" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", exec(scriptsDir .. "/ScreenShot.sh --in10"),
    { description = "schermata fra 10 secondi" })
hl.bind("ALT + Print", exec(scriptsDir .. "/ScreenShot.sh --active"),
    { description = "schermata della finestra attiva" })
hl.bind(mainMod .. " + SHIFT + S", exec(scriptsDir .. "/ScreenShot.sh --swappy"),
    { description = "schermata con swappy" })

--------------------------------------------------------------------
-- Ridimensionamento e spostamento
--------------------------------------------------------------------

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0, relative = true }),
    { repeating = true, description = "restringi a sinistra" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }),
    { repeating = true, description = "allarga a destra" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -50, relative = true }),
    { repeating = true, description = "restringi in alto" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 50, relative = true }),
    { repeating = true, description = "allarga in basso" })

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }),
    { description = "sposta la finestra a sinistra" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }),
    { description = "sposta la finestra a destra" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }),
    { description = "sposta la finestra in alto" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }),
    { description = "sposta la finestra in basso" })

hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }),
    { description = "scambia con la finestra a sinistra" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }),
    { description = "scambia con la finestra a destra" })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }),
    { description = "scambia con la finestra in alto" })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }),
    { description = "scambia con la finestra in basso" })

--------------------------------------------------------------------
-- Gruppi di finestre
--------------------------------------------------------------------

hl.bind(mainMod .. " + G", hl.dsp.group.toggle(),
    { description = "raggruppa/separa le finestre" })

hl.bind(mainMod .. " + Tab", hl.dsp.group.next(),
    { description = "finestra successiva nel gruppo" })
hl.bind(mainMod .. " + CTRL + tab", hl.dsp.group.next(),
    { description = "cambia finestra attiva nel gruppo" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev(),
    { description = "finestra precedente nel gruppo" })

hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ into_group = "l" }),
    { description = "porta nel gruppo a sinistra" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ into_group = "r" }),
    { description = "porta nel gruppo a destra" })
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ out_of_group = true }),
    { description = "porta fuori dal gruppo" })

--------------------------------------------------------------------
-- Spostamento del fuoco
--------------------------------------------------------------------

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }), { description = "fuoco a sinistra" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), { description = "fuoco a destra" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }), { description = "fuoco in alto" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }), { description = "fuoco in basso" })

--------------------------------------------------------------------
-- Workspace
--------------------------------------------------------------------

hl.bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "m+1" }),
    { description = "workspace successivo" })
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }),
    { description = "workspace precedente" })

-- Workspace speciale (scratchpad)
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }),
    { description = "sposta nel workspace speciale" })
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special(),
    { description = "mostra/nascondi il workspace speciale" })

-- I codici tasto rendono le scorciatoie indipendenti dalla disposizione della
-- tastiera: code:10 e' il tasto 1, code:19 e' il tasto 0.
for i = 1, 10 do
    local code = "code:" .. (i + 9)
    hl.bind(mainMod .. " + " .. code, hl.dsp.focus({ workspace = i }),
        { description = "workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }),
        { description = "sposta nel workspace " .. i })
    hl.bind(mainMod .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = i, follow = false }),
        { description = "sposta senza seguire nel workspace " .. i })
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }),
    { description = "sposta nel workspace precedente" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }),
    { description = "sposta nel workspace successivo" })
hl.bind(mainMod .. " + CTRL + bracketleft",  hl.dsp.window.move({ workspace = "-1", follow = false }),
    { description = "sposta senza seguire nel workspace precedente" })
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }),
    { description = "sposta senza seguire nel workspace successivo" })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }),
    { description = "workspace successivo" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }),
    { description = "workspace precedente" })
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }),
    { description = "workspace successivo" })
hl.bind(mainMod .. " + comma",  hl.dsp.focus({ workspace = "e-1" }),
    { description = "workspace precedente" })

--------------------------------------------------------------------
-- Mouse
--------------------------------------------------------------------

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),
    { mouse = true, description = "sposta la finestra" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(),
    { mouse = true, description = "ridimensiona la finestra" })
