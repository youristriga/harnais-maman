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

echo ""
echo "=== FIN MÉMOIRE ==="
exit 0
