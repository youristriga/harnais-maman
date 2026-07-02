---
name: journee
description: Raconter sa journée ou vider sa tête - tout est trié et noté au bon endroit (journal du jour, tâches, projets). Déclencheur - /journee [texte libre], ou spontanément quand l'utilisatrice raconte sa journée.
---

# /journee — Vider sa tête

L'utilisatrice raconte librement (événements, idées, choses à faire, rendez-vous, avancées de projets, tout mélangé). Ton travail : trier et ranger, sans lui demander de structurer.

## Démarche

1. Lis la note du jour `quotidien/AAAA-MM-JJ.md` si elle existe (le hook l'a peut-être déjà injectée). Sinon crée-la au format du CLAUDE.md.
2. Trie ce qu'elle raconte :
   - Faits, événements, décisions → `## Ce qui s'est passé` (horodaté `HH:MM —` ; obtiens l'heure via `date +"%H:%M"`, ne la devine jamais)
   - Choses à faire → `## À faire` (cases à cocher, échéance si mentionnée)
   - Avancée ou mention d'un projet → mets AUSSI à jour la fiche projet + `projets/_index.md`
   - Tâche professionnelle → AUSSI dans `pro/taches.md`
   - Rendez-vous futur → note-le dans « À faire » avec la date, et rappelle-le le jour venu (le hook réinjecte le journal)
3. Réponds en 2-3 phrases : ce que tu as retenu d'important, et une question SEULEMENT si un point est ambigu et que ça compte.

Ne récite pas la liste de tout ce que tu as écrit. Dis simplement « C'est noté » + le ou les points saillants (échéance proche, conflit d'agenda, chose oubliée depuis plusieurs jours).
