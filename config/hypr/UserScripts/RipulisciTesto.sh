#!/usr/bin/env bash
# Ripulisce con qwen in locale il testo selezionato (o quello negli appunti):
# punteggiatura, maiuscole, refusi, ripetizioni del parlato.
#
# Pensato per rifinire una dettatura quando serve un testo curato. La dettatura
# normale (F9) resta fedele parola per parola: la ripulitura si chiede a mano,
# perche' un modello piccolo ogni tanto cambia il senso della frase.
#
#   RipulisciTesto.sh            testo selezionato -> ripulito e riscritto
#   RipulisciTesto.sh --appunti  lavora sugli appunti, senza digitare

set -uo pipefail

POSTPROCESS="$(dirname "$0")/dettatura_postprocess.sh"
avvisa() { notify-send -a "Ripulisci testo" "$1" "${2:-}"; }

TESTO="$(wl-paste --primary --no-newline 2>/dev/null)"      # selezione col mouse
[[ -z "${TESTO// }" ]] && TESTO="$(wl-paste --no-newline 2>/dev/null)"  # appunti

if [[ -z "${TESTO// }" ]]; then
	avvisa "Niente da ripulire" "Seleziona un testo, poi ripremi."
	exit 1
fi

avvisa "⏳ Ci penso io…" "$(printf '%s' "$TESTO" | head -c 120)"
PULITO="$("$POSTPROCESS" <<< "$TESTO")"

if [[ -z "${PULITO// }" ]]; then
	avvisa "Non sono riuscito a ripulirlo" "Ollama risponde? Il testo è rimasto com'era."
	exit 1
fi

printf '%s' "$PULITO" | wl-copy

if [[ "${1:-}" == "--appunti" ]]; then
	avvisa "✅ Ripulito e copiato" "$PULITO"
	exit 0
fi

sleep 0.2
if wtype -- "$PULITO" 2>/dev/null; then
	avvisa "✅ Ripulito" "$PULITO"
else
	avvisa "✅ Ripulito, ma non ho potuto digitarlo" "È negli appunti: incollalo con CTRL+V."
fi
