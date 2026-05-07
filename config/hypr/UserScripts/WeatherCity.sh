#!/usr/bin/env bash
# GUI per cambiare la città del meteo

WEATHER_PY="$HOME/.config/hypr/UserScripts/Weather.py"

# Legge la città attuale
CURRENT=$(grep 'MANUAL_PLACE: Optional\[str\]' "$WEATHER_PY" | sed 's/.*= *"\(.*\)".*/\1/')

# Mostra la finestra yad
RESULT=$(yad \
    --title="Impostazioni Meteo" \
    --center \
    --width=400 \
    --form \
    --field="Città (es. Roma, Lazio, IT):TEXT" "$CURRENT" \
    --button="Conferma:0" \
    --button="Annulla:1")

EXIT_CODE=$?

# Se l'utente ha premuto Annulla o chiuso la finestra
[ $EXIT_CODE -ne 0 ] && exit 0

# Estrae il valore inserito
CITY=$(echo "$RESULT" | cut -d'|' -f1 | xargs)

# Controlla che non sia vuoto
if [ -z "$CITY" ]; then
    yad --title="Errore" --center --text="Il campo città non può essere vuoto." --button="OK:0" --image="dialog-error"
    exit 1
fi

# Aggiorna il file Weather.py
sed -i "s|MANUAL_PLACE: Optional\[str\] = \".*\"|MANUAL_PLACE: Optional[str] = \"$CITY\"|" "$WEATHER_PY"

# Ricarica waybar per aggiornare il widget meteo
pkill -SIGUSR2 waybar 2>/dev/null

yad --title="Meteo aggiornato" --center --text="Città impostata su:\n<b>$CITY</b>" --button="OK:0" --image="dialog-information" --timeout=3
