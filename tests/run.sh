#!/bin/bash
# memoire-vive — banc de test end-to-end de la boucle d'intelligence.
# Fabrique un faux HOME + un faux espace mémoire cassé exprès + de fausses
# conversations, fait tourner tout le pipeline déterministe, et vérifie les
# résultats. Sort 0 si tout est vert, 1 sinon. Aucune dépendance externe.
#
# Usage : bash tests/run.sh

set -u
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PLUGIN_ROOT/skills/progres/lib"
HOOK="$PLUGIN_ROOT/hooks/session-start.sh"

PASS=0; FAIL=0
ok(){ echo "  ✓ $1"; PASS=$((PASS+1)); }
ko(){ echo "  ✗ $1"; FAIL=$((FAIL+1)); }
check(){ if eval "$2"; then ok "$1"; else ko "$1  [condition: $2]"; fi; }

SANDBOX="$(mktemp -d 2>/dev/null || mktemp -d -t mvtests)"
trap 'rm -rf "$SANDBOX"' EXIT
FAKEHOME="$SANDBOX/home"
VAULT="$FAKEHOME/Documents/Ma Mémoire"
mkdir -p "$FAKEHOME"
export HOME="$FAKEHOME"   # isole tout dans le bac à sable

echo "== Bac à sable : $SANDBOX"

# ---------------------------------------------------------------------------
# FIXTURE : un espace mémoire volontairement cassé et incomplet
# ---------------------------------------------------------------------------
mkdir -p "$VAULT/quotidien" "$VAULT/projets" "$VAULT/moi"
# CLAUDE.md présent mais profil absent ; regles/ absent ; pro/ absent ;
# memoire/ absent ; boite-de-reception absent ; _index absent ; taches absent.
cat > "$VAULT/CLAUDE.md" <<'EOF'
# Assistant — second cerveau
Cerveau présent.
EOF
# une note égarée à la racine (doit être proposée au rangement)
echo "# note perdue" > "$VAULT/note-en-vrac.md"
# un projet sans entrée dans l'index (index sera recréé vide -> proposé)
echo "# Cuisine" > "$VAULT/projets/cuisine.md"
# un placeholder oublié (doit être signalé en ALERTE)
echo "Bonjour {{PRENOM}}" > "$VAULT/moi/profil.md"
# le pointeur de config
printf '%s\n' "$VAULT" > "$FAKEHOME/.memoire-vive"

# ===========================================================================
echo ""
echo "== TEST 1 : sante.sh répare le sûr, propose le reste, n'invente pas"
OUT="$(bash "$LIB/sante.sh" "$VAULT")"
check "dossier regles recréé"            'echo "$OUT" | grep -q "REPARE:.*regles"'
check "carnet reproches recréé"          'test -s "$VAULT/regles/reproches.md"'
check "carnet preferences recréé"        'test -s "$VAULT/regles/preferences.md"'
check "carnet signaux recréé"            'test -s "$VAULT/regles/signaux.md"'
check "index projets recréé"             'test -s "$VAULT/projets/_index.md"'
check "taches pro recréées"              'test -s "$VAULT/pro/taches.md"'
check "dossier boite-de-reception créé"  'test -d "$VAULT/boite-de-reception"'
check "dossier memoire/recherche créé"   'test -d "$VAULT/memoire/recherche"'
check "dossier moi/assistant créé"       'test -d "$VAULT/moi/assistant"'
check "note égarée PROPOSÉE (pas déplacée)" 'echo "$OUT" | grep -q "PROPOSE:.*note-en-vrac"'
check "note égarée toujours à sa place"  'test -f "$VAULT/note-en-vrac.md"'
check "projet hors index PROPOSÉ"        'echo "$OUT" | grep -qi "PROPOSE:.*cuisine"'
check "placeholder SIGNALÉ en alerte"    'echo "$OUT" | grep -q "ALERTE:.*{{"'
check "rien n a été supprimé (projet cuisine intact)" 'test -f "$VAULT/projets/cuisine.md"'

echo ""
echo "== TEST 2 : après réparation, --check dit structure saine (exit 0)"
bash "$LIB/sante.sh" --check "$VAULT" >/dev/null 2>&1
check "sante --check sort 0 après réparation" '[ $? -eq 0 ]'
OUT2="$(bash "$LIB/sante.sh" --check "$VAULT")"
check "resume annonce structure=saine" 'echo "$OUT2" | grep -q "structure=saine"'

echo ""
echo "== TEST 3 : idempotence — 2e réparation ne recrée rien"
OUT3="$(bash "$LIB/sante.sh" "$VAULT")"
check "2e passe : 0 réparation"        'echo "$OUT3" | grep -q "reparations=0"'

echo ""
echo "== TEST 4 : --check échoue (exit 1) sur un espace cassé"
BROKE="$SANDBOX/broke"; mkdir -p "$BROKE/quotidien"
echo "# x" > "$BROKE/CLAUDE.md"
bash "$LIB/sante.sh" --check "$BROKE" >/dev/null 2>&1
check "sante --check sort 1 si structure cassée" '[ $? -eq 1 ]'

