#!/usr/bin/env bash
# OCR dallo schermo: seleziona un'area, ne estrae il testo e lo copia negli appunti.
# Con --ia il testo estratto passa a Ollama in locale (riassunto, traduzione, spiegazione).
#
#   OCR.sh          selezione area -> testo negli appunti
#   OCR.sh --ia     selezione area -> testo -> menu azioni -> risposta di qwen
#   OCR.sh --schermo intero schermo invece della selezione

set -uo pipefail

LINGUE="ita+eng"
MODELLO="${OCR_MODELLO_IA:-qwen3.5:4b}"
TMP="$(mktemp -d /tmp/ocr-hypr.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

avvisa() { notify-send -a "OCR" "$1" "${2:-}"; }

for cmd in grim tesseract wl-copy notify-send; do
	command -v "$cmd" >/dev/null || { avvisa "Manca $cmd" "Installalo per usare l'OCR."; exit 1; }
done

# --- cattura -----------------------------------------------------------------
if [[ "${1:-}" == "--schermo" ]]; then
	grim "$TMP/shot.png" || exit 1
	shift
else
	command -v slurp >/dev/null || { avvisa "Manca slurp"; exit 1; }
	# hyprpicker congela lo schermo: si puo' fare OCR anche su un video o su un menu
	# che sparirebbe appena parte la selezione (trucco preso da Omarchy).
	PICKER=""
	if command -v hyprpicker >/dev/null; then
		hyprpicker -r -z >/dev/null 2>&1 &
		PICKER=$!
		sleep 0.2
	fi
	AREA="$(slurp -d 2>/dev/null)"   # ESC = annullato
	[[ -n "$PICKER" ]] && kill "$PICKER" 2>/dev/null
	[[ -z "$AREA" ]] && exit 0
	grim -g "$AREA" "$TMP/shot.png" || exit 1
fi

# --- riconoscimento ----------------------------------------------------------
# L'ingrandimento aiuta parecchio tesseract sul testo piccolo delle interfacce.
if command -v magick >/dev/null; then
	magick "$TMP/shot.png" -colorspace Gray -resize 300% -sharpen 0x1 "$TMP/pronta.png"
else
	cp "$TMP/shot.png" "$TMP/pronta.png"
fi

TESTO="$(tesseract "$TMP/pronta.png" - -l "$LINGUE" --oem 1 --psm 6 --dpi 300 \
	-c preserve_interword_spaces=1 2>/dev/null | sed -e 's/[[:space:]]*$//' -e '/^$/d')"

if [[ -z "$TESTO" ]]; then
	avvisa "Nessun testo riconosciuto" "Prova a selezionare un'area più grande o con più contrasto."
	exit 1
fi

printf '%s' "$TESTO" | wl-copy
RIGHE=$(printf '%s\n' "$TESTO" | wc -l)

# --- solo copia --------------------------------------------------------------
if [[ "${1:-}" != "--ia" ]]; then
	avvisa "Testo copiato ($RIGHE righe)" "$(printf '%s' "$TESTO" | head -c 300)"
	exit 0
fi

# --- passaggio all'IA locale -------------------------------------------------
command -v ollama >/dev/null || { avvisa "Ollama non installato" "Il testo è comunque negli appunti."; exit 1; }

AZIONE="$(printf 'Riassumi\nTraduci in italiano\nTraduci in inglese\nSpiega\nCorreggi il testo\n' |
	rofi -dmenu -i -p "Cosa ne faccio?" -theme-str 'window {width: 30%;}' 2>/dev/null)"
[[ -z "$AZIONE" ]] && exit 0

case "$AZIONE" in
	"Riassumi")            ISTRUZIONE="Riassumi in italiano, in poche righe, il testo qui sotto." ;;
	"Traduci in italiano") ISTRUZIONE="Traduci in italiano il testo qui sotto. Rispondi solo con la traduzione." ;;
	"Traduci in inglese")  ISTRUZIONE="Traduci in inglese il testo qui sotto. Rispondi solo con la traduzione." ;;
	"Spiega")              ISTRUZIONE="Spiega in italiano, in modo semplice, cosa dice il testo qui sotto." ;;
	"Correggi il testo")   ISTRUZIONE="Correggi errori e refusi nel testo qui sotto, mantenendo la lingua originale. Rispondi solo con il testo corretto." ;;
	*)                     ISTRUZIONE="$AZIONE" ;;
esac

avvisa "Ci penso io…" "$AZIONE con $MODELLO"
printf '%s\n\n---\n%s\n' "$ISTRUZIONE" "$TESTO" > "$TMP/prompt.txt"

if ! ollama run "$MODELLO" < "$TMP/prompt.txt" > "$TMP/risposta.txt" 2> "$TMP/errore.txt"; then
	avvisa "Ollama ha fallito" "$(head -c 200 "$TMP/errore.txt")"
	exit 1
fi

# Via il ragionamento dei modelli "thinking", che altrimenti inonda la finestra.
sed -i -e '/<think>/,/<\/think>/d' -e '/^$/{ /./!d }' "$TMP/risposta.txt"

printf '%s' "$(cat "$TMP/risposta.txt")" | wl-copy
cp "$TMP/risposta.txt" /tmp/ocr-ultima-risposta.txt
kitty --title "OCR · $AZIONE" -o confirm_os_window_close=0 \
	sh -c 'cat /tmp/ocr-ultima-risposta.txt; echo; echo "— copiato negli appunti. Invio per chiudere."; read _' &
