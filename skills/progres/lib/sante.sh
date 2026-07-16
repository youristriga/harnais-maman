#!/bin/bash
# memoire-vive — audit de santé & réparation de l'espace mémoire.
# Déterministe, sans dépendance (bash + coreutils macOS/Linux).
#
# Usage :
#   sante.sh [VAULT]           -> répare ce qui est sûr, imprime un rapport lisible, sort 0
#   sante.sh --check [VAULT]   -> lecture seule ; sort 0 si la structure est saine, 1 sinon
#
# Ne supprime ni ne déplace JAMAIS rien. Il ne fait que CRÉER ce qui manque
# (dossiers + fichiers de base). Les déplacements/fusions sont seulement PROPOSÉS.
#
# Marqueurs de sortie (une info par ligne, pour l'humain ET pour le banc de test) :
#   OK: ...        déjà en ordre
#   REPARE: ...    action de réparation effectuée (création)
#   PROPOSE: ...   suggestion nécessitant l'accord de l'utilisatrice (déplacement, rangement)
#   ALERTE: ...    problème à signaler / à revoir humainement (placeholder, cerveau minimal)
#   === RESUME === reparations=N propositions=M alertes=K structure=saine|cassee

set -u

MODE="reparer"
if [ "${1:-}" = "--check" ]; then MODE="check"; shift; fi

VAULT="${1:-}"
if [ -z "$VAULT" ]; then
  CONFIG="$HOME/.memoire-vive"
  [ -f "$CONFIG" ] && VAULT="$(head -n1 "$CONFIG")"
fi
if [ -z "$VAULT" ] || [ ! -d "$VAULT" ]; then
  echo "ALERTE: espace mémoire introuvable (chemin « $VAULT »)"
  echo "=== RESUME === reparations=0 propositions=0 alertes=1 structure=cassee"
  exit 1
fi

REP=0; PRO=0; ALE=0; CORE_MISSING=0
canwrite(){ [ "$MODE" = "reparer" ]; }

# --- dossiers attendus -------------------------------------------------------
ensure_dir(){ # $1 = chemin relatif
  local d="$VAULT/$1"
  if [ -d "$d" ]; then return 0; fi
  CORE_MISSING=$((CORE_MISSING+1))
  if canwrite; then
    mkdir -p "$d" && { echo "REPARE: dossier « $1 » recréé (il avait disparu)"; REP=$((REP+1)); }
  else
    echo "PROPOSE: dossier « $1 » manquant"
  fi
}

# --- fichiers de base --------------------------------------------------------
ensure_file(){ # $1 = relatif, $2 = contenu si absent, $3 = libellé humain, $4 = "core"|"aux"
  local f="$VAULT/$1"
  if [ -s "$f" ]; then return 0; fi
  [ "${4:-core}" = "core" ] && CORE_MISSING=$((CORE_MISSING+1))
  if canwrite; then
    mkdir -p "$(dirname "$f")"
    printf '%s\n' "$2" > "$f" && { echo "REPARE: $3 (recréé, il manquait ou était vide)"; REP=$((REP+1)); }
  else
    echo "PROPOSE: $3 manquant ou vide"
  fi
}

# 1) Arborescence attendue
for d in quotidien projets regles moi "pro/clients" "pro/factures" \
         "memoire/decisions" "memoire/recherche" boite-de-reception "moi/assistant"; do
  ensure_dir "$d"
done

# 2) Fichiers de base (créables sans risque)
ensure_file "regles/reproches.md" \
"# Règles apprises

Chaque correction que tu me donnes devient ici une règle datée, que je respecte pour toujours." \
"le carnet des règles apprises" core

ensure_file "regles/preferences.md" \
"# Préférences

Tes goûts, tes habitudes, ta façon de faire — notés au fil du temps." \
"le carnet des préférences" core

ensure_file "regles/signaux.md" \
"# Rappels & signaux appris

Ce que j'ai appris à surveiller pour toi (échéances qui reviennent, choses à te redemander, points de vigilance). Mis à jour automatiquement, réinjecté à chaque démarrage." \
"le carnet des rappels appris" core

ensure_file "projets/_index.md" \
"# Projets

| Projet | État | Prochaine étape | Dernière activité |
|---|---|---|---|" \
"l'index des projets" core

