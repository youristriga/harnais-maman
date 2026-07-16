# memoire-vive — second cerveau personnel

Plugin Claude Code qui transforme un dossier Obsidian en mémoire personnelle auto-gérée : journal quotidien, projets, règles apprises (corrections), préférences. Tout s'écrit tout seul ; l'utilisatrice parle, l'assistant range.

Conçu pour une personne **non technicienne** : onboarding guidé en 5 minutes, raccourci sur le Bureau, zéro dépendance (bash pur, pas de Python/Node).

## Architecture

```
Plugin (ce repo)                        Espace mémoire (créé par /demarrage)
├── hooks/session-start.sh   ────────▶  ~/Documents/Ma Mémoire/
│   (injecte l'état au boot :           ├── CLAUDE.md          ← cerveau : comportements auto
│    profil, règles, journal,           ├── moi/profil.md
│    projets, tâches pro)               ├── quotidien/AAAA-MM-JJ.md
├── skills/                             ├── projets/ (+ _index.md)
│   ├── demarrage   onboarding guidé    ├── regles/reproches.md + preferences.md
│   ├── journee     brain-dump trié     ├── pro/ (clients, factures, taches.md)
│   ├── projet      suivi projets       ├── memoire/ (decisions, recherche)
│   ├── cloture     fin de session      └── boite-de-reception/
│   ├── rangement   entretien hebdo
│   └── aide        mode d'emploi       ~/.memoire-vive  ← chemin du dossier (lu par le hook)
└── templates/                          ~/Desktop/Mon Assistant.command  ← lanceur double-clic
```

La « mémoire » repose sur 3 mécanismes :
1. **Injection au démarrage** : le hook SessionStart lit le dossier mémoire et injecte profil + règles + journal du jour (ou d'hier) + index projets. Chaque session part avec le contexte.
2. **Écriture automatique** : le CLAUDE.md du dossier ordonne à l'assistant d'enregistrer au fil de l'eau, sans qu'on demande (journal, projets, règles à la moindre correction).
3. **Clôture** : au revoir → synchronisation complète + « À suivre demain » réinjecté le lendemain.

## Installation (sur sa machine)

Prérequis : [Claude Code](https://claude.com/claude-code) installé et connecté.

```bash
claude plugin marketplace add youristriga/harnais-maman
claude plugin install memoire-vive@harnais-maman
```

Puis lancer `claude` et taper `/demarrage`. Tout le reste est guidé (prénom, nom de l'assistant, tutoiement, projets en cours, création du dossier et du raccourci Bureau).

En local (sans GitHub) :

```bash
claude plugin marketplace add /chemin/vers/harnais-maman
claude plugin install memoire-vive@harnais-maman
```

## Usage quotidien (côté utilisatrice)

1. Double-clic sur **Mon Assistant** (Bureau).
2. Parler normalement : journée, idées, rendez-vous, projets. Tout est noté et trié automatiquement.
3. Une correction (« ne fais plus ça », « je préfère que… ») devient une règle permanente.
4. Dire au revoir → tout est mis en ordre pour demain.

Commandes optionnelles : `/journee`, `/projet`, `/rangement`, `/progres`, `/cloture`, `/aide`.

## Boucle d'auto-amélioration (`/progres`)

De temps en temps (au bout de ~7 jours ou ~10 sessions), l'assistant **propose lui-même** de faire son « point pour progresser ». L'utilisatrice n'a qu'à dire oui ; elle ne fait ensuite que **valider**. La passe :

1. **Audite et répare** l'espace mémoire (dossiers/fichiers manquants recréés, notes égarées et projets hors index proposés au rangement) — puis se re-vérifie.
2. **Relit** la mémoire écrite **et** les vraies conversations (100 % local, jamais rien envoyé dehors), en incrémental (seulement le nouveau depuis la dernière passe).
3. **En tire** des règles, des préférences et des **rappels automatiques** (`regles/signaux.md`, réinjectés à chaque démarrage) + enrichit le profil.
4. **Fait valider** en un écran simple, **applique**, puis **re-vérifie** que tout est bien en place.

Deux niveaux d'effet :
- **Immédiat, sans réinstaller** : règles, préférences, rappels, profil → écrits dans son dossier, réinjectés par le hook dès la session suivante.
- **Nécessite une mise à jour du plugin** : les idées d'automatismes qui demandent un nouveau raccourci sont déposées dans `moi/assistant/idees-pour-youri.md` (côté admin).

La mécanique (audit, réparation, minutage, journal) vit dans des scripts bash déterministes `skills/progres/lib/*.sh`, couverts par un banc de test end-to-end : `bash tests/run.sh` (39 vérifications).

## Maintenance à distance (côté admin)

- Modifier le plugin ici, committer, pousser.
- Sur sa machine : `claude plugin update memoire-vive` (ou le faire pour elle à distance).
- Les données restent chez elle (`~/Documents/Ma Mémoire`) : une mise à jour du plugin ne touche jamais sa mémoire. Pour sauvegarder ses données : Time Machine ou copie du dossier.
- Le CLAUDE.md de SON dossier est créé une fois par `/demarrage` ; pour livrer des évolutions de comportement, passer par les skills/hook (mis à jour avec le plugin) plutôt que par ce CLAUDE.md.
