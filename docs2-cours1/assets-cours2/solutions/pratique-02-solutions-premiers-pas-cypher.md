<a id="top"></a>

# Pratique 2 — Solutions : Premiers pas en Cypher (chap. 07)

> Cible : [chapitre 07](../../07-premiers-pas-cypher.md) · Projet runnable : [`pratique-02-ch07-premiers-pas-cypher/`](./pratique-02-ch07-premiers-pas-cypher/)

## Objectif

Maîtriser les briques de base de Cypher : `CREATE`, `MATCH`, `WHERE`, `RETURN`, `ORDER BY`, traversée de relations, agrégations.

## Solution clé en main

```bash
cd pratique-02-ch07-premiers-pas-cypher
docker compose up -d
bash scripts/run-all.sh    # ou .\scripts\run-all.ps1
```

Ce script exécute, dans l'ordre :

1. `99-reset.cypher` — efface tout
2. `01-create-nodes.cypher` — crée 4 personnes + 3 villes
3. `02-create-relations.cypher` — crée `HABITE_A` et `CONNAIT`
4. `03-queries.cypher` — joue les **8 requêtes types**

## Les 8 requêtes commentées

### Q1 — Toutes les personnes

```cypher
MATCH (p:Personne) RETURN p;
```

`MATCH` = pattern matching. `(p:Personne)` = nœud avec label `Personne` capturé dans la variable `p`.

### Q2 — Trier par âge décroissant

```cypher
MATCH (p:Personne)
RETURN p.nom AS nom, p.age AS age
ORDER BY age DESC;
```

`p.nom` = accès à une **propriété** du nœud. `AS` renomme la colonne de sortie.

### Q3 — Filtrer par propriété de la cible

```cypher
MATCH (p:Personne)-[:HABITE_A]->(v:Ville {nom: 'Montreal'})
RETURN p.nom AS habitant_montreal;
```

Le filtre `{nom: 'Montreal'}` est inline. Équivaut à un `WHERE v.nom = 'Montreal'`.

### Q4 — Traversée simple

```cypher
MATCH (alice:Personne {nom: 'Alice'})-[:CONNAIT]->(ami:Personne)
RETURN ami.nom AS connaissances_alice;
```

La flèche `-[:CONNAIT]->` est **dirigée**. Pour ignorer la direction, utiliser `-[:CONNAIT]-`.

### Q5 — Chemin de longueur N (amis d'amis)

```cypher
MATCH (alice:Personne {nom: 'Alice'})-[:CONNAIT*2]->(ami_d_ami:Personne)
WHERE ami_d_ami.nom <> 'Alice'
RETURN DISTINCT ami_d_ami.nom AS amis_d_amis;
```

`*2` = exactement 2 relations. `*1..3` = entre 1 et 3. C'est ce qui rend Cypher unique : SQL galère à exprimer ça en `JOIN` récursifs.

### Q6 — Compter par groupe

```cypher
MATCH (p:Personne)-[:HABITE_A]->(v:Ville)
RETURN v.nom AS ville, count(p) AS nb_habitants
ORDER BY nb_habitants DESC;
```

En Cypher, **pas besoin de `GROUP BY`** : le groupement est implicite sur les colonnes non-agrégées.

### Q7 — Agrégation simple

```cypher
MATCH (p:Personne) RETURN avg(p.age) AS age_moyen;
```

`avg()`, `sum()`, `min()`, `max()`, `count()`, `collect()` sont disponibles d'office.

### Q8 — Lire une propriété de relation

```cypher
MATCH (p:Personne {nom: 'Alice'})-[r:HABITE_A]->(v:Ville)
RETURN p.nom AS personne, v.nom AS ville, r.depuis AS depuis_annee;
```

Capturer la relation dans `r` permet de lire ses propriétés (`r.depuis`).

## Tableau récapitulatif des constructions

| Construction       | Exemple                            | Équivalent SQL approximatif                  |
| ------------------ | ---------------------------------- | -------------------------------------------- |
| `(n:Label)`        | `(p:Personne)`                     | `FROM personne p`                            |
| `{prop: value}`    | `{nom: 'Alice'}`                   | `WHERE nom = 'Alice'`                        |
| `-[:REL]->`        | `-[:CONNAIT]->`                    | `JOIN ... ON personne_id = friend_id`        |
| `-[:REL*2]->`      | `-[:CONNAIT*2]->`                  | Joindre 2 fois la table de relation          |
| `count(x)`         | `count(p)`                         | `COUNT(*)`                                   |
| `r.prop`           | `r.depuis`                         | Colonne de la table d'association            |

## Pour aller plus loin

- Pratique suivante : [`pratique-03-solutions-cypher-cas-ia.md`](./pratique-03-solutions-cypher-cas-ia.md)
- Documentation Cypher officielle : https://neo4j.com/docs/cypher-manual/current/

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
