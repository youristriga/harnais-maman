#!/bin/bash
# memoire-vive — clôture d'une passe d'intelligence.
# Écrit le carnet d'état (pour que la prochaine passe soit incrémentale) et
# ajoute une entrée datée au journal de bord de l'assistant.
# Déterministe.
#
# Usage : cloturer.sh <VAULT> "<résumé d'une ligne pour le journal de bord>"

set -u

VAULT="${1:-}"
RESUME="${2:-passe de progrès effectuée}"
if [ -z "$VAULT" ] || [ ! -d "$VAULT" ]; then
  echo "ERREUR: espace mémoire introuvable"
  exit 1
fi

ASSIST_DIR="$VAULT/moi/assistant"
mkdir -p "$ASSIST_DIR"
ETAT="$ASSIST_DIR/etat-intelligence.txt"
LOG="$ASSIST_DIR/sessions.log"
JOURNAL="$ASSIST_DIR/journal-de-bord.md"

TODAY="$(date +%F)"
NOW="$(date '+%F %H:%M')"

TOTAL_SESSIONS=0
[ -f "$LOG" ] && TOTAL_SESSIONS="$(wc -l < "$LOG" 2>/dev/null | tr -d ' ')"
[ -z "$TOTAL_SESSIONS" ] && TOTAL_SESSIONS=0

# Carnet d'état (réécrit à neuf)
printf 'derniere-passe=%s\nsessions-a-la-derniere-passe=%s\n' "$TODAY" "$TOTAL_SESSIONS" > "$ETAT"

# Journal de bord (créé au besoin, puis on ajoute une entrée en tête d'historique)
if [ ! -s "$JOURNAL" ]; then
  printf '%s\n' "# Journal de bord de l'assistant

Ce que j'ai appris et amélioré au fil des passes « point pour progresser ».
" > "$JOURNAL"
fi
printf '\n## %s\n%s\n' "$NOW" "$RESUME" >> "$JOURNAL"

echo "OK: passe clôturée (derniere-passe=$TODAY, sessions=$TOTAL_SESSIONS)"
exit 0
