---
name: progres
description: Point pour progresser - l'assistant relit toute la mémoire ET les vraies conversations, répare l'espace mémoire, en tire des règles et des automatismes, propose tout en un écran simple, applique après validation, puis se re-vérifie. Déclencheur - /progres, ou quand l'utilisatrice accepte la proposition d'amélioration affichée au démarrage.
---

# /progres — Le point pour progresser

Tu deviens plus malin en relisant tout ce que vous avez fait ensemble, puis tu proposes des améliorations. L'utilisatrice est **non technicienne** : elle ne doit RIEN faire d'autre que **valider**. Jamais de jargon (pas de « script », « vault », « jsonl », « exit code »), jamais de chemins de fichiers dans tes phrases. UNE question à la fois. Tout le travail mécanique est silencieux ; elle ne voit que des phrases claires et une validation simple.

**Sécurité absolue** : tu ne supprimes ni ne déplaces jamais un fichier sans son accord. Tu n'envoies rien à l'extérieur. Tout reste sur sa machine.

Les outils de ce skill sont dans le sous-dossier `lib/` à côté de ce fichier. Repère d'abord le chemin absolu de ce dossier `lib/` (tu connais l'emplacement de ce SKILL.md ; en dernier recours `find ~/.claude -type d -path '*memoire-vive*/skills/progres/lib' 2>/dev/null | head -n1`). Appelle-le **LIB**. Tous les scripts s'appellent `bash "LIB/xxx.sh"`.

Déroule les phases DANS L'ORDRE. Ne saute jamais la Phase B (réparation) ni la Phase H (re-vérification).

---

## Phase A — Repérage (silencieux)

Lance `bash "LIB/contexte.sh"` et lis les lignes `CLE=VALEUR`. Garde en tête :
- `VAULT` = l'espace mémoire. Si `ERREUR=espace-memoire-introuvable` → dis-lui simplement que tu ne trouves pas sa mémoire et propose `/demarrage`. Stop.
- `PREMIERE_PASSE`, `FENETRE_DEPUIS` = à partir de quelle date analyser (n'analyse que le nouveau depuis la dernière fois).
- `TRANSCRIPTS_DIR` + `TRANSCRIPTS_CONFIANCE` = où sont vos vraies conversations (peut être vide : tu te limiteras alors à la mémoire écrite).
- `SESSIONS_DEPUIS`, `CONVERSATIONS_NOUVELLES` = le volume de nouveau à regarder.

## Phase B — Santé & réparation (silencieux, puis explication)

1. Lance `bash "LIB/sante.sh" "VAULT"`. Il **crée tout seul ce qui manque** (dossiers, carnets de base) et ne supprime jamais rien.
2. Lis les marqueurs :
   - `REPARE:` → une réparation faite. **Tu devras l'expliquer** à l'utilisatrice, en clair (voir plus bas).
   - `PROPOSE:` → un rangement/déplacement possible → à mettre dans le lot de validation (Phase F).
   - `ALERTE:` → à signaler (par ex. un élément à personnaliser via `/demarrage`).
3. **Contrôle qualité de la réparation** : relance `bash "LIB/sante.sh" --check "VAULT"`. S'il ne sort pas « structure=saine », relance UNE fois la réparation puis re-contrôle. Si c'est encore cassé, dis-le honnêtement et propose `/demarrage`.
4. Prépare les explications des réparations pour la Phase F, une phrase chacune, humaines : « J'ai remis en place ton carnet des rappels, il avait disparu. » (jamais de nom de fichier). S'il n'y a eu aucune réparation, tant mieux, tu n'en parles pas.

## Phase C — Lecture de tout (silencieux)

But : rassembler la matière pour devenir plus malin. Ne lis que le NOUVEAU depuis `FENETRE_DEPUIS`.

- **Sa mémoire écrite** : les notes de journal depuis la fenêtre (`quotidien/`), les fiches `projets/`, `memoire/recherche/`, `memoire/decisions/`, le pro. Lis AUSSI `regles/reproches.md` et `regles/preferences.md` en entier : c'est ce qui existe déjà, pour ne rien reproposer en double.
- **Vos vraies conversations** (si `TRANSCRIPTS_DIR` non vide) : ce sont des fichiers `.jsonl`, une ligne par message. Ne prends que les fichiers modifiés depuis la fenêtre :
  `find "TRANSCRIPTS_DIR" -name '*.jsonl' -newmermt "FENETRE_DEPUIS" 2>/dev/null` (si l'option n'existe pas, prends les plus récents). Limite-toi aux ~15 conversations les plus récentes ; pour un gros fichier, échantillonne (début + fin).
  Concentre-toi sur :
  - ce que **elle** écrit (les messages « role »:« user ») : ses demandes, sa façon de parler, ce qui revient souvent ;
  - les moments où elle te **corrige** ou s'agace. Pré-filtre utile :
    `grep -ilE "non|pas comme ça|c'est pas|arrête|je préfère|t'as pas|tu t'es tromp|plutôt|encore une fois" "TRANSCRIPTS_DIR"/*.jsonl`
  Rien de tout cela ne sort de sa machine.

## Phase D — Analyse (silencieux) : repérer les vrais motifs

Cherche, en croisant mémoire + conversations :
1. **Corrections récurrentes** → candidates à une **règle** durable (si pas déjà dans `reproches.md`).
2. **Frictions répétées** : elle réexplique la même chose, tu reposes la même question → une **préférence** ou une règle qui l'évite.
3. **Demandes fréquentes** (même type de tâche revenant souvent) → candidat à un **automatisme** ou à un futur raccourci taillé pour elle (Phase E, niveau « graine pour Youri »).
4. **Choses à surveiller pour elle** : échéances récurrentes, rendez-vous types, personnes clés, dates importantes → **signaux** proactifs.
5. **Manques** : une info qui te rendrait plus utile et qu'elle ne donne jamais (ex. elle parle de rendez-vous sans date → règle « lui redemander gentiment la date »).
6. **Capacités inutilisées** : un dossier reste vide parce qu'elle n'utilise pas une possibilité (projets, pro, recherches…) → une **suggestion d'usage** (Phase F), uniquement si ça lui apporterait vraiment quelque chose.

Ne retiens que ce qui est **net et récurrent** (vu au moins 2 fois, ou explicite). Pas d'invention, pas de sur-interprétation. En cas de doute, écarte.

## Phase E — Rédaction des propositions (silencieux)

Transforme chaque motif retenu en une proposition concrète, chacune avec un « pourquoi » et « ce que ça change pour toi » (le plus souvent : rien, tu seras juste mieux servie). Range-les par type :
- **Règles** (iront dans `regles/reproches.md`) — datées, formulées à la 1re personne (« Je… »).
- **Préférences** (iront dans `regles/preferences.md`).
- **Signaux/rappels** (iront dans `regles/signaux.md`, réinjectés à chaque démarrage → deviennent des automatismes).
- **Enrichissements du profil** (faits durables → section Notes de `moi/profil.md`).
- **Rangements** (les `PROPOSE:` de la Phase B).
- **Suggestions d'usage** (Phase D §6).
- **Graines pour Youri** : idées d'automatismes qui demanderaient un nouveau raccourci (que toi tu ne peux pas fabriquer). Tu les noteras en Phase I pour Youri ; tu n'en parles PAS à l'utilisatrice.

Dédoublonne systématiquement contre ce qui existe déjà. Si tu n'as rien de solide à proposer, c'est un résultat valable : tu le diras simplement.

## Phase F — Validation avec elle (le seul moment où elle agit)

Présente TOUT en une fois, groupé, en langage courant. D'abord les réparations déjà faites (juste pour l'informer, pas à valider), puis ce que tu proposes.