echo ""
echo "== TEST 5 : contexte.sh — première passe, fenêtre à 60j, transcripts localisés"
# fabrique de fausses conversations pour ce vault
ENC="$(printf '%s' "$VAULT" | sed 's/[^A-Za-z0-9]/-/g')"
TDIR="$FAKEHOME/.claude/projects/$ENC"
mkdir -p "$TDIR"
printf '{"role":"user","content":"le chemin %s"}\n' "$VAULT" > "$TDIR/s1.jsonl"
printf '{"role":"user","content":"non pas comme ça, je préfère autrement"}\n' > "$TDIR/s2.jsonl"
CTX="$(bash "$LIB/contexte.sh" "$VAULT")"
check "contexte trouve le VAULT"           'echo "$CTX" | grep -q "^VAULT=$VAULT$"'
check "première passe détectée"            'echo "$CTX" | grep -q "PREMIERE_PASSE=oui"'
check "dernière passe = jamais"            'echo "$CTX" | grep -q "DERNIERE_PASSE=jamais"'
check "conversations localisées"           'echo "$CTX" | grep -q "TRANSCRIPTS_DIR=$TDIR"'
check "confiance haute (chemin référencé)" 'echo "$CTX" | grep -q "TRANSCRIPTS_CONFIANCE=haute"'

echo ""
echo "== TEST 6 : cloturer.sh — écrit l'état + le journal de bord"
# simule 3 sessions journalisées
printf '2026-07-10 09:00\n2026-07-11 09:00\n2026-07-12 09:00\n' > "$VAULT/moi/assistant/sessions.log"
bash "$LIB/cloturer.sh" "$VAULT" "test : 2 réparations, 1 règle" >/dev/null
check "carnet d'état écrit"                'test -s "$VAULT/moi/assistant/etat-intelligence.txt"'
check "état mémorise 3 sessions"           'grep -q "sessions-a-la-derniere-passe=3" "$VAULT/moi/assistant/etat-intelligence.txt"'
check "état mémorise la date du jour"      'grep -q "derniere-passe=$(date +%F)" "$VAULT/moi/assistant/etat-intelligence.txt"'
check "journal de bord créé"               'test -s "$VAULT/moi/assistant/journal-de-bord.md"'
check "journal contient le résumé"         'grep -q "1 règle" "$VAULT/moi/assistant/journal-de-bord.md"'

echo ""
echo "== TEST 7 : contexte.sh après une passe — incrémental (depuis la dernière passe)"
CTX2="$(bash "$LIB/contexte.sh" "$VAULT")"
check "n'est plus une première passe"      'echo "$CTX2" | grep -q "PREMIERE_PASSE=non"'
check "fenêtre = date de la dernière passe" 'echo "$CTX2" | grep -q "FENETRE_DEPUIS=$(date +%F)"'
check "sessions depuis la passe = 0"        'echo "$CTX2" | grep -q "SESSIONS_DEPUIS=0"'

echo ""
echo "== TEST 8 : le hook injecte les signaux + journalise + NE propose pas trop tôt"
echo "- rappel test important" >> "$VAULT/regles/signaux.md"
# repart d'un état neuf pour le minutage de la proposition
rm -f "$VAULT/moi/assistant/etat-intelligence.txt" "$VAULT/moi/assistant/sessions.log" "$VAULT/moi/assistant/dernier-nudge.txt"
H1="$(bash "$HOOK")"
check "hook injecte la section signaux"      'echo "$H1" | grep -q "Rappels & signaux appris"'
check "hook journalise la session"           'test -s "$VAULT/moi/assistant/sessions.log"'
check "pas de proposition avant 5 sessions"  '! echo "$H1" | grep -q "PROPOSITION D.AMÉLIORATION"'

echo ""
echo "== TEST 9 : le hook PROPOSE au seuil (5e session), une seule fois par jour"
# TEST 8 a logué la session 1. On ajoute 3 sessions (2,3,4) : encore aucun seuil.
bash "$HOOK" >/dev/null; bash "$HOOK" >/dev/null; bash "$HOOK" >/dev/null
H5="$(bash "$HOOK")"                       # session 5 -> seuil atteint -> proposition
check "proposition affichée au seuil (5e session)" 'echo "$H5" | grep -q "PROPOSITION D.AMÉLIORATION"'
H6="$(bash "$HOOK")"                       # même jour -> throttle
check "pas de 2e proposition le même jour"   '! echo "$H6" | grep -q "PROPOSITION D.AMÉLIORATION"'

echo ""
echo "== TEST 10 : après une passe, le hook ne propose plus (compteur remis à zéro)"
bash "$LIB/cloturer.sh" "$VAULT" "passe" >/dev/null
rm -f "$VAULT/moi/assistant/dernier-nudge.txt"
H7="$(bash "$HOOK")"
check "plus de proposition juste après une passe" '! echo "$H7" | grep -q "PROPOSITION D.AMÉLIORATION"'

echo ""
echo "== TEST 11 : rétro-compatibilité — hook silencieux si config absente"
rm -f "$FAKEHOME/.memoire-vive"
H8="$(bash "$HOOK")"
check "message d'onboarding si pas de config" 'echo "$H8" | grep -q "memoire-vive"'
check "pas d'erreur bloquante"                '[ $? -eq 0 ]'

# ===========================================================================
echo ""
echo "==================================================="
echo "  RÉSULTAT : $PASS réussis, $FAIL échoués"
echo "==================================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
