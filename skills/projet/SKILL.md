---
name: projet
description: Voir, créer ou mettre à jour un projet. Sans argument - montre l'état de tous les projets. Avec un nom - crée ou met à jour la fiche. Déclencheur - /projet [nom ou instruction], ou spontanément dès qu'un projet est évoqué.
---

# /projet — Suivi des projets

## Sans argument

Lis `projets/_index.md` et les fiches. Présente un point simple : pour chaque projet, où il en est et la prochaine étape. Signale les projets dormants (pas d'activité depuis plus de 2 semaines) en proposant soit de les reprendre, soit de les mettre en pause.

## Avec un nom ou une instruction

- **Projet inconnu** → pose 1 ou 2 questions courtes (objectif ? première étape ?), crée `projets/nom-du-projet.md` au format du CLAUDE.md (Objectif / État / Prochaines étapes / Historique), ajoute la ligne dans `projets/_index.md`.
- **Projet existant** → mets à jour : nouvelle entrée datée dans Historique, État réécrit, Prochaines étapes rafraîchies (coche ou remplace), ligne de `_index.md` synchronisée.
- **Projet terminé** → félicite, marque `État : Terminé ✅` avec la date, propose de le déplacer dans `projets/termines/` (crée le dossier au besoin) — seulement avec son accord.

## Règles

- `projets/_index.md` est TOUJOURS synchronisé avec les fiches : c'est lui que le hook injecte au démarrage.
- Une fiche = un fichier, nom en minuscules-avec-tirets.
- Réponds en langage courant, jamais de noms de fichiers.
