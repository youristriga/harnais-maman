---
name: demarrage
description: Installation guidée du second cerveau (onboarding fiable et vérifié). Crée l'espace mémoire, le profil calibré sur ses usages, le raccourci de lancement adapté (CLI ou app Desktop). À lancer une seule fois, ou pour réparer. Déclencheur - /demarrage, ou toute première utilisation détectée par le hook.
---

# /demarrage — Installation guidée du second cerveau

Tu accompagnes une personne **non technicienne**. Ton absolu : chaleureux, simple, UNE question à la fois, jamais de jargon (pas de « vault », « hook », « markdown », « chemin », « CLI » — dis « dossier mémoire », « note », « raccourci », « application »).

Les templates du plugin sont dans `../../templates/` relatif à ce SKILL.md (résous le chemin absolu du dossier du plugin dès le début et garde-le sous la main).

Déroule les phases DANS L'ORDRE. Ne saute jamais la Phase D (vérification) ni la Phase E (test réel).

---

## Phase A — État des lieux (silencieuse)

Avant de poser la moindre question, vérifie dans un seul passage Bash :

1. `~/.memoire-vive` existe-t-il ? Si oui, le dossier pointé existe-t-il ? Contient-il un `CLAUDE.md` ?
2. La commande `claude` est-elle disponible dans le terminal ? (`command -v claude`) → détermine le type de raccourci en Phase C.
3. Note la date du jour (`date +%F`) et le chemin absolu du dossier de templates.

