<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# 16 — Requêtes avancées : KQL, ES|QL, Query DSL

> **Type** : Pratique · **Pré-requis** : [15 — Requêtes intermédiaires](./15-requetes-elasticsearch-intermediaire.md)

## Table des matières

- [1. Trois langages, trois usages](#1-trois-langages-trois-usages)
- [2. KQL — Kibana Query Language](#2-kql--kibana-query-language)
- [3. ES|QL — l'approche SQL-like](#3-esql--lapproche-sql-like)
- [4. Query DSL — le format JSON officiel](#4-query-dsl--le-format-json-officiel)
- [5. Tableau comparatif](#5-tableau-comparatif)
- [6. Cas pratique : index `news`](#6-cas-pratique--index-news)
- [7. Recommandations d'usage](#7-recommandations-dusage)

---

## 1. Trois langages, trois usages

Elasticsearch permet d'écrire la même requête de plusieurs façons :

| Langage     | Format          | Où l'utiliser                  | Force                         |
| ----------- | --------------- | ------------------------------ | ----------------------------- |
| **KQL**     | Une ligne texte | Kibana → Discover, filtres     | Le plus rapide à taper        |
| **ES\|QL**  | SQL-like        | Discover, Dev Tools            | Pipeline (FROM → STATS → …)   |
| **DSL JSON**| JSON structuré  | Dev Tools, API REST, code      | Le plus puissant et complet   |

> **Règle pratique** : KQL pour explorer, ES|QL pour analyser, DSL pour l'app finale.

---

## 2. KQL — Kibana Query Language

Disponible dans la barre de recherche **Discover** et dans les filtres de dashboards.

### Filtre simple

```text
category : "POLITICS"
```

### Période

```text
date >= "2018-05-20" and date < "2018-06-01"
```

### Plein texte (OR)

```text
headline : "Trump" or short_description : "Trump"
```

### Combinaison complexe

```text
category : ("WORLD NEWS" or "POLITICS")
  and authors : "Ron Dicker"
  and date >= "2018-05-25"
```

| Opérateur     | Effet                                    |
| ------------- | ---------------------------------------- |
| `and / or`    | Booléens                                 |
| `not`         | Négation                                 |
| `:`           | Égalité                                  |
| `:*`          | Champ existe (n'est pas null)            |
| `>`, `<`, `>=`, `<=` | Comparaisons numériques / dates    |
| `( )`         | Groupements                              |
| `*`           | Wildcard (ex : `headline : Trump*`)      |

---

## 3. ES|QL — l'approche SQL-like

Disponible dans Discover (sélecteur en haut) et dans **Dev Tools → Console**.

### Comptage par catégorie

```sql
FROM news
| STATS count = COUNT(*) BY category
| ORDER BY count DESC
| LIMIT 10
```

### Top auteurs sur une période

```sql
FROM news
| WHERE date BETWEEN "2018-05-20" AND "2018-05-31"
| STATS articles = COUNT(*) BY authors
| ORDER BY articles DESC
| LIMIT 10
```

### Recherche plein texte

```sql
FROM news
| WHERE MATCH(headline, "Trump") OR MATCH(short_description, "Trump")
| LIMIT 20
```

### Histogramme par jour pour une catégorie

```sql
FROM news
| WHERE category == "POLITICS"
| EVAL day = DATE_TRUNC(1 days, date)
| STATS articles = COUNT(*) BY day
| ORDER BY day
```

| Mot-clé             | Rôle                                                                    |
| ------------------- | ----------------------------------------------------------------------- |
| `FROM`              | Source (= index)                                                        |
| `WHERE`             | Filtre                                                                  |
| `STATS … BY …`      | Agrégation (≈ `GROUP BY`)                                               |
| `EVAL`              | Crée un nouveau champ calculé                                           |
| `ORDER BY`          | Tri                                                                     |
| `LIMIT`             | Taille max                                                              |
| `KEEP / DROP`       | Sélection / élimination de colonnes                                     |
| `DATE_TRUNC`        | Tronque une date (équivalent `date_histogram`)                          |

---

## 4. Query DSL — le format JSON officiel

C'est le langage **complet** d'Elasticsearch. Tout ce qu'on peut faire avec KQL ou ES|QL passe par DSL en interne.

### Plein texte multi-champs avec boost

```json
GET news/_search
{
  "query": {
    "multi_match": {
      "query":  "Trump",
      "fields": ["headline^2", "short_description"]
    }
  },
  "size": 20
}
```

### Filtre exact + dates + tri

```json
GET news/_search
{
  "query": {
    "bool": {
      "must":   [ { "term":  { "category.keyword": "POLITICS" } } ],
      "filter": [ { "range": { "date": { "gte": "2018-05-20", "lt": "2018-06-01" } } } ]
    }
  },
  "sort": [ { "date": "desc" } ]
}
```

### Top catégories (agrégation)

```json
GET news/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": { "field": "category.keyword", "size": 10 }
    }
  }
}
```

### Histogramme `POLITICS` par jour

```json
GET news/_search
{
  "size": 0,
  "query": { "term": { "category.keyword": "POLITICS" } },
  "aggs": {
    "per_day": {
      "date_histogram": { "field": "date", "calendar_interval": "day" }
    }
  }
}
```

### Surlignage (highlight)

```json
GET news/_search
{
  "query": {
    "multi_match": { "query": "North Korea", "fields": ["headline","short_description"] }
  },
  "highlight": {
    "fields": { "headline": {}, "short_description": {} }
  }
}
```

### Function score (ranking custom)

```json
GET news/_search
{
  "query": {
    "function_score": {
      "query":      { "match": { "headline": "Trump" } },
      "boost_mode": "multiply",
      "score_mode": "sum",
      "functions": [
        { "filter": { "term": { "category.keyword": "POLITICS" } }, "weight": 2.0 }
      ]
    }
  }
}
```

---

## 5. Tableau comparatif

| Besoin                                     | KQL                                  | ES\|QL                                              | DSL                                |
| ------------------------------------------ | ------------------------------------ | --------------------------------------------------- | ---------------------------------- |
| Filtrer par catégorie                      | `category : "POLITICS"`              | `WHERE category == "POLITICS"`                      | `term` ou `match`                  |
| Filtrer par période                        | `date >= "..." and date < "..."`     | `WHERE date BETWEEN "..." AND "..."`                | `range`                            |
| Plein texte                                | `headline : "Trump"`                 | `WHERE MATCH(headline, "Trump")`                    | `match`                            |
| `GROUP BY` catégorie                       |                                    | `STATS COUNT(*) BY category`                        | `aggs.terms`                       |
| Histogramme temporel                       |                                    | `EVAL day=DATE_TRUNC(1 days, date) STATS COUNT(*) BY day` | `aggs.date_histogram`         |
| Boost / scoring custom                     |                                    |                                                   | `function_score`                   |
| Sub-aggregations imbriquées                |                                    | partiel                                             |                                  |
| Highlight                                  |                                    |                                                   | `highlight`                        |
| Pagination grand volume (`search_after`)   |                                    |                                                   |                                  |

---

## 6. Cas pratique : index `news`

| Question                                              | Outil idéal | Réponse                                                          |
| ----------------------------------------------------- | ----------- | ---------------------------------------------------------------- |
| « Voir les articles WORLD NEWS du dernier mois »      | KQL         | `category : "WORLD NEWS" and date >= "2018-04-01"`               |
| « Top 10 catégories les plus actives »                | ES\|QL      | `FROM news \| STATS COUNT(*) BY category \| ORDER BY ... LIMIT 10` |
| « Articles dont le titre OU la description parle de Trump, classés par pertinence » | DSL | `multi_match` avec `^2` sur `headline`             |
| « Top auteurs avec leur dernier article »             | DSL         | `aggs.terms` + sous-`top_hits`                                   |
| « Surligner "North Korea" dans les titres »           | DSL         | `highlight`                                                      |

---

## 7. Recommandations d'usage

- **Discover en mode KQL** = exploration rapide pour un analyste / utilisateur métier.
- **ES|QL** = pour les rapports tabulaires (alternative à SQL).
- **Query DSL** = pour le code (Python, Node, Java) et les requêtes vraiment complexes.

> Dans le **Labo 2** ([chapitre 17](./17-labo2-rapport-dsl-news.md)), on n'utilisera **que** le Query DSL pour bien le maîtriser.

<p align="right"><a href="#top">↑ Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
