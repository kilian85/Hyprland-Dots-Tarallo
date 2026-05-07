#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Check if rofi or yad is running and kill them if they are
if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

# Icona Nerd Font per il tasto Super/Windows (U+EBC6)
S=$(printf '\xee\xaf\x86')

# Launch yad with calculated width and height
GDK_BACKEND=$BACKEND yad \
    --center \
    --width=900 --height=700 \
    --title="KooL Quick Cheat Sheet" \
    --no-buttons \
    --list \
    --column=Tasto: \
    --column=Descrizione: \
    --column=Comando: \
    --timeout-indicator=bottom \
"ESC" "chiudi questa app" "" \
"${S} = " "TASTO SUPER (Tasto Windows)" "(TASTO SUPER)" \
"${S} SHIFT K" "Cerca tasti di scelta rapida" "(Cerca tutti i tasti via rofi)" \
"${S} SHIFT E" "Menu impostazioni KooL Hyprland" "" \
"${S} enter" "Terminale" "(kitty)" \
"${S} SHIFT enter" "Terminale a tendina" "Q per chiudere" \
"${S} B" "Apri browser" "(browser predefinito)" \
"${S} A" "Panoramica desktop" "(AGS - se installato)" \
"${S} D" "Avvia applicazione" "(rofi-wayland)" \
"${S} E" "Apri gestore file" "(Thunar)" \
"${S} S" "Ricerca Google con rofi" "(rofi)" \
"${S} T" "Cambia tema globale" "(rofi)" \
"${S} Q" "Chiudi finestra attiva" "(non termina il processo)" \
"${S} W" "Scegli sfondo" "(Menu sfondi)" \
"${S} G" "Avvia Game Launcher" "(selettore giochi)" \
"${S} H" "Apri questo foglio rapido" "" \
"${S} F2" "Cambia profilo energetico" "Risparmio → Bilanciato → Prestazioni massime" \
"${S} Print" "Screenshot" "(grim)" \
"${S} SPACEBAR" "Attiva/disattiva finestra flottante" "finestra singola" \
"${S} SHIFT Q" "Termina finestra attiva" "(termina il processo)" \
"${S} SHIFT W" "Scegli effetti sfondo" "(imagemagick + swww)" \
"${S} SHIFT G" "Modalità gioco! Animazioni ON o OFF" "attiva/disattiva" \
"${S} SHIFT N" "Apri pannello notifiche" "Centro notifiche swaync" \
"${S} SHIFT F" "Schermo intero" "Attiva/disattiva schermo intero" \
"${S} SHIFT A" "Menu animazioni" "Scegli animazioni via rofi" \
"${S} SHIFT S" "Screenshot area" "(swappy)" \
"${S} SHIFT Print" "Screenshot area" "(grim + slurp)" \
"${S} CTRL G" "Raggruppa/separa finestre" "toggle group" \
"${S} CTRL B" "Scegli stile waybar" "(stili waybar)" \
"${S} CTRL F" "Schermo intero finto" "Attiva/disattiva schermo intero finto" \
"${S} CTRL O" "Attiva/disattiva opacità" "solo finestra attiva" \
"${S} CTRL R" "Menu temi Rofi" "Scegli temi Rofi via rofi" \
"${S} CTRL Print" "Screenshot con timer 5 sec" "(grim)" \
"${S} ALT V" "Gestore appunti" "(cliphist)" \
"${S} ALT B" "Scegli layout waybar" "(layout waybar)" \
"${S} ALT R" "Ricarica Waybar swaync Rofi" "CONTROLLA LE NOTIFICHE PRIMA!!!" \
"${S} ALT L" "Cambia layout Dwindle | Master" "Layout Hyprland" \
"${S} ALT SPACEBAR" "Tutte le finestre flottanti" "tutte le finestre" \
"${S} ALT O" "Attiva/disattiva sfocatura" "sfocatura normale o ridotta" \
"${S} ALT E" "Emoticon Rofi" "Emoticon" \
"${S} ALT rotella su/giù" "Zoom desktop" "Lente di ingrandimento" \
"${S} ALT Print" "Screenshot finestra attiva" "solo finestra attiva" \
"${S} CTRL SHIFT R" "Menu temi Rofi v2" "Scegli temi via selettore (modificato)" \
"${S} CTRL SHIFT Print" "Screenshot con timer 10 sec" "(grim)" \
"${S} CTRL ALT W" "Sfondo casuale" "(via swww)" \
"${S} CTRL ALT B" "Mostra/Nascondi Waybar" "waybar" \
"${S} CTRL ALT P" "Menu di alimentazione" "(wlogout)" \
"${S} CTRL ALT L" "Blocca schermo" "(hyprlock)" \
"${S} CTRL ALT Del" "Esci da Hyprland" "(ATTENZIONE: Hyprland si chiude immediatamente)"
