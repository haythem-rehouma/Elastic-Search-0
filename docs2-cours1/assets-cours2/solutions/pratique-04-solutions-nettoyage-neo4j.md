<a id="top"></a>

# Pratique 4 — Solutions : Nettoyage et reset Neo4j (chap. 09)

> Cible : [chapitre 09](../../09-nettoyage-neo4j.md) · Projet runnable : [`pratique-04-ch09-nettoyage-neo4j/`](./pratique-04-ch09-nettoyage-neo4j/)

## Objectif

Connaître les **5 méthodes** pour repartir d'une base propre, comprendre **ce que chacune préserve / supprime**, et choisir la bonne selon le contexte.

## Tableau de décision

| Méthode                        | Garde nœuds ? | Garde relations ? | Garde contraintes/index ? | Coût  | Quand l'utiliser                                |
| ------------------------------ | :-----------: | :---------------: | :-----------------------: | :---: | ----------------------------------------------- |
| 1. `MATCH ()-[r]-() DELETE r`  | Oui           | **Non**           | Oui                       | Faible | « Mauvais lien créé, je veux corriger »        |
| 2. `MATCH (n) DETACH DELETE n` | **Non**       | **Non**           | Oui                       | Moyen  | Cas le plus courant                             |
| 3. `DROP CONSTRAINT/INDEX`     | (déjà)        | (déjà)            | **Non**                   | Faible | Changement de modélisation                       |
| 4. APOC `periodic.iterate`     | **Non**       | **Non**           | Oui                       | Élevé* | Big Data : `DETACH DELETE` plante en OOM        |
| 5. `docker compose down -v`    | (volume)      | (volume)          | **Non**                   | Faible | Repartir totalement à neuf                       |

*Élevé en temps mais constant en mémoire (lots de 10 000).

## Solutions détaillées

### Méthode 1 — Effacer seulement les relations

```cypher
MATCH ()-[r]-()
DELETE r;
```

Les nœuds sont **conservés**. Utile quand vous avez créé une mauvaise relation (`CONNAIT` au lieu de `SUIT`) et voulez recommencer le câblage sans perdre les nœuds.

### Méthode 2 — `DETACH DELETE` (la plus courante)

```cypher
MATCH (n) DETACH DELETE n;
```

`DETACH` retire automatiquement les relations attachées aux nœuds avant la suppression. Sans `DETACH`, vous obtiendriez une erreur si un nœud a encore des relations.

> **Attention :** sur des **millions** de nœuds, cette commande peut planter en `OutOfMemory` (toutes les modifs sont dans une seule transaction). Utiliser méthode 4 dans ce cas.

### Méthode 3 — Supprimer le schéma

```cypher
SHOW CONSTRAINTS;
SHOW INDEXES;

DROP CONSTRAINT user_nom_unique IF EXISTS;
DROP INDEX user_nom_index IF EXISTS;
```

**Méthode 2 ne supprime PAS les contraintes/index.** Si vous changez de modélisation et voulez tout reset, enchaîner **2 puis 3**.

### Méthode 4 — Nettoyage en lots avec APOC

```cypher
CALL apoc.periodic.iterate(
  "MATCH (n) RETURN n",
  "DETACH DELETE n",
  {batchSize: 10000, parallel: false}
);
```

Découpe le travail en lots de 10 000 nœuds, chaque lot dans sa propre transaction. Pas de risque OOM. Utilisé en production sur des bases de plusieurs millions de nœuds.

### Méthode 5 — Reset volume Docker (table rase)

```bash
docker compose down -v
docker compose up -d
```

Le `-v` détruit le volume `p04_neo4j_data`. Au redémarrage, Neo4j repart **totalement vierge** : aucune donnée, aucun schéma, password réinitialisé. Méthode la plus radicale et la plus rapide pour repartir de zéro.

## Test guidé (15 minutes)

```bash
docker compose up -d

# Charger 3 noeuds + 3 relations + 1 contrainte + 1 index
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/01-seed-demo.cypher

# Methode 1 : effacer les relations seulement
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/10-clean-relations.cypher
# Resultat : 3 noeuds restants, 0 relation

# Recharger les donnees
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/01-seed-demo.cypher

# Methode 2 : DETACH DELETE
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/20-detach-delete.cypher
# Resultat : 0 noeud, mais la contrainte 'user_nom_unique' est toujours la

# Methode 3 : supprimer la contrainte
docker exec -i p04_neo4j cypher-shell -u neo4j -p 'Neo4jStrongPass!' < cypher/30-drop-constraints-indexes.cypher
# Resultat : aucune contrainte, aucun index
```

## Pièges classiques

| Piège                                                   | Solution                                                         |
| ------------------------------------------------------- | ---------------------------------------------------------------- |
| `DELETE` sans `DETACH` sur un nœud connecté             | Erreur explicite. Ajouter `DETACH`.                              |
| `DETACH DELETE` sur 5 M de nœuds → OOM                  | Utiliser méthode 4 (APOC iterate).                               |
| Après `DETACH DELETE`, un `CREATE` échoue en contrainte | Méthode 2 ne drop pas les contraintes. Faire méthode 3 ensuite.  |
| Reset volume Docker mais le password est resté         | Le password est dans le **volume** ; après `down -v`, il revient à la valeur de `NEO4J_AUTH`. |

## Pour aller plus loin

- Pratique suivante : [`pratique-05-solutions-installation-es-kibana.md`](./pratique-05-solutions-installation-es-kibana.md)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
