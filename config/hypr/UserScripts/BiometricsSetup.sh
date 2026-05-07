#!/usr/bin/env bash
# BiometricsSetup.sh
# Procedura guidata di configurazione periferiche biometriche
# Eseguita automaticamente al primo avvio oppure da menu applicazioni

FLAG="$HOME/.config/hypr/.biometrics_configured"

# Se già configurato in precedenza, chiedi se riconfigurare
if [ -f "$FLAG" ]; then
    REDO=$(printf "🔧  Riconfigura le impostazioni\n❌  Annulla" | rofi -dmenu -p "" \
        -mesg "$(printf "La configurazione biometrica è già stata eseguita.\nVuoi riconfigurarla?")" \
        -theme-str 'window { width: 700px; } listview { lines: 2; } element { padding: 12px; }')
    [ -z "$REDO" ] || [[ "$REDO" == *"Annulla"* ]] && exit 0
fi

# ─── Funzioni rofi ────────────────────────────────────────────────────────────

rofi_ask() {
    # $1=prompt  $2=mesg  $3=opzioni  $4=numero righe
    local lines="${4:-4}"
    local mesg; mesg=$(printf "%b" "$2")
    printf "%b" "$3" | rofi -dmenu -p "$1" -mesg "$mesg" \
        -theme-str "window { width: 900px; } listview { lines: ${lines}; } element { padding: 12px; }"
}

rofi_info() {
    # $1=mesg
    local mesg; mesg=$(printf "%b" "$1")
    printf "▶   Continua" | rofi -dmenu -p "" -mesg "$mesg" \
        -theme-str 'window { width: 900px; } listview { lines: 1; } element { padding: 12px; }'
}

# ─── Rilevamento hardware ─────────────────────────────────────────────────────

FP_HW=false;  FP_WORKING=false;  FP_ENROLLED=false
IR_HW=false;  IR_WORKING=false;  IR_ENROLLED=false;  IR_DEVICE=""

FP_VENDORS_RE="138a:|06cb:|1c7a:|27c6:|1491:|147e:|2808:|04f3:0[89c]"
if lsusb 2>/dev/null | grep -qE "$FP_VENDORS_RE"; then
    FP_HW=true
    if fprintd-list "$USER" &>/dev/null 2>&1; then
        FP_WORKING=true
        fprintd-list "$USER" 2>/dev/null | grep -q "finger" && FP_ENROLLED=true
    fi
fi

for _dev_name_path in /sys/class/video4linux/video*/name; do
    [ -f "$_dev_name_path" ] || continue
    _dev_name=$(cat "$_dev_name_path" 2>/dev/null)
    echo "$_dev_name" | grep -qi "IR\|infrared" || continue
    IR_HW=true
    IR_DEVICE="/dev/$(basename "$(dirname "$_dev_name_path")")"
    if command -v v4l2-ctl &>/dev/null && v4l2-ctl -d "$IR_DEVICE" --all &>/dev/null 2>&1; then
        IR_WORKING=true
        command -v howdy &>/dev/null && \
            sudo -n howdy list 2>/dev/null | grep -qvE "^\s*$|No models|none" && \
            IR_ENROLLED=true
    fi
    break
done

# ─── Schermata: periferiche rilevate ─────────────────────────────────────────

ANYTHING_WORKING=false
MSG="<b>Periferiche biometriche rilevate su questo PC</b>\n\n"

if $FP_HW; then
    if $FP_WORKING; then
        ANYTHING_WORKING=true
        $FP_ENROLLED \
            && MSG+="✅  <b>Lettore impronte</b>  —  pronto   <i>(impronta già salvata)</i>\n" \
            || MSG+="✅  <b>Lettore impronte</b>  —  pronto   <i>(nessuna impronta salvata)</i>\n"
    else
        MSG+="⚠️   <b>Lettore impronte</b>  —  rilevato ma il driver non è installato\n"
    fi
else
    MSG+="➖  <b>Lettore impronte</b>  —  non presente\n"
fi

if $IR_HW; then
    if $IR_WORKING; then
        ANYTHING_WORKING=true
        $IR_ENROLLED \
            && MSG+="✅  <b>Webcam IR  (riconoscimento viso)</b>  —  pronta   <i>(viso già salvato)</i>\n" \
            || MSG+="✅  <b>Webcam IR  (riconoscimento viso)</b>  —  pronta   <i>(nessun viso salvato)</i>\n"
    else
        MSG+="⚠️   <b>Webcam IR  (riconoscimento viso)</b>  —  rilevata ma il driver non è installato\n"
    fi
else
    MSG+="➖  <b>Webcam IR  (riconoscimento viso)</b>  —  non presente\n"
fi

if ! $FP_HW && ! $IR_HW; then
    MSG+="\n<i>Nessuna periferica biometrica trovata.\nVerrà usata solo la password.</i>"
    rofi_info "$MSG"
    touch "$FLAG"
    exit 0
fi

if ! $ANYTHING_WORKING; then
    MSG+="\n<i>I dispositivi sono stati rilevati ma i driver non funzionano.\nInstalla i driver mancanti e riesegui questa procedura.</i>"
    rofi_info "$MSG"
    touch "$FLAG"
    exit 0
fi

# ─── Scelta: configura ora o dopo ────────────────────────────────────────────

FIRST=$(rofi_ask "" \
    "$MSG\n<i>Vuoi configurare adesso come accedere al PC?</i>" \
    "🔧  Sì, configura ora\n⏭️   No, lo faccio in seguito" 2)
if [ -z "$FIRST" ] || [[ "$FIRST" == *"seguito"* ]]; then
    touch "$FLAG"
    exit 0
fi

# ─── Costruisce le opzioni PAM in base all'hardware disponibile ───────────────

