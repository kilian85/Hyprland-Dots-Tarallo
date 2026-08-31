-- user/keybinds.lua — scorciatoie personali (ex UserConfigs/UserKeybinds.conf)
--
-- Questo file non viene toccato dagli aggiornamenti delle dotfiles.
-- Le scorciatoie qui sotto vengono caricate DOPO quelle predefinite, quindi
-- per rimpiazzarne una basta ridefinirla con la stessa combinazione di tasti.

local helpers = require("lua/helpers")

local mainMod     = helpers.mainMod
local scriptsDir  = helpers.scripts
local userScripts = helpers.userscripts

hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd(scriptsDir .. "/PowerProfile.sh --cycle"),
    { description = "cambia profilo energetico" })

-- SUPER G apre il Game Launcher, quindi il raggruppamento finestre passa a SUPER CTRL G
hl.unbind(mainMod .. " + G")
hl.bind(mainMod .. " + CTRL + G", hl.dsp.group.toggle(),
    { description = "raggruppa/separa le finestre" })
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(scriptsDir .. "/gamelauncher.sh"),
    { description = "Game Launcher" })

-- OCR dallo schermo: seleziona un'area e il testo finisce negli appunti.
-- Con SHIFT il testo passa a qwen in locale (riassumi, traduci, spiega, correggi).
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd(userScripts .. "/OCR.sh"),
    { description = "OCR: copia il testo dallo schermo" })
hl.bind(mainMod .. " + ALT + SHIFT + T", hl.dsp.exec_cmd(userScripts .. "/OCR.sh --ia"),
    { description = "OCR e chiedi all'IA locale" })

-- Agente IA predefinito, come il "default agent" di Omarchy.
hl.bind(mainMod .. " + SHIFT + CTRL + A", hl.dsp.exec_cmd("kitty -e claude"),
    { description = "apri l'agente IA (Claude Code)" })

-- La dettatura vocale non passa da qui: voxtype ascolta F9 direttamente
-- dalla tastiera (tieni premuto, parla, rilascia). Si configura con
-- `voxtype config set hotkey.key <TASTO>`.
--
-- Ripulitura del testo dettato: si chiede a mano, non e' automatica. Un modello
-- piccolo ogni tanto riformula e cambia il senso, e Whisper punteggia gia' bene.
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd(userScripts .. "/RipulisciTesto.sh"),
    { description = "ripulisci con l'IA il testo selezionato" })

-- Per passare la tastiera a una macchina virtuale:
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
-- hl.define_submap("passthru", function()
--     hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)
