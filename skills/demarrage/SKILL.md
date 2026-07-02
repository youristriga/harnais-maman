---
name: demarrage
description: Installation guidée du second cerveau (onboarding). Crée l'espace mémoire Obsidian, le profil, le raccourci sur le Bureau. À lancer une seule fois, ou pour réparer une installation. Déclencheur - /demarrage, ou toute première utilisation détectée par le hook.
---

# /demarrage — Installation guidée du second cerveau

Tu accompagnes une personne **non technicienne** dans la création de son espace mémoire. Ton absolu : chaleureux, simple, UNE question à la fois, jamais de jargon (pas de « vault », « hook », « markdown », « chemin » — dis « dossier mémoire », « note », « raccourci »).

Le dossier du plugin (templates) est : `${CLAUDE_PLUGIN_ROOT}` — en pratique, retrouve-le via le chemin de ce SKILL.md (les templates sont dans `../../templates/` relatif à ce fichier).

## Étape 0 — Vérifier l'existant

Regarde si `~/.memoire-vive` existe déjà.
- S'il existe et que le dossier pointé existe : dis que l'espace mémoire est déjà installé, propose soit de tout garder (fin), soit de vérifier/réparer (passe les étapes en ne recréant que ce qui manque, SANS écraser les fichiers existants).
- Sinon : continue.

## Étape 1 — Accueil

Présente-toi en 3 phrases maximum : tu vas créer son espace mémoire personnel, ça prend 5 minutes, il suffit de répondre à quelques questions simples.

## Étape 2 — Interview (une question à la fois)

Pose ces questions UNE PAR UNE, en attendant chaque réponse (utilise AskUserQuestion quand des options s'y prêtent) :

1. **Prénom** : « Comment dois-je t'appeler ? »
2. **Nom de l'assistant** : propose 3 options (par exemple CLARA, LÉON, JADE) + choix libre.
3. **Ton** : tutoiement ou vouvoiement ?
4. **Activité pro** : « Est-ce que tu travailles ? Si oui, qu'est-ce que tu fais ? » (réponse libre ; si pas d'activité pro, le dossier pro existera quand même mais restera discret)
5. **Projets en cours** : « Quels sont les projets ou sujets qui t'occupent en ce moment ? Dis-les comme ça vient. » (liste libre, 0 à N projets)
6. **Emplacement** : propose par défaut `~/Documents/Ma Mémoire` (dis « dans ton dossier Documents, sous le nom Ma Mémoire »). Accepte un autre nom si elle préfère.

## Étape 3 — Création (silencieuse, en une passe)

1. Créer l'arborescence :
   ```
   <DOSSIER>/
     quotidien/  projets/  regles/  moi/
     pro/clients/  pro/factures/
     memoire/decisions/  memoire/recherche/
     boite-de-reception/
   ```
2. Copier `templates/CLAUDE-vault.md` → `<DOSSIER>/CLAUDE.md` en remplaçant les placeholders :
   - `{{PRENOM}}`, `{{ASSISTANT}}`
   - `{{TON_PHRASE}}` : « Tu la tutoies. » ou « Tu la vouvoies. » (adapte le CLAUDE.md entier au ton choisi si vouvoiement)
3. Copier `templates/profil.md` → `<DOSSIER>/moi/profil.md` en remplissant avec les réponses de l'interview (`{{TON}}`, `{{ACTIVITE_PRO}}`, `{{PRIORITES}}` d'après ce qu'elle a dit).
4. Créer `<DOSSIER>/regles/reproches.md` avec pour seul contenu :
   ```markdown
   # Règles apprises

   (Chaque fois que {{PRENOM}} me corrige, j'écris ici la règle, datée, avec le pourquoi. Je les respecte toutes, toujours.)
   ```
   et `<DOSSIER>/regles/preferences.md` sur le même modèle (goûts, habitudes).
5. Créer une fiche par projet cité (format fiche projet du CLAUDE.md) + `projets/_index.md` :
   ```markdown
   # Projets en cours

   | Projet | État | Prochaine étape | Dernière activité |
   |---|---|---|---|
   ```
6. Créer `pro/taches.md` (`# Tâches pro` + liste à cocher vide).
7. Créer la note du jour `quotidien/AAAA-MM-JJ.md` avec une première ligne : « Installation de l'espace mémoire. »
8. Écrire le fichier de configuration : `echo "<DOSSIER en chemin absolu>" > ~/.memoire-vive`
9. Créer le raccourci Bureau `~/Desktop/Mon Assistant.command` :
   ```bash
   #!/bin/bash
   cd "<DOSSIER>" && claude
   ```
   puis `chmod +x`. (Sur Linux : créer un fichier .desktop équivalent.)

## Étape 4 — Vérification réelle

- Relis `~/.memoire-vive` et vérifie que le dossier et le CLAUDE.md existent.
- Lance le script `hooks/session-start.sh` du plugin à la main (Bash) et vérifie qu'il sort bien le profil. Si erreur, corrige avant de continuer.

## Étape 5 — Mode d'emploi (5 lignes maximum)

Explique simplement :
1. « Pour me parler : double-clique sur **Mon Assistant** sur ton Bureau. »
2. « Raconte-moi ta journée, tes idées, tes rendez-vous : je note tout, tu n'as rien à ranger. »
3. « Si je fais quelque chose qui te déplaît, dis-le-moi : je m'en souviendrai pour toujours. »
4. « Pour finir, dis simplement au revoir : je mets tout en ordre. »
5. (Si Obsidian est installé : mentionne qu'elle peut ouvrir le dossier « Ma Mémoire » dans Obsidian pour feuilleter ses notes, c'est optionnel.)

Termine en demandant de fermer cette fenêtre et de relancer via l'icône du Bureau, pour que la mémoire s'active.
