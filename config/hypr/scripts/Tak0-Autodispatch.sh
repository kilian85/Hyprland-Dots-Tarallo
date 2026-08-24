#!/usr/bin/env bash

# ─────────────────────────────────────────────────────────────────────────────
# Tak0-Autodispatch.sh
# ─────────────────────────────────────────────────────────────────────────────
# This script is an "authoritative spawn dispatcher" for Hyprland.
#
# Its purpose is to FORCE all windows belonging to a single application launch
# (main window + helpers + Electron / Steam child processes)
# onto a specific workspace.
#
# It explicitly ignores:
#   • spawn race conditions
#   • delayed window creation
#   • detached helper processes
#   • Electron / Chromium / Steam madness
#
# Typical use cases:
#   • Prevent apps from spawning on the currently focused workspace
#   • Control applications that completely ignore static windowrules
#
# Invocation:
#   ./Tak0-Autodispatch.sh <workspace> [rule ...] -- <command>
#
# Important notes:
#   • All window rules are TEMPORARY
#   • No permanent pollution of Hyprland configuration
# ─────────────────────────────────────────────────────────────────────────────
# REQUIREMENTS:
#   - hyprctl   → runtime control of Hyprland
#   - jq        → JSON client parsing
#   - pgrep/ps  → process tree inspection

set -u

LOGFILE="$(dirname "$0")/dispatch.log"

# ─────────────────────────────────────────────────────────────────────────────
# 0️⃣ ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────
#   $1            → target workspace
#   Next args     → optional capture rules (windowrulev2 syntax)
#   "--"          → argument separator
#   After "--"    → command to execute (verbatim)

TARGET_WS="$1"
shift || true

CAPTURE_RULES=()
while [[ "${1-}" != "--" && -n "${1-}" ]]; do
  CAPTURE_RULES+=("$1")
  shift || break
done

if [[ "${1-}" == "--" ]]; then
  shift
fi

CMD="$*"

if [[ -z "$TARGET_WS" || -z "$CMD" ]]; then
  echo "Usage: $0 <workspace> [rule rule ...] -- <command>" >>"$LOGFILE"
  exit 1
fi

echo "=== Deploy '$CMD' → WS $TARGET_WS @ $(date) ===" >>"$LOGFILE"

# ─────────────────────────────────────────────────────────────────────────────
# 1️⃣ HYPRLAND READINESS GATE
# ─────────────────────────────────────────────────────────────────────────────
#   Hyprland may not be fully initialized during early autostart.
#   hyprctl silently fails if called too early.

for _ in {1..50}; do
  hyprctl -j monitors >/dev/null 2>&1 && break
  sleep 0.1
done

# ─────────────────────────────────────────────────────────────────────────────
# 2️⃣ CLEANUP GUARANTEE
# ─────────────────────────────────────────────────────────────────────────────
#   Ensures that ALL temporary rules are removed
#   even on crash, SIGTERM, or user interruption.

# Dalla 0.55 le regole si creano con `hyprctl eval` e la nuova API Lua.
# Le regole con nome restituiscono un riferimento: lo teniamo in una variabile
# globale lua (_G) per poterle spegnere piu' tardi, visto che ogni `eval` gira
# in una chiamata separata. Non esiste piu' un "unset".

# Traduce una regola in vecchia sintassi (class:^(x)$) in una tabella `match`.
rule_to_match() {
  local rule="$1" key value
  key="${rule%%:*}"
  value="${rule#*:}"
  case "$key" in
    class)        echo "{ class = \"$value\" }" ;;
    initialClass) echo "{ initial_class = \"$value\" }" ;;
    title)        echo "{ title = \"$value\" }" ;;
    initialTitle) echo "{ initial_title = \"$value\" }" ;;
    *)            echo "" ;;
  esac
}

disable_rule() {
  hyprctl eval "if _G.$1 then _G.$1:set_enabled(false) end" >>"$LOGFILE" 2>&1 || true
}

cleanup() {
  echo "Cleanup: removing temporary capture rules and initialWorkspace at $(date)" >>"$LOGFILE"

  disable_rule tak0_wide
  local i=0
  for RULE in "${CAPTURE_RULES[@]}"; do
    i=$((i + 1))
    echo "Cleanup: removing temporary capture rule: $RULE" >>"$LOGFILE"
    disable_rule "tak0_cap_$i"
  done
}

trap cleanup EXIT INT TERM ERR

# ─────────────────────────────────────────────────────────────────────────────
# 3️⃣ ULTRA-EARLY GLOBAL CAPTURE (NUCLEAR OPTION)
# ─────────────────────────────────────────────────────────────────────────────
#   Temporarily forces ALL windows (initialClass:.*)
#   onto the target workspace.
#
#   Protects against ultra-fast helpers:
#     • gpu-process
#     • renderer
#     • steamwebhelper

