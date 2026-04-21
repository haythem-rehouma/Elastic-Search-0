<a id="top"></a>

# Pratique 2 — Premiers pas en Cypher (chap. 07)

> Référence : [chapitre 07 — Premiers pas en Cypher](../../../07-premiers-pas-cypher.md)

## Objectif

Découvrir la syntaxe de base de **Cypher** : `CREATE`, `MATCH`, `RETURN`, `WHERE`, `ORDER BY`, `count()`, `avg()` et la traversée de relations (chemin de longueur N).

## Stack

| Service | Image                  | Port  |
| ------- | ---------------------- | :---: |
| Neo4j   | `neo4j:5.20-community` | 7474, 7687 |

## Démarrage rapide

```bash
docker compose up -d

bash scripts/run-all.sh
```

PowerShell :

```powershell
docker compose up -d

.\scripts\run-all.ps1
```

## Contenu pédagogique

| Fichier Cypher                         | Contenu                                              |
| -------------------------------------- | ---------------------------------------------------- |
| [`cypher/01-create-nodes.cypher`](./cypher/01-create-nodes.cypher) | 4 personnes + 3 villes |
| [`cypher/02-create-relations.cypher`](./cypher/02-create-relations.cypher) | `HABITE_A` et `CONNAIT` |
| [`cypher/03-queries.cypher`](./cypher/03-queries.cypher) | 8 requêtes types graduées |
| [`cypher/99-reset.cypher`](./cypher/99-reset.cypher) | `MATCH (n) DETACH DELETE n` |

## Les 8 requêtes types

| #  | Sujet                                       | Démontre                                |
| -: | ------------------------------------------- | --------------------------------------- |
|  1 | Tous les nœuds Personne                     | `MATCH ... RETURN`                      |
|  2 | Trier par âge                               | `ORDER BY age DESC`                     |
|  3 | Personnes habitant Montréal                 | Filtre par propriété sur la cible       |
|  4 | Connaissances d'Alice                       | Traversée `-[:CONNAIT]->`               |
|  5 | Amis d'amis (chemin de longueur 2)          | `[:CONNAIT*2]` + `DISTINCT`             |
|  6 | Compter les habitants par ville             | `count()` + `GROUP BY` implicite        |
|  7 | Âge moyen                                   | `avg()`                                 |
|  8 | Depuis quand Alice habite Montréal          | Lecture des **propriétés de relation**  |

## Visualiser dans le Browser

Ouvrir http://localhost:7474, se connecter avec `neo4j` / `Neo4jStrongPass!`, puis exécuter :

```cypher
MATCH (n) RETURN n LIMIT 100;
```

Vous voyez le **graphe complet** : 4 personnes + 3 villes + relations.

## Nettoyage

```bash
docker compose down -v
```

## Prochaine étape

Pratique 3 — [`pratique-03-ch08-cypher-ia/`](../pratique-03-ch08-cypher-ia/)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
