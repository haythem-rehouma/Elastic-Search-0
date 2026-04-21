<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Projet ch13 — CRUD pédagogique dans Kibana Dev Tools

Stack ES + Kibana standalone. Les exercices se font **dans la Console Kibana** (pas en CLI).

## Démarrage

```bash
docker compose up -d
```

Ouvrez **Kibana → Dev Tools → Console** : http://localhost:5601/app/dev_tools#/console

## Snippets prêts à coller

| Fichier                                              | Contenu                                                |
| ---------------------------------------------------- | ------------------------------------------------------ |
| [`console/01-liste-cours.txt`](./console/01-liste-cours.txt) | Session pédagogique complète : POST/PUT/`_create`, update, delete, pièges PUT _doc |
| [`console/02-bibliotheque-exercices.txt`](./console/02-bibliotheque-exercices.txt) | Solution des 6 exercices d'auto-évaluation |
| [`console/03-update-vs-replace.txt`](./console/03-update-vs-replace.txt) | Démo update partiel vs remplacement vs script Painless |

## Mode d'emploi

1. Ouvrir un fichier `console/*.txt`
2. Copier tout le contenu
3. Coller dans la Console Kibana
4. Placer le curseur sur **une** requête → `Ctrl + Entrée` (ou triangle ▶)
5. Lire le résultat à droite, comparer aux commentaires `# →`

## Cleanup

```bash
docker compose down -v
```

## Documentation détaillée

[`../pratique-07-solutions-crud-pedagogique.md`](../pratique-07-solutions-crud-pedagogique.md)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
