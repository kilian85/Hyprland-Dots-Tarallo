-- helpers.lua — funzioni di appoggio per la configurazione Lua di Hyprland
--
-- Perche' esiste: diversi programmi esterni continuano a scrivere file nel
-- vecchio formato hyprlang (.conf) e non possiamo cambiarli:
--   * wallust      -> wallust/wallust-hyprland.conf  (letto anche da hyprlock)
--   * nwg-displays -> monitors.conf, workspaces.conf
--   * Animations.sh-> UserConfigs/UserAnimations.conf
--   * auto-rotate.sh -> auto-rotate-monitor.conf
-- Invece di riscrivere quei programmi, qui leggiamo i loro .conf e li
-- traduciamo al volo nelle chiamate hl.* della nuova API.

local M = {}

M.home        = os.getenv("HOME")
M.confdir     = M.home .. "/.config/hypr"
M.scripts     = M.confdir .. "/scripts"
M.userscripts = M.confdir .. "/UserScripts"
M.userconfigs = M.confdir .. "/UserConfigs"

-- Tasto modificatore principale, usato da tutti i moduli dei keybind
M.mainMod = "SUPER"

--------------------------------------------------------------------
-- Lettura file
--------------------------------------------------------------------

--- Legge un file di testo riga per riga.
--- @return table|nil elenco delle righe, nil se il file non esiste
function M.read_lines(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local lines = {}
    for line in f:lines() do
        lines[#lines + 1] = line
    end
    f:close()
    return lines
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end
M.trim = trim

--- Divide una stringa sul separatore indicato, togliendo gli spazi.
function M.split(s, sep)
    sep = sep or ","
    local out = {}
    for field in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do
        out[#out + 1] = trim(field)
    end
    -- l'ultimo elemento e' sempre vuoto per costruzione
    if out[#out] == "" then table.remove(out) end
    return out
end

--------------------------------------------------------------------
-- Variabili hyprlang ($nome = valore)
--------------------------------------------------------------------

--- Legge le variabili `$nome = valore` di un file hyprlang.
--- Usato per i colori di wallust e per 01-UserDefaults.conf.
function M.parse_vars(path)
    local vars = {}
    for _, line in ipairs(M.read_lines(path) or {}) do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.*)$")
        if name then
            value = trim(value:gsub("%s+#.*$", ""))
            value = value:gsub('^"(.*)"$', "%1")
            vars[name] = value
        end
    end
    return vars
end

--- Colori generati da wallust, con fallback se il file manca.
function M.wallust_colors()
    local c = M.parse_vars(M.confdir .. "/wallust/wallust-hyprland.conf")
    local function color(name, fallback)
        return c[name] or fallback
    end
    return {
        background = color("background", "rgb(0D1926)"),
        foreground = color("foreground", "rgb(B4E1FD)"),
        color0     = color("color0",  "rgb(363636)"),
        color10    = color("color10", "rgb(8EFF1E)"),
        color12    = color("color12", "rgb(1E8EFF)"),
        color15    = color("color15", "rgb(C2C2C2)"),
    }
end

--------------------------------------------------------------------
-- Animazioni in formato hyprlang (Animations.sh)
--------------------------------------------------------------------

local function to_bool(v)
    v = tostring(v):lower()
    return v == "1" or v == "yes" or v == "true" or v == "on"
end
M.to_bool = to_bool

--- Legge un file animazioni in formato hyprlang e lo applica.
--- Riconosce `enabled`, `bezier` e `animation`; le graffe sono ignorate,
--- perche' le tre chiavi bastano a distinguere le righe.
--- @return boolean true se il file esisteva
function M.apply_animations(path)
    local lines = M.read_lines(path)
    if not lines then return false end

    for _, raw in ipairs(lines) do
        local line = raw:gsub("#.*$", "")
        local key, rest = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")

        if key == "enabled" then
            hl.config({ animations = { enabled = to_bool(rest) } })

        elseif key == "bezier" then
            local p = M.split(rest)
            if #p >= 5 then
                hl.curve(p[1], {
                    type   = "bezier",
                    points = { { tonumber(p[2]), tonumber(p[3]) },
                               { tonumber(p[4]), tonumber(p[5]) } },
                })
            end

        elseif key == "spring" then
            local p = M.split(rest)
            if #p >= 4 then
                hl.curve(p[1], {
                    type      = "spring",
                    mass      = tonumber(p[2]),
                    stiffness = tonumber(p[3]),
                    dampening = tonumber(p[4]),
                })
            end

        elseif key == "animation" then
            local p = M.split(rest)
            if p[1] then
                if not to_bool(p[2] or "0") then
                    hl.animation({ leaf = p[1], enabled = false })
                else
                    -- la nuova API rifiuta velocita' oltre 100, i vecchi preset
                    -- arrivavano a 180 per la rotazione del bordo
                    local speed = math.min(tonumber(p[3]) or 1, 100)
                    local spec = { leaf = p[1], enabled = true, speed = speed }
                    if p[4] and p[4] ~= "" then spec.bezier = p[4] end
                    if p[5] and p[5] ~= "" then
                        spec.style = table.concat(p, " ", 5)
                    end
                    hl.animation(spec)
                end
            end
        end
    end
    return true
end

--------------------------------------------------------------------
-- Monitor in formato hyprlang (nwg-displays, auto-rotate.sh)
--------------------------------------------------------------------

--- Converte `monitor = OUTPUT, MODE, POSIZIONE, SCALA[, chiave, valore...]`
--- nella chiamata hl.monitor() corrispondente.
function M.apply_monitors(path)
    local lines = M.read_lines(path)
    if not lines then return false end

    for _, raw in ipairs(lines) do
        local line = raw:gsub("#.*$", "")
        local rest = line:match("^%s*monitor%s*=%s*(.-)%s*$")
        if rest and rest ~= "" then
            local p = M.split(rest)
            local spec = { output = p[1] or "" }

            -- `monitor = NOME, disable` spegne l'uscita
            if (p[2] or ""):lower() == "disable" then
                spec.disabled = true
            else
                spec.mode     = p[2] or "preferred"
                spec.position = p[3] or "auto"
                spec.scale    = tonumber(p[4]) or p[4] or "auto"

                -- coppie chiave/valore facoltative in coda
                local i = 5
                while p[i] do
                    local key, value = p[i]:lower(), p[i + 1]
                    if value then
                        if key == "transform" or key == "bitdepth" or key == "vrr" then
                            spec[key] = tonumber(value)
                        elseif key == "mirror" then
                            spec.mirror = value
                        end
                    end
                    i = i + 2
                end
            end

            hl.monitor(spec)
        end
    end
    return true
end

--------------------------------------------------------------------
-- Regole workspace in formato hyprlang (nwg-displays)
--------------------------------------------------------------------

local WS_BOOL_RULES = {
    default = "default", persistent = "persistent", decorate = "decorate",
    border = "no_border", rounding = "no_rounding", shadow = "no_shadow",
}

--- Converte `workspace = ID, monitor:NOME, regola:valore, ...`.
function M.apply_workspaces(path)
    local lines = M.read_lines(path)
    if not lines then return false end

    for _, raw in ipairs(lines) do
        local line = raw:gsub("#.*$", "")
        local rest = line:match("^%s*workspace%s*=%s*(.-)%s*$")
        if rest and rest ~= "" then
            local p = M.split(rest)
            local spec = { workspace = p[1] }

            for i = 2, #p do
                local key, value = p[i]:match("^([%w%-_]+)%s*:%s*(.+)$")
                if key then
                    key = key:lower()
                    if key == "monitor" then
                        spec.monitor = value
                    elseif key == "on-created-empty" then
                        spec.on_created_empty = value
                    elseif key == "gapsin" then
                        spec.gaps_in = tonumber(value)
                    elseif key == "gapsout" then
                        spec.gaps_out = tonumber(value)
                    elseif key == "bordersize" then
                        spec.border_size = tonumber(value)
                    elseif key == "layout" then
                        spec.layout = value
                    elseif key == "defaultname" then
                        spec.default_name = value
                    elseif WS_BOOL_RULES[key] then
                        local target = WS_BOOL_RULES[key]
                        -- border/rounding/shadow sono negati nella nuova API
                        if target:match("^no_") then
                            spec[target] = not to_bool(value)
                        else
                            spec[target] = to_bool(value)
                        end
                    end
                end
            end

            hl.workspace_rule(spec)
        end
    end
    return true
end

return M