PAM_OPTS=""
PAM_LINES=1
if $FP_WORKING && $IR_WORKING; then
    PAM_OPTS+="👁️  Prima il viso, poi l'impronta, poi la password\n"
    PAM_OPTS+="🖐️  Prima l'impronta, poi il viso, poi la password\n"
    PAM_OPTS+="👁️  Solo riconoscimento viso  (password come riserva)\n"
    PAM_OPTS+="🖐️  Solo impronta digitale  (password come riserva)\n"
    PAM_LINES=5
elif $IR_WORKING; then
    PAM_OPTS+="👁️  Solo riconoscimento viso  (password come riserva)\n"
    PAM_LINES=2
elif $FP_WORKING; then
    PAM_OPTS+="🖐️  Solo impronta digitale  (password come riserva)\n"
    PAM_LINES=2
fi
PAM_OPTS+="🔑  Solo password  (disabilita il biometrico)"

# ─── Step 1: login SDDM ──────────────────────────────────────────────────────

SDDM_CHOICE=$(rofi_ask "" \
    "<b>Passo 1 di 2  —  Sblocco schermo e login</b>\n\nCome vuoi accedere al PC all'avvio?\n<i>Se il metodo scelto non funziona, il sistema chiede comunque la password.</i>" \
    "$PAM_OPTS" "$PAM_LINES")
[ -z "$SDDM_CHOICE" ] && { touch "$FLAG"; exit 0; }

# ─── Step 2: sudo ────────────────────────────────────────────────────────────

SUDO_CHOICE=$(rofi_ask "" \
    "<b>Passo 2 di 2  —  Comandi di sistema (sudo)</b>\n\nCome vuoi confermare operazioni come installare programmi o modificare impostazioni?\n<i>Se il metodo scelto non funziona, il sistema chiede comunque la password.</i>" \
    "$PAM_OPTS" "$PAM_LINES")
[ -z "$SUDO_CHOICE" ] && { touch "$FLAG"; exit 0; }

# ─── Converti scelta in parametro per il helper PAM ──────────────────────────

_to_param() {
    case "$1" in
        *"viso"*"impronta"*) echo "face,fingerprint" ;;
        *"impronta"*"viso"*) echo "fingerprint,face" ;;
        *"viso"*)             echo "face" ;;
        *"impronta"*)         echo "fingerprint" ;;
        *)                    echo "password" ;;
    esac
}

SDDM_PARAM=$(_to_param "$SDDM_CHOICE")
SUDO_PARAM=$(_to_param "$SUDO_CHOICE")

pkexec /usr/local/bin/biometrics-pam-apply sddm "$SDDM_PARAM"
pkexec /usr/local/bin/biometrics-pam-apply sudo "$SUDO_PARAM"

# ─── Step 3: registrazione biometrica ────────────────────────────────────────

ENROLL_OPTS=""
ENROLL_LINES=1
$FP_WORKING && ! $FP_ENROLLED && ENROLL_OPTS+="🖐️  Registra la tua impronta digitale adesso\n" && ((ENROLL_LINES++))
$IR_WORKING && ! $IR_ENROLLED && ENROLL_OPTS+="👁️  Registra il tuo viso adesso\n"             && ((ENROLL_LINES++))

if [ -n "$ENROLL_OPTS" ]; then
    ENROLL_OPTS+="⏭️  Salta — lo faccio in seguito"

    TERM_CMD="kitty"
    for t in kitty alacritty foot wezterm; do
        command -v "$t" &>/dev/null && TERM_CMD="$t" && break
    done

    while true; do
        ENROLL=$(rofi_ask "" \
            "<b>Registrazione credenziali biometriche</b>\n\nVuoi salvare subito le tue credenziali?\n<i>Si aprirà un terminale con le istruzioni passo per passo.\nPuoi farlo anche in seguito da  Menu applicazioni → Configurazione Biometrica</i>" \
            "$ENROLL_OPTS" "$ENROLL_LINES")
        [ -z "$ENROLL" ] || [[ "$ENROLL" == *"seguito"* ]] && break

        if [[ "$ENROLL" == *"impronta"* ]]; then
            $TERM_CMD --title "Registrazione impronta" \
                bash -c 'echo "=== Registrazione impronta digitale ==="; echo;
                         echo "Appoggia il dito sul sensore più volte seguendo le istruzioni."; echo;
                         fprintd-enroll; echo; echo "Premi Invio per chiudere."; read' &
            ENROLL_OPTS="${ENROLL_OPTS/🖐️  Registra la tua impronta digitale adesso$'\n'/}"
        elif [[ "$ENROLL" == *"viso"* ]]; then
            $TERM_CMD --title "Registrazione viso" \
                bash -c 'echo "=== Registrazione riconoscimento viso ==="; echo;
                         echo "Guarda direttamente la webcam IR seguendo le istruzioni."; echo;
                         sudo howdy add; echo; echo "Premi Invio per chiudere."; read' &
            ENROLL_OPTS="${ENROLL_OPTS/👁️  Registra il tuo viso adesso$'\n'/}"
        fi

        [[ "$ENROLL_OPTS" != *"🖐️"* ]] && [[ "$ENROLL_OPTS" != *"👁️"* ]] && break
    done
fi

# ─── Riepilogo ────────────────────────────────────────────────────────────────

touch "$FLAG"

SUMMARY="<b>✅  Configurazione salvata</b>\n\n"
SUMMARY+="<b>Login e sblocco schermo:</b>   $SDDM_CHOICE\n\n"
SUMMARY+="<b>Comandi di sistema:</b>   $SUDO_CHOICE\n\n"
SUMMARY+="<i>Per modificare in seguito: Menu applicazioni → Configurazione Biometrica</i>"

rofi_info "$SUMMARY"
