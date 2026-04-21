<a id="top"></a>

# Solutions — Chapitre 08 : Cas pratique Cypher « Intelligence Artificielle »

> **Lien chapitre source** : [`08-cas-pratique-cypher-ia.md`](../../08-cas-pratique-cypher-ia.md)
> **Pré-requis** : avoir suivi le [setup A à Z](./00-setup-complet-a-z.md) (au minimum les services `neo4j` doivent être healthy).

## Table des matières

- [0. Vérification rapide](#0-vérification-rapide)
- [1. Reset propre de la base](#1-reset-propre-de-la-base)
- [2. Script complet de création (à coller dans Neo4j Browser)](#2-script-complet-de-création-à-coller-dans-neo4j-browser)
- [3. Vérification visuelle](#3-vérification-visuelle)
- [4. Solutions des requêtes d'exploration](#4-solutions-des-requêtes-dexploration)
- [5. Solutions des requêtes de mise à jour](#5-solutions-des-requêtes-de-mise-à-jour)
- [6. Solutions des suppressions ciblées](#6-solutions-des-suppressions-ciblées)
- [7. Variante MERGE (sans doublons)](#7-variante-merge-sans-doublons)
- [8. Sortie attendue récapitulative](#8-sortie-attendue-récapitulative)

---

## 0. Vérification rapide

Avant de commencer, vérifiez que Neo4j tourne :

```bash
docker compose ps neo4j
# STATUS doit être : Up X minutes (healthy)

curl http://localhost:7474
# doit retourner du JSON/HTML
```

Ouvrez **Neo4j Browser** : http://localhost:7474 (login : `neo4j` / `spotify123`).

---

## 1. Reset propre de la base

Pour repartir d'un état vide (à exécuter dans Neo4j Browser) :

```cypher
MATCH (n) DETACH DELETE n;
```

Vérification :

```cypher
MATCH (n) RETURN count(n) AS total;
// → total: 0
```

---

## 2. Script complet de création (à coller dans Neo4j Browser)

> **Astuce** : dans Neo4j Browser, séparez chaque requête par `;` — elles s'exécutent les unes après les autres.

```cypher
// ==========================================
// 1) COURS DU PROGRAMME IA
// ==========================================
CREATE (:cours {sigle: '420-AI01-RO', diplome: 'AEC/DEC/MAITRISE/BAC/DOCTORAT'}),
       (:cours {sigle: '420-AI02-RO', diplome: 'AEC/DEC/MAITRISE/BAC/DOCTORAT'}),
       (:cours {sigle: '420-AI03-RO'}),
       (:cours {sigle: '420-AI04-RO'}),
       (:cours {sigle: '420-AI05-RO'}),
       (:cours {sigle: '420-AI06-RO'});

// ==========================================
// 2) PROFESSEURS + RELATIONS ENSEIGNER
//    (variante MERGE pour ne pas dupliquer les cours)
// ==========================================
MERGE (c1:cours {sigle: '420-AI01-RO'})
MERGE (c2:cours {sigle: '420-AI02-RO'})
MERGE (c3:cours {sigle: '420-AI03-RO'})
MERGE (c4:cours {sigle: '420-AI04-RO'})
MERGE (c5:cours {sigle: '420-AI05-RO'})

CREATE (:professeur {matricule: 101, prenom: 'John',    nom: 'Smith'})
       -[:ENSEIGNER]->(c1),
       (:professeur {matricule: 102, prenom: 'Emily',   nom: 'Johnson'})
       -[:ENSEIGNER {nbrhrs: 45}]->(c2),
       (:professeur {matricule: 103, prenom: 'Michael', nom: 'Williams'})
       -[:ENSEIGNER]->(c3),
       (:professeur {matricule: 104, prenom: 'Sarah',   nom: 'Brown'})
       -[:ENSEIGNER]->(c4),
       (:professeur {matricule: 105, prenom: 'Haythem', nom: 'Rehouma'})
       -[:ENSEIGNER {nbrhrs: 60}]->(c5);

// ==========================================
// 3) RELATIONS PREALABLE
// ==========================================
MATCH (a:cours {sigle: '420-AI05-RO'}), (b:cours {sigle: '420-AI01-RO'})
MERGE (a)-[:PREALABLE]->(b);

MATCH (a:cours {sigle: '420-AI06-RO'}), (b:cours {sigle: '420-AI02-RO'})
MERGE (a)-[:PREALABLE]->(b);

MATCH (a:cours {sigle: '420-AI02-RO'}), (b:cours {sigle: '420-AI03-RO'})
MERGE (a)-[:PREALABLE]->(b);

// ==========================================
// 4) RELATIONS COLLEGUES (idempotent via MERGE)
// ==========================================
MATCH (a:professeur {prenom: 'Haythem', nom: 'Rehouma'}),
      (b:professeur {prenom: 'John',    nom: 'Smith'})
MERGE (a)-[:COLLEGUES {programme: 'Intelligence Artificielle'}]->(b);

MATCH (a:professeur {prenom: 'Emily', nom: 'Johnson'}),
      (b:professeur {prenom: 'Sarah', nom: 'Brown'})
MERGE (a)-[:COLLEGUES {programme: 'Intelligence Artificielle'}]->(b);

MATCH (a:professeur {prenom: 'Michael', nom: 'Williams'}),
      (b:professeur {prenom: 'Sarah',   nom: 'Brown'})
MERGE (a)-[:COLLEGUES {programme: 'Intelligence Artificielle'}]->(b);
```

---

## 3. Vérification visuelle

```cypher
MATCH (a)-[r]->(b) RETURN a, r, b LIMIT 100;
```

Cliquez ensuite sur un nœud pour voir ses voisins. Vous devriez observer :

| Nœud type     | Compte attendu |
| ------------- | :------------: |
| `cours`       |       6        |
| `professeur`  |       5        |
| `ENSEIGNER`   |       5        |
| `PREALABLE`   |       3        |
| `COLLEGUES`   |       3        |

Vérifications chiffrées :

```cypher
MATCH (c:cours)         RETURN count(c) AS total_cours;
MATCH (p:professeur)    RETURN count(p) AS total_profs;
MATCH ()-[r:ENSEIGNER]->()  RETURN count(r) AS total_enseigner;
MATCH ()-[r:PREALABLE]->()  RETURN count(r) AS total_prealable;
MATCH ()-[r:COLLEGUES]->()  RETURN count(r) AS total_collegues;
```

---

## 4. Solutions des requêtes d'exploration

### Q1 — Lister tous les professeurs

```cypher
MATCH (p:professeur) RETURN p;
```

**Résultat attendu** : 5 lignes (John Smith, Emily Johnson, Michael Williams, Sarah Brown, Haythem Rehouma).

### Q2 — Prénoms / noms uniquement

```cypher
MATCH (p:professeur) RETURN p.prenom AS prenom, p.nom AS nom ORDER BY nom;
```

| prenom   | nom       |
| -------- | --------- |
| Sarah    | Brown     |
| Emily    | Johnson   |
| Haythem  | Rehouma   |
| John     | Smith     |
| Michael  | Williams  |

### Q3 — Trouver Haythem Rehouma

```cypher
MATCH (p:professeur)
WHERE p.prenom = 'Haythem' AND p.nom = 'Rehouma'
RETURN p;
```

### Q4 — Professeurs et leurs cours (avec heures)

```cypher
MATCH (p:professeur)-[r:ENSEIGNER]->(c:cours)
RETURN p.prenom + ' ' + p.nom AS professeur,
       c.sigle              AS cours,
       coalesce(r.nbrhrs, 'non précisé') AS heures
ORDER BY professeur;
```

| professeur          | cours        | heures        |
| ------------------- | ------------ | ------------- |
| Emily Johnson       | 420-AI02-RO  | 45            |
| Haythem Rehouma     | 420-AI05-RO  | 60            |
| John Smith          | 420-AI01-RO  | non précisé   |
| Michael Williams    | 420-AI03-RO  | non précisé   |
| Sarah Brown         | 420-AI04-RO  | non précisé   |

### Q5 — Relations entre collègues

```cypher
MATCH (p1:professeur)-[r:COLLEGUES]->(p2:professeur)
RETURN p1.nom AS de, p2.nom AS vers, r.programme AS programme;
```

### Q6 — Tous les prérequis (chemin court)

```cypher
MATCH (a:cours)-[:PREALABLE]->(b:cours)
RETURN a.sigle AS prerequis, b.sigle AS pour_le_cours
ORDER BY pour_le_cours;
```

### Q7 — Chaîne complète de prérequis (transitive)

```cypher
MATCH path = (a:cours)-[:PREALABLE*1..5]->(b:cours)
RETURN [n IN nodes(path) | n.sigle] AS chaine;
```

### Q8 — Bonus UNWIND (diplômes acceptés pour AI01)

```cypher
MATCH (n:cours) WHERE n.sigle = "420-AI01-RO"
UNWIND split(n.diplome, "/") AS element
RETURN element ORDER BY element ASC;
```

| element     |
| ----------- |
| AEC         |
| BAC         |
| DEC         |
| DOCTORAT    |
| MAITRISE    |

### Q9 — Bonus WITH (préfixe + collège)

```cypher
MATCH (n:cours)
WITH substring(n.sigle, 0, 3) AS prefixe,
     substring(n.sigle, 8, 2) AS college
RETURN DISTINCT prefixe, college;
```

→ `prefixe: "420"` , `college: "RO"` (cours du collège Rosemont).

---

## 5. Solutions des requêtes de mise à jour

### M1 — Ajouter un bureau à Haythem

```cypher
MATCH (p:professeur {prenom: 'Haythem', nom: 'Rehouma'})
SET p.bureau = 'A-204'
RETURN p;
```

### M2 — Modifier le nombre d'heures d'enseignement

```cypher
MATCH (p:professeur {prenom: 'Haythem'})-[r:ENSEIGNER]->(c:cours)
SET r.nbrhrs = 75
RETURN p.nom AS prof, c.sigle AS cours, r.nbrhrs AS nouvelles_heures;
```

### M3 — Ajouter une étiquette/label `senior` à un professeur

```cypher
MATCH (p:professeur {prenom: 'Haythem'})
SET p:senior
RETURN labels(p) AS labels;
// → labels: ['professeur', 'senior']
```

---

## 6. Solutions des suppressions ciblées

| Cas                                                | Requête                                                                              |
| -------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Supprimer **un** professeur (et ses relations)     | `MATCH (p:professeur {prenom:'Haythem',nom:'Rehouma'}) DETACH DELETE p;`             |
| Supprimer **tous** les professeurs                 | `MATCH (p:professeur) DETACH DELETE p;`                                              |
| Supprimer une **relation** ENSEIGNER précise       | `MATCH (p:professeur {prenom:'Haythem'})-[r:ENSEIGNER]->(c:cours) DELETE r;`         |
| Supprimer un prof par condition (60 h)             | `MATCH (p:professeur)-[r:ENSEIGNER {nbrhrs:60}]->(c) DETACH DELETE p;`               |
| Supprimer **toutes** les relations COLLEGUES       | `MATCH (:professeur)-[r:COLLEGUES]->(:professeur) DELETE r;`                         |
| **Tout** vider                                     | `MATCH (n) DETACH DELETE n;`                                                         |

> `DETACH DELETE` supprime **les relations puis le nœud** ; sans `DETACH`, Neo4j refuse de supprimer un nœud qui a des relations.

---

## 7. Variante MERGE (sans doublons)

Pour éviter les doublons à la création, on remplace `CREATE` par `MERGE` :

```cypher
MERGE (p:professeur {matricule: 101})
ON CREATE SET p.prenom = 'John', p.nom = 'Smith'
ON MATCH  SET p.last_seen = datetime();
```

| Verbe   | Comportement                                                       |
| ------- | ------------------------------------------------------------------ |
| `CREATE`| Crée toujours, peut faire des doublons                             |
| `MERGE` | Cherche un nœud correspondant ; sinon le crée. **Idempotent**.     |
| `MERGE` + `ON CREATE` | Ajouter des propriétés **uniquement à la création**  |
| `MERGE` + `ON MATCH`  | Ajouter des propriétés **uniquement si déjà existant**|

---

## 8. Sortie attendue récapitulative

À la fin de tous les exercices :

```cypher
MATCH (n) RETURN labels(n) AS label, count(n) AS nb;
```

| label              | nb |
| ------------------ | -- |
| `["cours"]`        | 6  |
| `["professeur"]`   | 5  |

```cypher
MATCH ()-[r]->() RETURN type(r) AS rel_type, count(r) AS nb;
```

| rel_type    | nb |
| ----------- | -- |
| `ENSEIGNER` | 5  |
| `PREALABLE` | 3  |
| `COLLEGUES` | 3  |

→ Si vous obtenez ces chiffres, **le cas pratique est réussi**.

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