**Aiguillage :**
- Installation saine détectée → dis-le simplement, propose : tout garder (fin) / compléter ce qui manque (mode réparation : exécute les phases suivantes en ne créant QUE ce qui manque, sans JAMAIS écraser un fichier existant) / recommencer ailleurs (repars de zéro mais ne supprime rien de l'ancien dossier).
- Config présente mais dossier disparu → propose de le recréer au même endroit ou ailleurs.
- Rien → installation neuve, continue.

## Phase B — Interview (une question à la fois, dans cet ordre)

Attends chaque réponse avant la question suivante. Utilise AskUserQuestion quand il y a des options, sinon question libre. Reformule librement, mais couvre TOUS les points :

1. **Prénom** — « Comment dois-je t'appeler ? »
2. **Nom de l'assistant** — propose 3 prénoms (par exemple CLARA, LÉON, JADE) + choix libre.
3. **Ton** — tutoiement ou vouvoiement ?
4. **Activité professionnelle** — travaille-t-elle ? Quoi ? (Si pas d'activité pro : le dossier pro existera mais restera discret — ne plus jamais le mentionner.)
5. **Usages principaux** — « À quoi veux-tu que je te serve, surtout ? » avec options multi-choix : rédaction (mails, courriers), recherches d'informations, suivi administratif et démarches, organisation du quotidien, projets personnels, activité pro. Garde les réponses : elles calibrent le profil.
6. **Rappels** — « Est-ce que tu veux que je te rappelle spontanément tes rendez-vous et échéances quand on se parle, ou seulement quand tu me le demandes ? »
7. **Projets en cours** — « Quels projets ou sujets t'occupent en ce moment ? Dis-les comme ça vient. » (0 à N ; pour chacun, demande en une phrase où ça en est.)
8. **Emplacement** — propose par défaut « dans ton dossier Documents, sous le nom Ma Mémoire » (`~/Documents/Ma Mémoire`). Accepte un autre nom/endroit.

Récapitule ensuite en 4-5 lignes simples ce que tu as compris et demande « C'est bien ça ? » avant de créer quoi que ce soit.

## Phase C — Création (silencieuse, checklist exhaustive)

Crée EXACTEMENT ceci (en mode réparation : seulement ce qui manque). Utilise toujours des chemins absolus, entre guillemets (le nom du dossier contient un espace).

| # | Élément | Contenu |
|---|---|---|
| 1 | Arborescence | `quotidien/`, `projets/`, `regles/`, `moi/`, `pro/clients/`, `pro/factures/`, `memoire/decisions/`, `memoire/recherche/`, `boite-de-reception/` |
| 2 | `CLAUDE.md` | copie de `templates/CLAUDE-vault.md`, placeholders remplacés : `{{PRENOM}}`, `{{ASSISTANT}}`, `{{TON_PHRASE}}` (« Tu la tutoies. » / « Vous la vouvoyez. » — si vouvoiement, adapte TOUT le fichier au vouvoiement) |
| 3 | `moi/profil.md` | copie de `templates/profil.md` remplie avec TOUTES les réponses de l'interview : ton, activité pro, usages principaux (question 5), préférence de rappels (question 6) |
| 4 | `regles/reproches.md` | titre `# Règles apprises` + phrase d'explication (chaque correction devient une règle datée, respectée pour toujours) |
| 5 | `regles/preferences.md` | titre `# Préférences` + phrase d'explication (goûts, habitudes, façons de faire) ; si la question 6 a donné une préférence claire sur les rappels, écris-la ici, datée — c'est la première préférence apprise |
| 6 | Fiches projets | une par projet cité (format Objectif / État / Prochaines étapes / Historique du CLAUDE.md), État rempli avec ce qu'elle a dit |
| 7 | `projets/_index.md` | tableau `Projet / État / Prochaine étape / Dernière activité`, une ligne par projet créé |
| 8 | `pro/taches.md` | `# Tâches pro` + liste à cocher vide |
| 9 | `quotidien/AAAA-MM-JJ.md` | note du jour au format standard, première ligne : « HH:MM — Installation de l'espace mémoire. » |
| 10 | `~/.memoire-vive` | UNE ligne : le chemin absolu du dossier mémoire (rien d'autre) |
| 11 | Raccourci de lancement | selon la détection de Phase A, voir ci-dessous |

**Raccourci (11) — deux cas :**
- **`claude` disponible dans le terminal** → créer `~/Desktop/Mon Assistant.command` contenant `#!/bin/bash` puis `cd "<dossier mémoire>" && claude`, et `chmod +x`. (Linux : fichier `.desktop` équivalent.)
- **`claude` absent** (elle utilise l'application Claude Desktop) → NE PAS créer le fichier. À la place, tu expliqueras en Phase F : ouvrir l'application Claude → onglet **Code** → choisir le dossier « Ma Mémoire » (après la première fois, il apparaît dans les dossiers récents).

## Phase D — Vérification (OBLIGATOIRE, en réel)

Vérifie en Bash, point par point :

1. `~/.memoire-vive` contient bien le chemin absolu, et ce dossier existe.
2. Chacun des fichiers de la checklist C existe et n'est pas vide (`CLAUDE.md`, `moi/profil.md`, les 2 fichiers de `regles/`, `_index.md`, `pro/taches.md`, la note du jour).
3. Plus AUCUN placeholder `{{...}}` ne subsiste : `grep -r "{{" <dossier>` doit ne rien retourner.
4. Exécute le script `hooks/session-start.sh` du plugin et vérifie que sa sortie contient bien le profil et le prénom.
5. Si le raccourci Bureau a été créé : vérifie qu'il est exécutable.

**Si un point échoue : corrige et revérifie avant de continuer.** Ne jamais annoncer que l'installation est terminée si un point est en échec.

## Phase E — Test réel avec elle

Propose : « Pour vérifier que tout marche, raconte-moi une chose de ta journée, n'importe quoi. »

À sa réponse : enregistre-la dans la note du jour (format standard, horodatée via `date +"%H:%M"`), puis relis le fichier pour confirmer que c'est écrit. Dis-lui simplement : « C'est noté. Ta mémoire fonctionne. »

## Phase F — Mode d'emploi (6 lignes maximum, adapté au cas)

1. Comment me lancer : double-clic sur **Mon Assistant** (Bureau) OU application Claude → onglet Code → dossier « Ma Mémoire » (selon le cas de la Phase C).
2. « Raconte-moi ta journée, tes idées, tes rendez-vous : je note et je range tout, tu n'as rien à faire. »
3. « Demande-moi ce que tu veux : écrire un mail, chercher une info, faire le point sur un projet. »
4. « Si je fais quelque chose qui te déplaît, dis-le-moi : je m'en souviendrai pour toujours. »
5. « Pour finir, dis simplement au revoir : je mets tout en ordre pour demain. »
6. (Optionnel, seulement si pertinent : le dossier « Ma Mémoire » est lisible avec Obsidian pour feuilleter ses notes.)

Termine en demandant de fermer et relancer une fois (via le raccourci ou l'onglet Code), pour que la mémoire s'active dès le prochain démarrage.
