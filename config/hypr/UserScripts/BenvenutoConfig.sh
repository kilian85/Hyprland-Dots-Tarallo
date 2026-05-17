#!/usr/bin/env bash
# GUI per modificare il messaggio di benvenuto all'avvio

BENVENUTO_SH="$HOME/.config/hypr/scripts/Benvenuto.sh"
FLAG_FILE="$HOME/.config/hypr/.benvenuto_disabled"

# Legge il messaggio attuale
CURRENT=$(grep 'echo ' "$BENVENUTO_SH" | sed 's/.*echo "\(.*\)" |.*/\1/')

# Stato attuale: se il flag NON esiste = abilitato
[ -f "$FLAG_FILE" ] && ENABLED="FALSE" || ENABLED="TRUE"

# Mostra la finestra yad
RESULT=$(yad \
    --title="Messaggio di Benvenuto" \
    --center \
    --width=450 \
    --form \
    --field="Messaggio (es. Ciao Tarallo, benvenuto!):TEXT" "$CURRENT" \
    --field="Abilita saluto vocale all'avvio:CHK" "$ENABLED" \
    --button="Anteprima:2" \
    --button="Conferma:0" \
    --button="Annulla:1")

EXIT_CODE=$?

[ $EXIT_CODE -eq 1 ] && exit 0

MSG=$(echo "$RESULT" | cut -d'|' -f1 | xargs)
NEW_ENABLED=$(echo "$RESULT" | cut -d'|' -f2)

if [ -z "$MSG" ]; then
    yad --title="Errore" --center --text="Il messaggio non può essere vuoto." --button="OK:0" --image="dialog-error"
    exit 1
fi

# Anteprima
if [ $EXIT_CODE -eq 2 ]; then
    notify-send -u low -t 3000 "🔊 Anteprima" "Generazione audio in corso..."
    echo "$MSG" | piper-tts --model "$HOME/.local/share/piper/it_IT-paola-medium.onnx" --output_file /tmp/benvenuto_preview.wav 2>/dev/null && paplay /tmp/benvenuto_preview.wav
    exec "$0"
    exit 0
fi

# Aggiorna abilitazione
if [ "$NEW_ENABLED" = "TRUE" ]; then
    rm -f "$FLAG_FILE"
else
    touch "$FLAG_FILE"
fi

# Aggiorna lo script con il nuovo messaggio (awk per gestire | e \ nel testo)
awk -v msg="$MSG" '{gsub(/echo "[^"]*" \| piper-tts/, "echo \"" msg "\" | piper-tts")} 1' "$BENVENUTO_SH" > "${BENVENUTO_SH}.tmp" && chmod +x "${BENVENUTO_SH}.tmp" && mv "${BENVENUTO_SH}.tmp" "$BENVENUTO_SH"

# Pregenera il file audio così all'avvio non c'è ritardo
notify-send -u low -t 3000 "🔊 Benvenuto" "Generazione audio in corso..."
echo "$MSG" | piper-tts --model "$HOME/.local/share/piper/it_IT-paola-medium.onnx" --output_file "$HOME/.cache/benvenuto.wav" 2>/dev/null

if [ "$NEW_ENABLED" = "TRUE" ]; then
    STATUS_MSG="✅ Saluto vocale <b>abilitato</b>"
else
    STATUS_MSG="🔇 Saluto vocale <b>disabilitato</b>"
fi

yad --title="Impostazioni aggiornate" --center \
    --text="Messaggio:\n<b>$MSG</b>\n\n$STATUS_MSG" \
    --button="OK:0" --image="dialog-information" --timeout=3
