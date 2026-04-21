<a id="top"></a>

# 09 — Nettoyage et reset d'une base Neo4j

> **Type** : Pratique · **Pré-requis** : [07](./07-premiers-pas-cypher.md), [08](./08-cas-pratique-cypher-ia.md)

## Table des matières

- [1. Pourquoi nettoyer ?](#1-pourquoi-nettoyer-)
- [2. La commande de base](#2-la-commande-de-base)
- [3. Variantes ciblées](#3-variantes-ciblées)
- [4. Grosse base : nettoyer par lots avec APOC](#4-grosse-base--nettoyer-par-lots-avec-apoc)
- [5. Lancer depuis cypher-shell](#5-lancer-depuis-cypher-shell)
- [6. Réinitialiser totalement la base](#6-réinitialiser-totalement-la-base)
- [7. Index & contraintes](#7-index--contraintes)
- [8. Cheatsheet](#8-cheatsheet)

---

## 1. Pourquoi nettoyer ?

| Situation                                | Action                                                  |
| ---------------------------------------- | ------------------------------------------------------- |
| Vous avez exécuté un script plusieurs fois → doublons | Supprimer + relancer avec `MERGE`           |
| Vous changez de modèle                   | Supprimer tous les nœuds                                |
| Vous avez chargé un mauvais CSV          | Supprimer un label précis                               |
| Vous voulez repartir from scratch        | Drop + Create de la database                            |

---

## 2. La commande de base

```cypher
MATCH (n) DETACH DELETE n;
```

| Mot-clé        | Rôle                                                                       |
| -------------- | -------------------------------------------------------------------------- |
| `MATCH (n)`    | Sélectionne **tous** les nœuds                                             |
| `DETACH`       | Détache toutes les relations attachées au nœud (sans ça : erreur)          |
| `DELETE n`     | Supprime le nœud                                                           |

---

## 3. Variantes ciblées

### Supprimer les relations seulement (garder les nœuds)

```cypher
MATCH ()-[r]-() DELETE r;
```

### Supprimer un seul label

```cypher
MATCH (n:Person) DETACH DELETE n;
```

### Supprimer une relation précise sans toucher aux nœuds

```cypher
MATCH (a:Person {name:"Alice"})-[r:KNOWS]->(b:Person {name:"Bob"})
DELETE r;
```

---

## 4. Grosse base : nettoyer par lots avec APOC

Avec une base lourde, `MATCH (n) DETACH DELETE n` saturera la mémoire. On utilise `apoc.periodic.iterate` :

```cypher
CALL apoc.periodic.iterate(
  'MATCH (n) RETURN n',
  'DETACH DELETE n',
  {batchSize: 5000, parallel: true}
);
```

| Paramètre    | Effet                                                          |
| ------------ | -------------------------------------------------------------- |
| `batchSize`  | Nombre de nœuds traités par transaction                        |
| `parallel`   | Plusieurs threads en parallèle (gain de temps)                 |

> Le plugin **APOC doit être installé** (cf. chapitre 06).

---

## 5. Lancer depuis cypher-shell

### Local

```bash
cypher-shell -u neo4j -p 'votre_mot_de_passe' "MATCH (n) DETACH DELETE n"
```

### Docker

```bash
docker exec -it spotify-neo4j cypher-shell -u neo4j -p Neo4jStrongPass! \
  "MATCH (n) DETACH DELETE n"
```

---

## 6. Réinitialiser totalement la base

> Détruit aussi les **indexes** et **contraintes**. À utiliser avec précaution.

Dans le browser :

```cypher
:use system
STOP DATABASE neo4j;
DROP DATABASE neo4j;
CREATE DATABASE neo4j;
START DATABASE neo4j;
```

En ligne de commande (service arrêté) :

```bash
neo4j-admin database remove --force neo4j
neo4j-admin dbms set-initial-password 'nouveau_mdp'
```

---

## 7. Index & contraintes

### Lister

```cypher
SHOW INDEXES;       -- Neo4j 5.x / 4.4
SHOW CONSTRAINTS;
```

<details>
<summary>Anciennes versions (Neo4j 3.5 / 4.0 / 4.1)</summary>

```cypher
CALL db.indexes();
CALL db.constraints();
```

Dans le Browser, `:schema` fonctionne aussi.

</details>

### Vérifier la version

```cypher
RETURN version();
CALL dbms.components();
```

### Supprimer

```cypher
DROP INDEX <nom_index>     IF EXISTS;
DROP CONSTRAINT <nom>      IF EXISTS;
```

### Génération automatique de DROP (versions 4.x sans noms)

```cypher
CALL db.indexes() YIELD description
RETURN 'DROP ' + description AS drop_cmd;
```

→ Copier/coller chaque ligne retournée.

### Tout nuker en une commande (APOC)

```cypher
CALL apoc.schema.assert({},{});
```

> Supprime **tous** les index et contraintes (sans rien recréer).

---

## 8. Cheatsheet

| Objectif                                | Commande                                                                |
| --------------------------------------- | ----------------------------------------------------------------------- |
| Tout supprimer                          | `MATCH (n) DETACH DELETE n;`                                            |
| Supprimer relations uniquement          | `MATCH ()-[r]-() DELETE r;`                                             |
| Supprimer un label                      | `MATCH (n:Label) DETACH DELETE n;`                                      |
| Tout supprimer (grosse base)            | `CALL apoc.periodic.iterate('MATCH (n) RETURN n','DETACH DELETE n',{batchSize:5000});` |
| Compter les nœuds                       | `MATCH (n) RETURN count(n);`                                            |
| Compter les relations                   | `MATCH ()-[r]->() RETURN count(r);`                                     |
| Lister index (5.x)                      | `SHOW INDEXES;`                                                         |
| Tout nettoyer (schéma)                  | `CALL apoc.schema.assert({},{});`                                       |

<p align="right"><a href="#top">↑ Retour en haut</a></p>
