<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
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

### `UNWIND` en un mot : **déplier**

`UNWIND` veut dire **« déplier une liste en lignes »**. C'est exactement ça : vous avez **une liste** (un tableau), et vous voulez **une ligne par élément**.

**Image mentale :** vous avez une **boîte de chaussettes**. `UNWIND` ouvre la boîte et **étale chaque chaussette sur la table**, une par une.

```
Avant UNWIND : [ "AEC", "DEC", "BAC" ]   ← 1 ligne, 1 liste
Après UNWIND :    "AEC"
                  "DEC"                   ← 3 lignes, 1 valeur chacune
                  "BAC"
```

**Pourquoi c'est utile ?** Cypher (comme SQL) travaille **ligne par ligne**. Si vous avez une liste à l'intérieur d'une cellule, vous ne pouvez ni la trier, ni l'agréger, ni la filtrer simplement. `UNWIND` la transforme en plusieurs lignes — et là, tout devient possible.

### Découper une liste en lignes (exemple concret)

```cypher
MATCH (n:cours) WHERE n.sigle = "420-J44-RO"
UNWIND split(n.diplome, "/") AS element
RETURN element ORDER BY element ASC;
```

**Ce que fait chaque ligne :**

1. `MATCH` trouve **un seul cours** (`420-J44-RO`).
2. `split(n.diplome, "/")` transforme la chaîne `"AEC/DEC/MAITRISE/BAC/DOCTORAT"` en **liste** `["AEC","DEC","MAITRISE","BAC","DOCTORAT"]`.
3. `UNWIND ... AS element` **déplie** la liste : 1 ligne devient **5 lignes**, chacune avec une variable `element`.
4. `ORDER BY element ASC` trie alphabétiquement.

| Entrée                                            | Sorties                                                  |
| ------------------------------------------------- | -------------------------------------------------------- |
| `n.diplome = "AEC/DEC/MAITRISE/BAC/DOCTORAT"`     | 5 lignes : `AEC`, `BAC`, `DEC`, `DOCTORAT`, `MAITRISE`   |

<details>
<summary><b>Comparer : avec et sans <code>UNWIND</code></b></summary>

**Sans `UNWIND` :**

```cypher
MATCH (n:cours) WHERE n.sigle = "420-J44-RO"
RETURN split(n.diplome, "/") AS diplomes;
```

Résultat : **1 ligne**, 1 colonne contenant une liste.

```
diplomes
---------------------------------
["AEC","DEC","MAITRISE","BAC","DOCTORAT"]
```

**Avec `UNWIND` :**

```cypher
MATCH (n:cours) WHERE n.sigle = "420-J44-RO"
UNWIND split(n.diplome, "/") AS element
RETURN element;
```

Résultat : **5 lignes**, 1 colonne avec une seule valeur chacune.

```
element
--------
AEC
DEC
MAITRISE
BAC
DOCTORAT
```

**C'est exactement la différence entre une liste et un ensemble de lignes.**

</details>

<details>
<summary><b>Quand utiliser <code>UNWIND</code> en pratique</b></summary>

| Situation                                                           | Utiliser `UNWIND` ?                                  |
| ------------------------------------------------------------------- | ---------------------------------------------------- |
| Vous avez une **liste** dans une propriété et voulez la trier       | **Oui**                                              |
| Vous voulez **créer plusieurs nœuds d'un coup** depuis une liste    | **Oui** : `UNWIND [...] AS x CREATE (:Label {...})`  |
| Vous voulez **compter** combien d'éléments dans une liste           | Non, utilisez `size(liste)`                          |
| Vous voulez juste **renvoyer** la liste telle quelle                | Non, `RETURN liste` suffit                           |
| Vous chargez un CSV avec une colonne « tags » séparés par virgules  | **Oui** : `UNWIND split(row.tags, ",") AS tag`       |

**Cas typique d'import en masse :**

```cypher
UNWIND ["Alice", "Bob", "Carol"] AS prenom
CREATE (:Personne {nom: prenom});
```

Crée **3 nœuds** d'un coup.

</details>

> **À retenir en une phrase :** `UNWIND` = transformer **une liste en plusieurs lignes**, pour pouvoir les manipuler une par une comme n'importe quelle ligne Cypher.

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


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