echo "Applying temporary initialWorkspace capture (initialClass:.*)" >>"$LOGFILE"
hyprctl eval "_G.tak0_wide = hl.window_rule({ name = \"tak0-wide\", match = { initial_class = \".*\" }, workspace = \"$TARGET_WS silent\" })" \
  >>"$LOGFILE" 2>&1 || true

# ─────────────────────────────────────────────────────────────────────────────
# 3️⃣.1 OPTIONAL CLASS-BASED PRE-CAPTURE
# ─────────────────────────────────────────────────────────────────────────────
#   Additional precision rules.
#   Useful for Electron / Steam multi-process hell.

RULE_INDEX=0
for RULE in "${CAPTURE_RULES[@]}"; do
  RULE_INDEX=$((RULE_INDEX + 1))
  MATCH="$(rule_to_match "$RULE")"
  if [[ -z "$MATCH" ]]; then
    echo "Regola non riconosciuta, ignorata: $RULE" >>"$LOGFILE"
    continue
  fi
  echo "Applying temporary capture rule: $RULE" >>"$LOGFILE"
  hyprctl eval "_G.tak0_cap_$RULE_INDEX = hl.window_rule({ name = \"tak0-cap-$RULE_INDEX\", match = $MATCH, workspace = \"$TARGET_WS silent\" })" \
    >>"$LOGFILE" 2>&1 || true
done

# ─────────────────────────────────────────────────────────────────────────────
# 4️⃣ APPLICATION LAUNCH
# ─────────────────────────────────────────────────────────────────────────────
#   bash -c allows aliases, env vars, wrappers.
#   ROOT_PID is the root of process lineage.

bash -c "$CMD" &
ROOT_PID=$!
echo "Root PID: $ROOT_PID" >>"$LOGFILE"

# Resolve canonical process name
APP_NAME=""
for _ in {1..20}; do
  if [[ -r "/proc/$ROOT_PID/comm" ]]; then
    APP_NAME="$(tr -d '\0' </proc/$ROOT_PID/comm 2>/dev/null || true)"
    break
  fi
  sleep 0.05
done

if [[ -z "$APP_NAME" ]]; then
  read -r -a __toks <<<"$CMD"
  APP_NAME="$(basename "${__toks[0]}")"
fi

echo "App gate name: $APP_NAME" >>"$LOGFILE"

sleep 1.5

#!TO-DO: Release the nuclear option ASAP
echo "Releasing ultra-early wide capture" >>"$LOGFILE"
disable_rule tak0_wide

# ─────────────────────────────────────────────────────────────────────────────
# 5️⃣ SUPERVISION LOOP (AUTHORITATIVE PHASE)
# ─────────────────────────────────────────────────────────────────────────────
#   This loop:
#     • scans ALL Hyprland clients
#     • matches PID lineage
#     • matches detached helpers
#     • matches class rules

get_descendants() {
  local root="$1"
  local all=("$root")
  local changed=1

  while ((changed)); do
    changed=0
    for p in "${all[@]}"; do
      for c in $(pgrep -P "$p" 2>/dev/null || true); do
        if [[ ! " ${all[*]} " =~ " $c " ]]; then
          all+=("$c")
          changed=1
        fi
      done
    done
  done

  echo "${all[@]}"
}

pid_matches_app() {
  local pid="$1"
  local comm
  comm="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
  [[ "$comm" == "$APP_NAME" || "$comm" == "$APP_NAME"* ]]
}

END_TIME=$((SECONDS + 20))
declare -A SEEN

while ((SECONDS < END_TIME)); do
  PIDS="$(get_descendants "$ROOT_PID")"

  while IFS=$'\t' read -r PID ADDR CLASS; do
    MATCH=0

    for TPID in $PIDS; do
      [[ "$PID" == "$TPID" ]] && MATCH=1 && break
    done

    pid_matches_app "$PID" && MATCH=1

    for RULE in "${CAPTURE_RULES[@]}"; do
      if [[ "$RULE" =~ class:\^\((.*)\)\$ ]]; then
        [[ "$CLASS" =~ ${BASH_REMATCH[1]} ]] && MATCH=1
      fi
    done

    if ((MATCH)) && [[ -z "${SEEN[$ADDR]-}" ]]; then
      echo "Placing window $ADDR (pid $PID, class $CLASS) → WS $TARGET_WS" >>"$LOGFILE"
      hyprctl dispatch \
        "hl.dsp.window.move({ workspace = \"$TARGET_WS\", follow = false, window = \"address:$ADDR\" })" \
        >>"$LOGFILE" 2>&1 || true
      SEEN[$ADDR]=1
    fi
  done < <(hyprctl clients -j | jq -r '.[] | [.pid, .address, .class] | @tsv')

  sleep 0.01
done

echo "=== Deploy finished: '$CMD' ===" >>"$LOGFILE"
exit 0
