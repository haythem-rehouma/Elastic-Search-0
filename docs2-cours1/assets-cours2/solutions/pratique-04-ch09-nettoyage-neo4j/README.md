<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Pratique 4 — Nettoyage et reset d'une base Neo4j (chap. 09)

> Référence : [chapitre 09 — Nettoyage et reset d'une base Neo4j](../../../09-nettoyage-neo4j.md)

## Objectif

Maîtriser **les 5 méthodes** pour repartir d'une base propre, du plus chirurgical au plus radical.

## Les 5 méthodes (du plus doux au plus brutal)

| # | Méthode                              | Garde                          | Supprime                        | Fichier                                                |
| - | ------------------------------------ | ------------------------------ | ------------------------------- | ------------------------------------------------------ |
| 1 | Effacer seulement les relations       | Nœuds, contraintes, index      | Relations                       | [`cypher/10-clean-relations.cypher`](./cypher/10-clean-relations.cypher) |
| 2 | `DETACH DELETE` (le plus courant)    | Contraintes, index             | Nœuds + relations               | [`cypher/20-detach-delete.cypher`](./cypher/20-detach-delete.cypher) |
| 3 | `DROP CONSTRAINT / DROP INDEX`        | (rien après)                   | Contraintes et index            | [`cypher/30-drop-constraints-indexes.cypher`](./cypher/30-drop-constraints-indexes.cypher) |
| 4 | `apoc.periodic.iterate` (gros volumes) | Contraintes, index            | Nœuds + relations en lots       | [`cypher/40-apoc-bulk.cypher`](./cypher/40-apoc-bulk.cypher) |
| 5 | Reset volume Docker (table rase)      | (rien)                         | TOUT, retour à l'état d'usine   | [`scripts/reset-volume.sh`](./scripts/reset-volume.sh) |

## Démarrage rapide

```bash
docker compose up -d

# Charger des donnees factices
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/01-seed-demo.cypher

# Tester n'importe quelle methode (exemple : detach delete)
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/20-detach-delete.cypher
```

PowerShell :

```powershell
docker compose up -d
Get-Content cypher/01-seed-demo.cypher | docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!'
Get-Content cypher/20-detach-delete.cypher | docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!'
```

## Quand utiliser quoi ?

| Situation                                                        | Méthode |
| ---------------------------------------------------------------- | :-----: |
| « J'ai juste fait un mauvais `CREATE` de relation »              | 1       |
| « Je veux repartir des nœuds vides mais garder mon schéma »      | 2       |
| « Je change la modélisation, je drop tout »                      | 2 + 3   |
| « `DETACH DELETE` plante en OOM sur 10M de nœuds »               | 4       |
| « Je veux exactement l'état d'un nouveau conteneur »             | 5       |

## Piège classique

`DETACH DELETE` n'efface **pas** les **contraintes** ni les **index**. Si après nettoyage vous tentez :

```cypher
CREATE (u:User {nom: 'Alice'});
CREATE (u:User {nom: 'Alice'});
```

vous obtenez une erreur de contrainte unique. Solution : enchaîner méthode **2 puis 3**, ou utiliser la méthode **5**.

## Nettoyage du projet lui-même

```bash
docker compose down -v
```

## Prochaine étape

Pratique 5 — [`pratique-05-ch10-installation-es-kibana/`](../pratique-05-ch10-installation-es-kibana/)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
