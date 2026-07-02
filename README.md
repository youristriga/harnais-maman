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

Commandes optionnelles : `/journee`, `/projet`, `/rangement`, `/cloture`, `/aide`.

## Maintenance à distance (côté admin)

- Modifier le plugin ici, committer, pousser.
- Sur sa machine : `claude plugin update memoire-vive` (ou le faire pour elle à distance).
- Les données restent chez elle (`~/Documents/Ma Mémoire`) : une mise à jour du plugin ne touche jamais sa mémoire. Pour sauvegarder ses données : Time Machine ou copie du dossier.
- Le CLAUDE.md de SON dossier est créé une fois par `/demarrage` ; pour livrer des évolutions de comportement, passer par les skills/hook (mis à jour avec le plugin) plutôt que par ce CLAUDE.md.
