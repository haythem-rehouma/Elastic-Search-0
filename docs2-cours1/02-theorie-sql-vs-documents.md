<a id="top"></a>

# 02 — SQL vs Documents (le modèle d'Elasticsearch)

> **Type** : Théorie · **Pré-requis** : [01](./01-introduction-elasticsearch-elk-stack.md)

## Table des matières

- [1. Deux philosophies opposées](#1-deux-philosophies-opposées)
- [2. Tableau de correspondance SQL ↔ Elasticsearch](#2-tableau-de-correspondance-sql--elasticsearch)
- [3. Schéma rigide vs schéma flexible](#3-schéma-rigide-vs-schéma-flexible)
- [4. Pas de jointure : on aplatit !](#4-pas-de-jointure--on-aplatit-)
- [5. Quand choisir l'un ou l'autre ?](#5-quand-choisir-lun-ou-lautre-)

---

## 1. Deux philosophies opposées

| Aspect                | Base SQL (relationnel)                          | Elasticsearch (orienté document)             |
| --------------------- | ----------------------------------------------- | -------------------------------------------- |
| Unité de stockage     | Ligne dans une table                            | Document JSON dans un index                  |
| Schéma                | **Rigide** (défini avant)                       | **Flexible** (mapping dynamique possible)    |
| Relations             | Jointures (`JOIN`)                              | **Pas de jointure** → on dénormalise         |
| Optimisé pour         | Cohérence, transactions ACID                    | Recherche, lecture, agrégation               |
| Mise à jour partielle | `UPDATE col = val`                              | Réindexation du document (techniquement)     |

---

## 2. Tableau de correspondance SQL ↔ Elasticsearch

| Concept SQL          | Concept Elasticsearch                              |
| -------------------- | -------------------------------------------------- |
| Database             | Cluster                                            |
| Table                | **Index**                                          |
| Row                  | **Document** (JSON)                                |
| Column               | **Field**                                          |
| Schema (DDL)         | **Mapping**                                        |
| Index (B-tree)       | **Index inversé** (Lucene)                         |
| `SELECT * FROM …`    | `GET /index/_search`                               |
| `WHERE col = 'x'`    | `{"query": {"term": {"col": "x"}}}`                |
| `GROUP BY`           | **Aggregations**                                   |
| `JOIN`               | → dénormalisation, `nested`, ou `parent/child`  |

---

## 3. Schéma rigide vs schéma flexible

### En SQL

```sql
CREATE TABLE personne (
  id   INT PRIMARY KEY,
  nom  VARCHAR(100),
  age  INT
);
```

Si tu insères `nom = 'Alice', age = 'trente'`, ça **échoue**.

### Dans Elasticsearch

```json
PUT /personne/_doc/1
{
  "nom": "Alice",
  "age": 30,
  "hobbies": ["lecture", "vélo"]
}
```

Le mapping est **deviné automatiquement** au premier document. On peut aussi le **figer** à l'avance pour éviter les surprises (recommandé en production).

> La flexibilité, c'est cool en dev, mais en prod **on définit toujours un mapping explicite** (sinon `age` peut être typé `long` aujourd'hui et `text` demain → tout casse).

---

## 4. Pas de jointure : on aplatit !

En SQL, on aurait :

```
TABLE article          TABLE auteur
+----+--------+        +----+--------+
| id | titre  |        | id | nom    |
+----+--------+        +----+--------+
| 1  | "ELK"  |        | 1  | Alice  |
+----+--------+        +----+--------+
   |
   ↓ FK auteur_id = 1
```

En Elasticsearch, on stocke tout **dans le même document** (= **dénormalisation**) :

```json
{
  "titre": "Comprendre la stack ELK",
  "auteur": {
    "id": 1,
    "nom": "Alice"
  },
  "tags": ["elk", "kibana"]
}
```

<details>
<summary>Et si l'auteur change de nom ?</summary>

Il faut mettre à jour **tous les documents** qui le mentionnent. C'est le **prix à payer** pour une recherche ultra-rapide. Si la mise à jour fréquente est critique, Elasticsearch n'est probablement pas le bon outil pour cette donnée-là.

</details>

---

## 5. Quand choisir l'un ou l'autre ?

| Besoin métier                                   | Outil recommandé              |
| ----------------------------------------------- | ----------------------------- |
| Transactions bancaires, cohérence stricte       | SQL (Postgres, MySQL…)        |
| Catalogue produit avec recherche                | **Elasticsearch** (+ SQL)     |
| Logs applicatifs                                | **Elasticsearch**             |
| Données fortement liées (graphe d'amis…)        | **Neo4j** (graphe)            |
| Cache clé/valeur ultra-rapide                   | Redis                         |
| Document JSON sans recherche complexe           | MongoDB                       |

> Dans ce cours on combine **Neo4j (graphe) + Elasticsearch (recherche)** : chacun fait ce qu'il fait le mieux.

<p align="right"><a href="#top">↑ Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
