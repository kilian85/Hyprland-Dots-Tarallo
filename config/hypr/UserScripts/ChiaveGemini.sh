#!/usr/bin/env bash
# Configura la chiave di Gemini usata per ripulire il testo dettato con F9.
# Tutto da rofi: niente file da aprire a mano, niente comandi da ricordare.
#
# Senza chiave la dettatura funziona lo stesso: la ripulitura la fa qwen in
# locale. Con la chiave le frasi dettate vengono inviate ai server di Google.

set -uo pipefail

ENV_GEMINI="$HOME/.config/dettatura-gemini.env"
MODELLO="${DETTATURA_MODELLO_GEMINI:-gemini-3.5-flash-lite}"
TITOLO="  Dettatura"

avvisa() { notify-send -a "Dettatura" "$1" "${2:-}"; }

leggi_chiave() {
	[[ -r "$ENV_GEMINI" ]] || return 1
	(. "$ENV_GEMINI" 2>/dev/null; printf '%s' "${GEMINI_API_KEY:-}")
}

# Chiede a Google se la chiave e' buona: meglio scoprirlo adesso che alla prima
# frase dettata.
prova_chiave() {
	local chiave="$1" risposta
	risposta="$(curl -sS -m 15 \
		"https://generativelanguage.googleapis.com/v1beta/models/${MODELLO}:generateContent" \
		-H "x-goog-api-key: $chiave" -H 'Content-Type: application/json' \
		-d '{"contents":[{"parts":[{"text":"Rispondi solo: ok"}]}]}' 2>/dev/null)"
	printf '%s' "$risposta" | grep -q '"text"'
}

salva_chiave() {
	install -m 600 /dev/null "$ENV_GEMINI"
	printf 'GEMINI_API_KEY=%s\n' "$1" > "$ENV_GEMINI"
}

chiedi_chiave() {
	rofi -dmenu -password \
		-p "  Incolla la chiave" \
		-mesg $'<b>Come ottenerla (un minuto, \xc3\xa8 gratis):</b>\n\n  1. Vai su  <i>https://aistudio.google.com/apikey</i>  e accedi con Google\n  2. Premi <b>Create API key</b>\n  3. Copia la chiave e incollala qui sotto (CTRL+V)\n\n<i>La chiave resta sul tuo computer, in ~/.config/dettatura-gemini.env</i>' \
		-markup -lines 0 -width 66 < /dev/null
}

configura() {
	local chiave
	chiave="$(chiedi_chiave)"
	chiave="${chiave//[[:space:]]/}"
	[[ -z "$chiave" ]] && { avvisa "Nessuna chiave inserita" "Non ho cambiato niente."; exit 0; }

	avvisa "⏳ Provo la chiave…" "Un momento."
	if prova_chiave "$chiave"; then
		salva_chiave "$chiave"
		avvisa "✅ Chiave attiva" "Da adesso il testo dettato con F9 viene ripulito da Gemini."
	else
		# La chiave sbagliata non si salva: meglio riprovare che dettare a vuoto.
		local riprova
		riprova="$(printf 'Riprova\nSalvala lo stesso\nAnnulla\n' |
			rofi -dmenu -i -p "$TITOLO" \
				-mesg '<b>Google ha rifiutato questa chiave.</b>\nPuò essere incompleta, scaduta, oppure copiata male.' \
				-markup -lines 3 -width 52)"
		case "$riprova" in
			Riprova) configura ;;
			"Salvala lo stesso")
				salva_chiave "$chiave"
				avvisa "Chiave salvata, ma non verificata" "Se non funziona, la ripulitura passa a qwen in locale."
				;;
			*) avvisa "Annullato" "Non ho cambiato niente." ;;
		esac
	fi
}

# --- menu ---------------------------------------------------------------------
CHIAVE="$(leggi_chiave || true)"

if [[ -z "$CHIAVE" ]]; then
	SCELTA="$(printf 'Configura la chiave (consigliato)\nContinua senza, uso l'"'"'IA locale\n' |
		rofi -dmenu -i -p "$TITOLO" \
			-mesg $'Il testo che detti con <b>F9</b> viene ripulito prima di essere scritto:\npunteggiatura, maiuscole, accenti e ripetizioni del parlato.\n\nCon una <b>chiave gratuita di Gemini</b> il risultato in italiano \xc3\xa8\nnettamente migliore e arriva in meno di un secondo.\nSenza chiave se ne occupa qwen sul tuo computer, pi\xc3\xb9 lentamente.\n\n<i>Attenzione: con la chiave le frasi dettate vengono inviate a Google.</i>' \
			-no-custom -markup -lines 2 -width 66)"
	[[ "$SCELTA" == Configura* ]] && configura || avvisa "Va bene così" "La ripulitura resta in locale. Puoi cambiare idea da rofi: «Chiave Gemini»."
	exit 0
fi

SCELTA="$(printf 'Prova la chiave attuale\nSostituisci la chiave\nRimuovi la chiave (torna tutto in locale)\nAnnulla\n' |
	rofi -dmenu -i -p "$TITOLO" \
		-mesg "Una chiave è già configurata (${#CHIAVE} caratteri, termina con <b>…${CHIAVE: -4}</b>)." \
		-no-custom -markup -lines 4 -width 62)"

case "$SCELTA" in
	"Prova la chiave attuale")
		avvisa "⏳ Provo la chiave…"
		if prova_chiave "$CHIAVE"; then
			avvisa "✅ La chiave funziona" "Gemini risponde: la dettatura viene ripulita da lui."
		else
			avvisa "❌ Google rifiuta la chiave" "Intanto ci pensa qwen in locale. Rifalla da rofi: «Chiave Gemini»."
		fi
		;;
	"Sostituisci la chiave") configura ;;
	"Rimuovi la chiave"*)
		rm -f "$ENV_GEMINI"
		avvisa "Chiave rimossa" "Da adesso la ripulitura è tutta in locale: niente esce da casa."
		;;
	*) : ;;
esac