ensure_file "pro/taches.md" \
"# Tâches pro
" \
"la liste des tâches pro" aux

# 3) Le cerveau (CLAUDE.md) et le profil : coeur du système.
#    S'ils manquent, on met un minimum vital pour que ça tourne, mais on ALERTE :
#    seule une relance de /demarrage les recalibre correctement.
if [ ! -s "$VAULT/CLAUDE.md" ]; then
  CORE_MISSING=$((CORE_MISSING+1))
  if canwrite; then
    printf '%s\n' \
"# Assistant — second cerveau

**Dossier mémoire** : ce dossier.
**Langue** : français simple, phrases courtes, zéro jargon.

Tu es l'assistant personnel de la personne. Tu retiens tout à sa place : journal du jour (quotidien/AAAA-MM-JJ.md), projets (projets/ + _index.md), règles apprises à la moindre correction (regles/reproches.md), préférences (regles/preferences.md). Tu écris au fil de l'eau, sans qu'on te le demande. Tu ne supprimes ni n'envoies rien à l'extérieur sans accord. Une question à la fois.

(Fichier minimal recréé automatiquement. Relance /demarrage pour le personnaliser.)" \
> "$VAULT/CLAUDE.md"
    echo "REPARE: le cerveau (CLAUDE.md) manquait — version minimale recréée"; REP=$((REP+1))
    echo "ALERTE: cerveau recréé en version générique — relancer /demarrage pour le personnaliser (prénom, ton, usages)"; ALE=$((ALE+1))
  else
    echo "PROPOSE: le cerveau (CLAUDE.md) est manquant"
  fi
fi

if [ ! -s "$VAULT/moi/profil.md" ]; then
  CORE_MISSING=$((CORE_MISSING+1))
  if canwrite; then
    mkdir -p "$VAULT/moi"
    printf '%s\n' \
"# Profil

- **Prénom** : (à compléter)
- **Ton souhaité** : (à compléter)
- **Usages principaux** : (à compléter)

## Notes
(Complété automatiquement au fil des conversations.)" \
> "$VAULT/moi/profil.md"
    echo "REPARE: le profil manquait — version minimale recréée"; REP=$((REP+1))
    echo "ALERTE: profil incomplet — relancer /demarrage pour le remplir"; ALE=$((ALE+1))
  else
    echo "PROPOSE: le profil est manquant"
  fi
fi

# --- Vérifications consultatives (n'affectent pas la santé structurelle) -----

# a) Placeholders {{...}} oubliés (installation bâclée)
PH=$(grep -rl '{{' "$VAULT" 2>/dev/null | grep -v '/\.' || true)
if [ -n "$PH" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    echo "ALERTE: des blancs à remplir « {{...}} » subsistent dans « ${f#$VAULT/} » (à personnaliser via /demarrage)"
    ALE=$((ALE+1))
  done <<< "$PH"
fi

# b) Notes égarées à la racine (hors CLAUDE.md / README)
for f in "$VAULT"/*.md; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  case "$b" in
    CLAUDE.md|README.md) ;;
    *) echo "PROPOSE: la note « $b » est à la racine — je peux la ranger au bon endroit"; PRO=$((PRO+1)) ;;
  esac
done

# c) Projets présents mais absents de l'index
if [ -f "$VAULT/projets/_index.md" ]; then
  for f in "$VAULT"/projets/*.md; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    [ "$b" = "_index.md" ] && continue
    stem="${b%.md}"
    if ! grep -qiF "$stem" "$VAULT/projets/_index.md" 2>/dev/null; then
      echo "PROPOSE: le projet « $stem » n'est pas dans l'index — je peux l'y ajouter"; PRO=$((PRO+1))
    fi
  done
fi

# --- Résumé ------------------------------------------------------------------
if [ "$CORE_MISSING" -eq 0 ]; then STRUCT="saine"; else STRUCT="cassee"; fi
[ "$REP" -eq 0 ] && [ "$PRO" -eq 0 ] && [ "$ALE" -eq 0 ] && echo "OK: espace mémoire en ordre, rien à réparer"
echo "=== RESUME === reparations=$REP propositions=$PRO alertes=$ALE structure=$STRUCT"

if [ "$MODE" = "check" ] && [ "$CORE_MISSING" -gt 0 ]; then exit 1; fi
exit 0
