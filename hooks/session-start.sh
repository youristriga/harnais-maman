#!/bin/bash
# memoire-vive — hook SessionStart
# Injecte l'état de la mémoire au démarrage de chaque session.
# Zéro dépendance : bash + coreutils macOS uniquement.

CONFIG="$HOME/.memoire-vive"

if [ ! -f "$CONFIG" ]; then
  echo "[memoire-vive] Aucun espace mémoire configuré sur cette machine."
  echo "[memoire-vive] Propose gentiment à l'utilisatrice de taper /demarrage pour créer son espace (installation guidée, 5 minutes)."
  exit 0
fi

VAULT="$(head -n 1 "$CONFIG")"

if [ ! -d "$VAULT" ]; then
  echo "[memoire-vive] Le dossier mémoire « $VAULT » est introuvable (déplacé ou supprimé ?)."
  echo "[memoire-vive] Propose de relancer /demarrage pour le recréer ou le relocaliser."
  exit 0
fi

TODAY="$(date +%F)"
YESTERDAY="$(date -v-1d +%F 2>/dev/null || date -d yesterday +%F 2>/dev/null)"

# Affiche une section bornée en taille si le fichier existe et n'est pas vide.
section() { # $1=titre $2=fichier $3=max octets (défaut 1500)
  if [ -s "$2" ]; then
    echo ""
    echo "--- $1 ---"
    head -c "${3:-1500}" "$2"
    echo ""
  fi
}

echo "=== MÉMOIRE — état injecté automatiquement au démarrage ==="
echo "(Ne pas relire ces fichiers sauf besoin d'un détail non couvert ici.)"
echo "Date : $(LC_TIME=fr_FR.UTF-8 date '+%A %d %B %Y — %H:%M' 2>/dev/null || date '+%Y-%m-%d %H:%M')"
echo "Dossier mémoire : $VAULT"

section "Profil" "$VAULT/moi/profil.md" 1500
section "Règles apprises — À RESPECTER ABSOLUMENT" "$VAULT/regles/reproches.md" 2500
section "Préférences" "$VAULT/regles/preferences.md" 1500
section "Journal d'aujourd'hui ($TODAY)" "$VAULT/quotidien/$TODAY.md" 2500

# Si pas encore de note aujourd'hui, montrer celle d'hier (continuité).
if [ ! -s "$VAULT/quotidien/$TODAY.md" ] && [ -n "$YESTERDAY" ]; then
  section "Journal d'hier ($YESTERDAY)" "$VAULT/quotidien/$YESTERDAY.md" 2000
fi

section "Projets en cours" "$VAULT/projets/_index.md" 2000
section "Tâches pro" "$VAULT/pro/taches.md" 1200
section "Rappels & signaux appris" "$VAULT/regles/signaux.md" 1500

# --- Boucle d'intelligence : journal des sessions + proposition périodique ---
# Tout est en pur bash, sans dépendance. Silencieux si l'espace « moi/assistant »
# n'existe pas encore (rétro-compatible avec les installations d'avant).
ASSIST_DIR="$VAULT/moi/assistant"
mkdir -p "$ASSIST_DIR" 2>/dev/null
SLOG="$ASSIST_DIR/sessions.log"
SETAT="$ASSIST_DIR/etat-intelligence.txt"
printf '%s\n' "$(date '+%F %H:%M')" >> "$SLOG" 2>/dev/null

TOTAL=0
[ -f "$SLOG" ] && TOTAL="$(wc -l < "$SLOG" 2>/dev/null | tr -d ' ')"
[ -z "$TOTAL" ] && TOTAL=0

DPASSE=""; BASE=0
if [ -f "$SETAT" ]; then
  DPASSE="$(sed -n 's/^derniere-passe=//p' "$SETAT" | head -n1)"
  BASE="$(sed -n 's/^sessions-a-la-derniere-passe=//p' "$SETAT" | head -n1)"
fi
[ -z "$BASE" ] && BASE=0
DEPUIS=$(( TOTAL - BASE )); [ "$DEPUIS" -lt 0 ] && DEPUIS=0

JOURS=999
if [ -n "$DPASSE" ]; then
  TN="$(date +%s)"
  TP="$(date -j -f "%Y-%m-%d" "$DPASSE" +%s 2>/dev/null || date -d "$DPASSE" +%s 2>/dev/null)"
  [ -n "$TP" ] && JOURS=$(( (TN - TP) / 86400 ))
fi

NUDGE=0
if [ ! -f "$SETAT" ]; then
  # Jamais de passe encore : on attend un minimum d'usage réel avant de proposer.
  [ "$TOTAL" -ge 5 ] && NUDGE=1
else
  { [ "$JOURS" -ge 7 ] || [ "$DEPUIS" -ge 10 ]; } && NUDGE=1
fi

if [ "$NUDGE" = "1" ]; then
  # Throttle : au plus une proposition par jour, même sur plusieurs sessions.
  NMARK="$ASSIST_DIR/dernier-nudge.txt"
  LASTN=""; [ -f "$NMARK" ] && LASTN="$(head -n1 "$NMARK")"
  if [ "$LASTN" != "$TODAY" ]; then
    printf '%s\n' "$TODAY" > "$NMARK" 2>/dev/null
    echo ""
    echo "--- PROPOSITION D'AMÉLIORATION (à formuler à l'utilisatrice, gentiment, UNE fois) ---"
    echo "Ça fait un moment qu'on avance ensemble. Propose-lui EN UNE PHRASE simple, sans jargon,"
    echo "de faire ton « point pour progresser » (tu relis tout ce que vous avez fait et tu deviens"
    echo "plus malin), par ex. : « Dis, ça fait un moment — je peux prendre 2 minutes pour devenir"
    echo "un peu plus malin avec tout ce qu'on a fait ? ». Si elle accepte, lance le skill /progres."
    echo "Si elle décline ou est occupée, n'insiste pas : ne le repropose pas aujourd'hui."
  fi
fi

echo ""
echo "=== FIN MÉMOIRE ==="
exit 0
