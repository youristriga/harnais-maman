#!/bin/bash
# memoire-vive — contexte de la passe d'intelligence.
# Résout : espace mémoire, dossier des conversations Claude Code, fenêtre
# incrémentale (ne réanalyser que le nouveau), état de la dernière passe.
# Déterministe, lecture seule. Sort des lignes CLE=VALEUR à consommer par le skill.
#
# Usage : contexte.sh [VAULT]

set -u

VAULT="${1:-}"
if [ -z "$VAULT" ]; then
  CONFIG="$HOME/.memoire-vive"
  [ -f "$CONFIG" ] && VAULT="$(head -n1 "$CONFIG")"
fi
if [ -z "$VAULT" ] || [ ! -d "$VAULT" ]; then
  echo "VAULT="
  echo "ERREUR=espace-memoire-introuvable"
  exit 1
fi
echo "VAULT=$VAULT"

ASSIST_DIR="$VAULT/moi/assistant"
ETAT="$ASSIST_DIR/etat-intelligence.txt"
LOG="$ASSIST_DIR/sessions.log"

# --- État de la dernière passe ----------------------------------------------
DERNIERE_PASSE=""; BASELINE=0
if [ -f "$ETAT" ]; then
  DERNIERE_PASSE="$(sed -n 's/^derniere-passe=//p' "$ETAT" | head -n1)"
  BASELINE="$(sed -n 's/^sessions-a-la-derniere-passe=//p' "$ETAT" | head -n1)"
fi
[ -z "$BASELINE" ] && BASELINE=0
echo "DERNIERE_PASSE=${DERNIERE_PASSE:-jamais}"

TOTAL_SESSIONS=0
[ -f "$LOG" ] && TOTAL_SESSIONS="$(wc -l < "$LOG" 2>/dev/null | tr -d ' ')"
[ -z "$TOTAL_SESSIONS" ] && TOTAL_SESSIONS=0
SESSIONS_DEPUIS=$(( TOTAL_SESSIONS - BASELINE ))
[ "$SESSIONS_DEPUIS" -lt 0 ] && SESSIONS_DEPUIS=0
echo "SESSIONS_TOTAL=$TOTAL_SESSIONS"
echo "SESSIONS_DEPUIS=$SESSIONS_DEPUIS"

# --- Fenêtre incrémentale : depuis quelle date analyser ? -------------------
# Première passe : 60 jours en arrière. Sinon : depuis la dernière passe.
if [ -n "$DERNIERE_PASSE" ]; then
  FENETRE_DEPUIS="$DERNIERE_PASSE"
  echo "PREMIERE_PASSE=non"
else
  FENETRE_DEPUIS="$(date -v-60d +%F 2>/dev/null || date -d '60 days ago' +%F 2>/dev/null)"
  echo "PREMIERE_PASSE=oui"
fi
echo "FENETRE_DEPUIS=$FENETRE_DEPUIS"

# --- Localisation des conversations Claude Code (100% local) ----------------
# Les transcriptions vivent dans ~/.claude/projects/<chemin-encodé>/*.jsonl.
# L'encodage remplace les caractères non alphanumériques par des tirets.
PROJ_ROOT="$HOME/.claude/projects"
TDIR=""; CONF="faible"
if [ -d "$PROJ_ROOT" ]; then
  # 1) candidat par encodage direct du chemin du vault
  ENC="$(printf '%s' "$VAULT" | sed 's/[^A-Za-z0-9]/-/g')"
  if [ -d "$PROJ_ROOT/$ENC" ]; then
    TDIR="$PROJ_ROOT/$ENC"; CONF="haute"
  else
    # 2) sinon : dossier de projet le plus récemment actif qui référence le vault
    #    (parcours du plus récent au plus ancien)
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      if ls "$d"/*.jsonl >/dev/null 2>&1; then
        if grep -qsF "$VAULT" "$d"/*.jsonl 2>/dev/null; then
          TDIR="$d"; CONF="haute"; break
        fi
        [ -z "$TDIR" ] && TDIR="$d"   # repli : le plus récent, confiance faible
      fi
    done <<< "$(ls -dt "$PROJ_ROOT"/*/ 2>/dev/null)"
  fi
fi
echo "TRANSCRIPTS_DIR=${TDIR:-}"
echo "TRANSCRIPTS_CONFIANCE=$CONF"

# Nombre de conversations nouvelles depuis la fenêtre (fichiers modifiés après)
NB_NOUVELLES=0
if [ -n "$TDIR" ] && [ -n "$FENETRE_DEPUIS" ]; then
  REF="$ASSIST_DIR/.ref-fenetre"
  # touch -t attend AAAAMMJJhhmm ; on convertit AAAA-MM-JJ -> minuit
  STAMP="$(printf '%s0000' "$(printf '%s' "$FENETRE_DEPUIS" | tr -d '-')")"
  if touch -t "$STAMP" "$REF" 2>/dev/null; then
    NB_NOUVELLES="$(find "$TDIR" -name '*.jsonl' -newer "$REF" 2>/dev/null | wc -l | tr -d ' ')"
    rm -f "$REF" 2>/dev/null
  fi
fi
echo "CONVERSATIONS_NOUVELLES=$NB_NOUVELLES"
exit 0
