#!/usr/bin/env bash
# Assegna SUPER+J e SUPER+K in modo che ruotino sempre fra le finestre, a
# prescindere dalla disposizione attiva: evita che l'azione venga eseguita due
# volte quando si cambia disposizione.
# Dalla 0.55 la configurazione e' in Lua: si usa `hyprctl eval`.

set -euo pipefail

hyprctl eval 'hl.unbind("SUPER + J")' >/dev/null 2>&1 || true
hyprctl eval 'hl.unbind("SUPER + K")' >/dev/null 2>&1 || true

# J = finestra successiva, K = precedente
hyprctl eval 'hl.bind("SUPER + J", hl.dsp.window.cycle_next(), { description = "finestra successiva" })'
hyprctl eval 'hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }), { description = "finestra precedente" })'