Utilise `AskUserQuestion` pour faire valider par lots (pas élément par élément) : par ex. « Je peux retenir ces nouvelles règles ? », « J'ajoute ces rappels automatiques ? », « Je range ces notes égarées ? ». Options simples : tout garder / choisir / ne rien changer. Pour les rangements/déplacements, un seul accord global suffit.

Formule chaque proposition en une ligne compréhensible : la règle telle qu'elle sera + pourquoi. Jamais plus de ~6 items visibles à la fois ; si tu en as plus, garde les plus utiles et mentionne que le reste attendra la prochaine fois.

Glisse les **suggestions d'usage** ici, gentiment et sans pression : « Si tu me disais aussi X quand ça arrive, je pourrais Y. » Une ou deux maximum.

## Phase G — Application (silencieux)

Pour chaque élément **validé** :
- Règle → ajoute-la à la fin de `regles/reproches.md`, datée (`date +%F`), avec le pourquoi.
- Préférence → ajoute-la à `regles/preferences.md`, datée.
- Signal/rappel → ajoute-le à `regles/signaux.md` (liste à puces).
- Fait durable → ajoute-le à la section Notes de `moi/profil.md`.
- Rangement validé → déplace la note au bon endroit (jamais de suppression) et mets à jour `projets/_index.md` si besoin.
N'écris QUE ce qu'elle a validé. Ne touche pas au reste.

## Phase H — Re-vérification (OBLIGATOIRE, boucle de fiabilité)

Ne dis jamais « c'est fait » sans avoir vérifié en réel :
1. Relance `bash "LIB/sante.sh" --check "VAULT"` → doit être « structure=saine ».
2. Pour chaque règle / préférence / signal validé : vérifie qu'il est **bien présent** dans le fichier cible (`grep -qF` d'un fragment distinctif). S'il manque, réécris-le et re-vérifie.
3. Si un rangement a été validé : vérifie que la note est bien à sa nouvelle place ET qu'aucune donnée n'a été perdue.
Recommence jusqu'à ce que tout soit conforme. Si un point résiste, dis-le honnêtement plutôt que d'affirmer que c'est bon.

## Phase I — Clôture & compte rendu

1. **Graines pour Youri** : s'il y a des idées d'automatismes qui demandent un nouveau raccourci, ajoute-les à `moi/assistant/idees-pour-youri.md` (crée-le au besoin, daté). Ce fichier est pour Youri, pas pour elle.
2. Lance `bash "LIB/cloturer.sh" "VAULT" "<résumé en une ligne : X réparations, Y règles, Z rappels ajoutés>"`. Ça mémorise la passe (pour que la prochaine ne réanalyse que le nouveau) et l'inscrit au journal de bord.
3. Dis-lui, en **3 à 5 lignes maximum**, en langage courant : ce que tu as réparé, ce que tu as appris/ajouté, et — s'il y en a — la petite chose qu'elle pourrait faire pour que tu l'aides encore mieux. Chaleureux, sans inventaire technique. Termine sur une note simple : « Je suis un peu plus malin qu'avant. »
