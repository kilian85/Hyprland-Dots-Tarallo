#!/usr/bin/env bash
# Ripulisce il testo dettato a voce: punteggiatura, maiuscole, refusi,
# ripetizioni del parlato. Riceve il testo su stdin, lo restituisce su stdout.
#
# Prova prima Gemini (conosce l'italiano molto meglio di un modello locale
# piccolo), e se manca la chiave, la rete o la risposta, ripiega su qwen in
# locale. Se fallisce anche quello restituisce il testo originale: meglio
# grezzo che perso.
#
# La chiave sta in ~/.config/dettatura-gemini.env come GEMINI_API_KEY=...
# Senza quel file tutto resta in locale e nulla esce da casa.

set -uo pipefail

ENV_GEMINI="$HOME/.config/dettatura-gemini.env"
MODELLO_GEMINI="${DETTATURA_MODELLO_GEMINI:-gemini-3.5-flash-lite}"
MODELLO_LOCALE="${DETTATURA_MODELLO_IA:-qwen2.5:3b}"
ATTESA_MAX="${DETTATURA_TIMEOUT:-20}"
API_OLLAMA="${OLLAMA_HOST:-http://127.0.0.1:11434}"

ISTRUZIONE='Sistema soltanto punteggiatura, maiuscole, accenti e refusi del testo dettato a voce qui sotto, in italiano, e togli le ripetizioni involontarie.
REGOLA FERREA: ogni parola deve restare quella che era, e una domanda deve restare una domanda. Vietato sostituire parole con sinonimi, riformulare, rispondere, aggiungere o togliere concetti, commentare.
Rispondi soltanto con il testo corretto.'

TESTO="$(cat)"
[[ -z "${TESTO// }" ]] && exit 0
originale() { printf '%s' "$TESTO"; }
command -v curl >/dev/null || { originale; exit 0; }

# Scarta le risposte in cui il modello ha commentato invece di correggere.
plausibile() {
	local r="$1"
	[[ -n "${r// }" ]] && (( ${#r} <= ${#TESTO} * 2 ))
}

# --- Gemini ------------------------------------------------------------------
gemini() {
	[[ -r "$ENV_GEMINI" ]] || return 1
	local chiave
	chiave="$(. "$ENV_GEMINI" 2>/dev/null; printf '%s' "${GEMINI_API_KEY:-}")"
	[[ -n "$chiave" ]] || return 1

	local corpo
	corpo="$(python3 -c '
import json, sys
print(json.dumps({
    "system_instruction": {"parts": [{"text": sys.argv[1]}]},
    "contents": [{"parts": [{"text": sys.argv[2]}]}],
    "generationConfig": {"temperature": 0, "maxOutputTokens": 2048},
}))' "$ISTRUZIONE" "$TESTO" 2>/dev/null)" || return 1

	curl -sS -m 10 -X POST \
		"https://generativelanguage.googleapis.com/v1beta/models/${MODELLO_GEMINI}:generateContent" \
		-H "x-goog-api-key: $chiave" -H 'Content-Type: application/json' \
		-d "$corpo" 2>/dev/null |
		python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d["candidates"][0]["content"]["parts"][0]["text"].strip())
except Exception:
    sys.exit(1)' 2>/dev/null
}

# --- qwen in locale ----------------------------------------------------------
locale_ollama() {
	command -v ollama >/dev/null || return 1
	local corpo
	corpo="$(python3 -c '
import json, sys
print(json.dumps({
    "model": sys.argv[3],
    "prompt": f"{sys.argv[1]}\n\n---\n{sys.argv[2]}",
    "stream": False,
    "keep_alive": "30m",
    "options": {"temperature": 0, "num_predict": 512},
}))' "$ISTRUZIONE" "$TESTO" "$MODELLO_LOCALE" 2>/dev/null)" || return 1

	curl -sS -m "$ATTESA_MAX" -X POST "$API_OLLAMA/api/generate" \
		-H 'Content-Type: application/json' -d "$corpo" 2>/dev/null |
		python3 -c '
import json, re, sys
try:
    t = json.load(sys.stdin).get("response", "")
except Exception:
    sys.exit(1)
print(re.sub(r"<think>.*?</think>", "", t, flags=re.S).strip())' 2>/dev/null
}

RISPOSTA="$(gemini)" || RISPOSTA=""
plausibile "$RISPOSTA" || RISPOSTA="$(locale_ollama)" || RISPOSTA=""
plausibile "$RISPOSTA" && printf '%s' "$RISPOSTA" || originale
