<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Pratique 1 — Installation de Neo4j (chap. 06)

> Projet runnable autonome pour la **Pratique 1** du cours.
> Référence : [chapitre 06 — Installation de Neo4j](../../../06-installation-neo4j.md)

## Objectif

Installer Neo4j 5.20 (Community) **dans Docker**, avec le plugin APOC, des volumes nommés persistants, et vérifier que tout fonctionne.

## Stack

| Service | Image                        | Port  | Rôle                 |
| ------- | ---------------------------- | :---: | -------------------- |
| Neo4j   | `neo4j:5.20-community`       | 7474  | HTTP / Browser       |
| Neo4j   | `neo4j:5.20-community`       | 7687  | Bolt (drivers)       |

Volumes nommés : `p01_neo4j_data`, `p01_neo4j_logs`, `p01_neo4j_plugins`.

## Démarrage rapide

```bash
docker compose up -d

bash scripts/verify.sh
```

Sur Windows PowerShell :

```powershell
docker compose up -d

.\scripts\verify.ps1
```

Puis ouvrir http://localhost:7474

- Identifiants : `neo4j` / `Neo4jStrongPass!`

## Ce que vérifie le script

1. Le conteneur `p01_neo4j` est démarré
2. Le port 7474 répond en HTTP
3. Le port 7687 (Bolt) est en écoute
4. APOC est correctement chargé (`RETURN apoc.version()`)
5. Une écriture/lecture de test passe

## Nettoyage

```bash
docker compose down -v
```

> Le `-v` détruit aussi les volumes et donc les données. Utile pour repartir propre.

## Prochaine étape

Pratique 2 — [`pratique-02-ch07-premiers-pas-cypher/`](../pratique-02-ch07-premiers-pas-cypher/)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
