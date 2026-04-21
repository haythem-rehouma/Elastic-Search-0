<a id="top"></a>

# 07 — Premiers pas en Cypher

> **Type** : Pratique · **Pré-requis** : [06 — Installation Neo4j](./06-installation-neo4j.md)

## Table des matières

- [1. Le langage Cypher en 30 secondes](#1-le-langage-cypher-en-30-secondes)
- [2. CRUD de base](#2-crud-de-base)
- [3. Manipuler les chaînes de caractères](#3-manipuler-les-chaînes-de-caractères)
- [4. Travailler avec `WITH`](#4-travailler-avec-with)
- [5. `UNWIND` et `ORDER BY`](#5-unwind-et-order-by)
- [6. Sauvegarde / restauration](#6-sauvegarde--restauration)

---

## 1. Le langage Cypher en 30 secondes

Cypher est au graphe ce que SQL est aux tables. Sa syntaxe imite un dessin :

```
(noeud)-[:RELATION]->(autre_noeud)
```

| Symbole         | Signification                                |
| --------------- | -------------------------------------------- |
| `()`            | Un nœud                                      |
| `[:TYPE]`       | Une relation de type `TYPE`                  |
| `-->`           | Sens de la relation                          |
| `--`            | Relation non orientée                        |
| `:Label`        | Étiquette du nœud (équivalent "table")       |
| `{prop: val}`   | Propriétés (équivalent "colonnes")           |

---

## 2. CRUD de base

### Créer un nœud

```cypher
CREATE (n:Person {name: 'John', age: 30})
```

### Lire (`MATCH`)

```cypher
MATCH (n:Person) WHERE n.name = 'John' RETURN n;
```

### Créer une relation

```cypher
CREATE (a:Person {name: 'Alice'})-[:KNOWS]->(b:Person {name: 'Bob'});
```

### Lire une relation

```cypher
MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a, b;
```

### Mettre à jour (`SET`)

```cypher
MATCH (n:Person {name: 'John'}) SET n.age = 31 RETURN n;
```

### Supprimer (`DETACH DELETE`)

```cypher
MATCH (n:Person {name: 'John'}) DETACH DELETE n;
```

### Supprimer **uniquement** une relation

```cypher
MATCH (a:Person {name: "Alice"})-[r:KNOWS]->(b:Person {name: "Bob"})
DELETE r;
```

> `DETACH DELETE` supprime le nœud **et** toutes ses relations.
> `DELETE` simple échoue si le nœud a encore des relations.

---

## 3. Manipuler les chaînes de caractères

### Comparaison sensible à la casse

```cypher
MATCH (n:cours) WHERE n.sigle = "420-J44-RO" RETURN n;
```

### Insensible à la casse

```cypher
MATCH (n:cours) WHERE tolower(n.sigle) = "420-j44-ro" RETURN n;
MATCH (n:cours) WHERE toupper(n.sigle) = "420-J44-RO" RETURN n;
```

### Sous-chaîne

```cypher
MATCH (n:cours) RETURN n.sigle, substring(n.sigle, 0, 3) AS prefixe;
MATCH (n:cours) RETURN DISTINCT substring(trim(n.sigle), 8, 2) AS college;
```

### Conversion en entier

```cypher
MATCH (n:cours)
RETURN toInteger(substring(trim(n.sigle), 0, 3)) + 1 AS prefixe_plus_un;
```

---

## 4. Travailler avec `WITH`

`WITH` est l'équivalent d'une **étape intermédiaire** dans un pipeline (comme `|` en shell).

```cypher
MATCH (n:cours)
WITH substring(n.sigle, 0, 3) AS prefixe,
     substring(n.sigle, 8, 2) AS college
RETURN prefixe, college;
```

> Sans `WITH`, on ne peut pas chaîner deux opérations qui dépendent l'une de l'autre.

---

## 5. `UNWIND` et `ORDER BY`

### Découper une liste en lignes

```cypher
MATCH (n:cours) WHERE n.sigle = "420-J44-RO"
UNWIND split(n.diplome, "/") AS element
RETURN element ORDER BY element ASC;
```

| Entrée                                            | Sorties                          |
| ------------------------------------------------- | -------------------------------- |
| `n.diplome = "AEC/DEC/MAITRISE/BAC/DOCTORAT"`     | 5 lignes : AEC, DEC, MAITRISE, … |

### Trier

```cypher
MATCH (n:cours) RETURN n ORDER BY n.sigle ASC LIMIT 10;
```

---

## 6. Sauvegarde / restauration

### Dump (sauvegarde)

```bash
neo4j-admin dump --database=neo4j --to=/path/to/backup.dump
```

Avec Docker :

```bash
docker exec spotify-neo4j neo4j-admin database dump neo4j --to-path=/data
```

### Restore

```bash
neo4j-admin load --from=/path/to/backup.dump --database=neo4j --force
```

### Compter rapidement

```cypher
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS rels;
```

> On verra dans le [chapitre 09](./09-nettoyage-neo4j.md) comment **nettoyer** une base avant de recharger.

<p align="right"><a href="#top">↑ Retour en haut</a></p>
