<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Solutions — Chapitre 15 : Requêtes Elasticsearch intermédiaires

> **Lien chapitre source** : [`15-requetes-elasticsearch-intermediaire.md`](../../15-requetes-elasticsearch-intermediaire.md)
> **Pré-requis** : [Setup A à Z](./00-setup-complet-a-z.md) + [Solutions chap. 14](./pratique-08-solutions-bulk-import.md) (l'index `news` doit contenir 200 853 articles).
> **Où exécuter** : Kibana → **Dev Tools → Console** (http://localhost:5601/app/dev_tools#/console).

## Table des matières

- [0. Vérification de l'index `news`](#0-vérification-de-lindex-news)
- [1. Compter exactement les hits](#1-compter-exactement-les-hits)
- [2. Recherche full-text (`match`)](#2-recherche-full-text-match)
- [3. Précision vs Rappel — démonstration chiffrée](#3-précision-vs-rappel--démonstration-chiffrée)
- [4. `match_phrase` (expression exacte)](#4-match_phrase-expression-exacte)
- [5. `multi_match` avec boost](#5-multi_match-avec-boost)
- [6. Tolérance aux fautes (`fuzzy`)](#6-tolérance-aux-fautes-fuzzy)
- [7. Recherches exactes (`term`, `terms`, `prefix`)](#7-recherches-exactes-term-terms-prefix)
- [8. Filtres combinés (`bool`)](#8-filtres-combinés-bool)
- [9. Plages (`range`)](#9-plages-range)
- [10. Tri & pagination (`from/size`, `search_after`)](#10-tri--pagination-fromsize-search_after)
- [11. Highlight](#11-highlight)
- [12. Agrégations](#12-agrégations)
- [13. `_update_by_query` et `_reindex`](#13-_update_by_query-et-_reindex)
- [14. Quiz corrigé](#14-quiz-corrigé)

---

## 0. Vérification de l'index `news`

```
GET _cat/indices/news?v
```

→ doit afficher `docs.count` ≈ **200 853**.

```
GET news/_search
{ "track_total_hits": true, "size": 0 }
```

Réponse attendue :

```json
"hits": { "total": { "value": 200853, "relation": "eq" }, ... }
```

Si vous voyez `"value": 10000, "relation": "gte"` → vous avez oublié `track_total_hits: true`.

---

## 1. Compter exactement les hits

```
GET news/_count
```

```json
{ "count": 200853, "_shards": { ... } }
```

Comptage filtré (articles politiques) :

```
GET news/_count
{
  "query": { "term": { "category.keyword": "POLITICS" } }
}
```

→ ~32 739.

---

## 2. Recherche full-text (`match`)

```
GET news/_search
{
  "size": 5,
  "_source": ["headline","date","category"],
  "query":   { "match": { "headline": "Trump summit North Korea" } }
}
```

Lecture de la sortie :

| Champ                        | Sens                                                 |
| ---------------------------- | ---------------------------------------------------- |
| `hits.total.value`           | Nombre de docs qui matchent (≈ plusieurs milliers)   |
| `hits.max_score`             | Score TF-IDF le plus haut                            |
| `hits.hits[].\_score`         | Score de chaque doc                                  |
| `hits.hits[]._source`        | Le document indexé (réduit aux champs `_source`)     |

---

## 3. Précision vs Rappel — démonstration chiffrée

Lancez les **3 variantes** sur la même question et comparez `hits.total.value` :

### Variante OR (par défaut, rappel max)

```
GET news/_search
{
  "size": 0,
  "track_total_hits": true,
  "query": { "match": { "headline": { "query": "obama trump clinton" } } }
}
```

→ **plusieurs dizaines de milliers** de hits (au moins 1 mot).

### Variante AND (précision max)

```
GET news/_search
{
  "size": 0,
  "track_total_hits": true,
  "query": { "match": { "headline": { "query": "obama trump clinton", "operator": "and" } } }
}
```

→ **quelques dizaines** de hits (3 mots tous présents).

### Variante minimum_should_match (compromis)

```
GET news/_search
{
  "size": 0,
  "track_total_hits": true,
  "query": { "match": { "headline": { "query": "obama trump clinton", "minimum_should_match": 2 } } }
}
```

→ **plusieurs centaines** de hits (au moins 2 mots sur 3).

| Variante               | hits typiques | Rappel | Précision |
| ---------------------- | -------------:| :----: | :-------: |
| OR (défaut)            | ~25 000       |  ▲▲▲   |     ▼     |
| AND                    |     ~30       |   ▼▼   |   ▲▲▲     |
| `minimum_should_match: 2` | ~500       |   ▲    |    ▲▲     |

> C'est cette **démonstration chiffrée** qui permet de comprendre le compromis. Lancez-la !

---

## 4. `match_phrase` (expression exacte)

```
GET news/_search
{
  "size": 5,
  "_source": ["headline","date"],
  "query":   { "match_phrase": { "headline": "President Obama" } }
}
```

→ Tous les hits ont les mots **dans cet ordre** et **côte-à-côte**. Précision très haute.

Variante avec `slop` (autorise N mots entre les termes) :

```
GET news/_search
{
  "query": {
    "match_phrase": {
      "headline": { "query": "Obama Russia", "slop": 3 }
    }
  }
}
```

---

## 5. `multi_match` avec boost

```
GET news/_search
{
  "size": 5,
  "_source": ["headline","short_description","authors"],
  "query": {
    "multi_match": {
      "query":  "President Obama",
      "fields": ["headline^3", "short_description", "authors"]
    }
  }
}
```

→ Un titre qui contient « President Obama » sera **3 fois mieux classé** qu'une description.

Variante `type: phrase` (multi_match qui exige l'expression exacte par champ) :

```
GET news/_search
{
  "query": {
    "multi_match": {
      "query":  "President Obama",
      "fields": ["headline^2","short_description"],
      "type":   "phrase"
    }
  }
}
```

---

## 6. Tolérance aux fautes (`fuzzy`)

```
GET news/_search
{
  "size": 3,
  "_source": ["headline"],
  "query": {
    "match": {
      "headline": { "query": "presdent obmaa", "fuzziness": "AUTO" }
    }
  }
}
```

→ retourne quand même des hits sur "President Obama" malgré les fautes.

| `fuzziness` | Distance d'édition autorisée                                   |
| ----------- | -------------------------------------------------------------- |
| `0`         | Aucune (= match strict)                                        |
| `1`         | 1 lettre de différence                                         |
| `2`         | 2 lettres                                                      |
| `AUTO`      | Adapté à la longueur du terme (recommandé)                     |

---

## 7. Recherches exactes (`term`, `terms`, `prefix`)

```
# UN terme exact (sur .keyword !)
GET news/_search
{ "query": { "term": { "category.keyword": "POLITICS" } } }

# LISTE de termes exacts
GET news/_search
{ "query": { "terms": { "category.keyword": ["POLITICS","WORLD NEWS","CRIME"] } } }

# Préfixe
GET news/_search
{ "size": 5, "query": { "prefix": { "authors.keyword": "Mary" } } }
```

> **Piège classique** : `term: { category: "POLITICS" }` (sans `.keyword`) **ne marchera pas** car `category` est analysé en minuscules par défaut. Toujours cibler le sous-champ `.keyword` pour les recherches exactes.

---

## 8. Filtres combinés (`bool`)

Recherche : Trump dans le titre, en POLITICS ou WORLD NEWS, en mai 2018, sans mention de "joke" :

```
GET news/_search
{
  "_source": ["date","category","headline"],
  "query": {
    "bool": {
      "must":   [ { "match": { "headline": "Trump" } } ],
      "filter": [
        { "terms": { "category.keyword": ["POLITICS","WORLD NEWS"] } },
        { "range": { "date": { "gte": "2018-05-01", "lte": "2018-05-31" } } }
      ],
      "must_not": [ { "match_phrase": { "short_description": "joke" } } ],
      "should":   [ { "match": { "short_description": "summit" } } ]
    }
  }
}
```

| Clause     | Compte dans le score ? | Effet                                                    |
| ---------- | :-------------------: | -------------------------------------------------------- |
| `must`     |          oui          | DOIT matcher                                             |
| `filter`   |          **non**      | DOIT matcher (cacheable, plus rapide)                    |
| `must_not` |          non          | NE DOIT PAS matcher                                      |
| `should`   |          oui          | OPTIONNEL ; remonte le score si match                    |

> **Optimisation** : tout filtre exact (term/terms/range/exists) doit aller dans `filter`, pas dans `must`. Gain de performance significatif sur gros volumes.

---

## 9. Plages (`range`)

```
GET news/_search
{
  "size": 0,
  "query": {
    "range": { "date": { "gte": "2018-01-01", "lt": "2019-01-01" } }
  }
}
```

| Opérateur | Sens |
| --------- | ---- |
| `gte`     | ≥    |
| `gt`      | >    |
| `lte`     | ≤    |
| `lt`      | <    |

Format de date relatif (très utile dans Kibana) :

| Notation   | Sens                                       |
| ---------- | ------------------------------------------ |
| `now`      | Maintenant                                 |
| `now-1d/d` | Hier minuit                                |
| `now-7d`   | Il y a 7 jours                             |
| `now/M`    | Premier jour du mois courant               |
| `now+1y`   | Dans un an                                 |

---

## 10. Tri & pagination (`from/size`, `search_after`)

### Pagination classique

```
GET news/_search
{
  "from": 0,  "size": 10,
  "_source": ["date","headline"],
  "sort":    [ { "date": "desc" } ]
}
```

> `from + size > 10 000` est **bloqué** par défaut (limite `index.max_result_window`).

### Pagination scalable `search_after`

Page 1 :

```
GET news/_search
{
  "size": 5,
  "_source": ["date","headline"],
  "sort":    [ { "date": "desc" }, { "_id": "desc" } ]
}
```

Récupérez la valeur `sort` du dernier hit, par ex. `["2018-05-26","_xyz123"]`, puis :

```
GET news/_search
{
  "size": 5,
  "_source":     ["date","headline"],
  "sort":        [ { "date": "desc" }, { "_id": "desc" } ],
  "search_after":["2018-05-26","_xyz123"]
}
```

→ Vous pouvez paginer indéfiniment, même sur 1 milliard de docs.

---

## 11. Highlight

```
GET news/_search
{
  "size": 3,
  "_source": ["headline","short_description","date"],
  "query":   { "match": { "short_description": "North Korea summit" } },
  "highlight": {
    "fields":    { "headline": {}, "short_description": {} },
    "pre_tags":  ["<mark>"],
    "post_tags": ["</mark>"]
  }
}
```

Sortie : chaque hit contient désormais un objet `highlight` avec les fragments surlignés (à utiliser tels quels dans une UI HTML).

---

## 12. Agrégations

### 12.1 Comptage par catégorie (Top 10)

```
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

Sortie typique :

| key            | doc_count |
| -------------- | --------: |
| POLITICS       |    32 739 |
| WELLNESS       |    17 827 |
| ENTERTAINMENT  |    16 058 |
| TRAVEL         |     9 887 |
| STYLE & BEAUTY |     9 649 |

### 12.2 Histogramme par jour + sous-aggregation

```
GET news/_search
{
  "size": 0,
  "aggs": {
    "per_day": {
      "date_histogram": { "field": "date", "calendar_interval": "day" },
      "aggs": {
        "by_cat": { "terms": { "field": "category.keyword", "size": 5 } }
      }
    }
  }
}
```

### 12.3 Top hit par catégorie

```
GET news/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": { "field": "category.keyword", "size": 5 },
      "aggs": {
        "latest": {
          "top_hits": {
            "size": 1,
            "sort":   [ { "date": "desc" } ],
            "_source":["date","headline","authors"]
          }
        }
      }
    }
  }
}
```

### 12.4 Cardinalité (auteurs distincts)

```
GET news/_search
{
  "size": 0,
  "aggs": {
    "authors_count": { "cardinality": { "field": "authors.keyword" } }
  }
}
```

→ ~25 000 auteurs distincts.

### 12.5 `significant_text` (mots saillants pour POLITICS)

```
GET news/_search
{
  "size": 0,
  "query": { "term": { "category.keyword": "POLITICS" } },
  "aggs":  { "hot_terms": { "significant_text": { "field": "headline", "size": 10 } } }
}
```

→ Termes typiquement renvoyés : `trump`, `obama`, `clinton`, `senate`, `congress`, `gop`, `democrats`, etc.

---

## 13. `_update_by_query` et `_reindex`

### Uppercaser tous les `category` (Painless)

```
POST news/_update_by_query
{
  "script": {
    "source": "ctx._source.category = ctx._source.category.toUpperCase();",
    "lang":   "painless"
  },
  "query": { "match_all": {} }
}
```

> Long sur 200 853 docs (~1-2 min). À ne lancer qu'une fois.

### Migration vers `news_v2` (avec mapping différent)

```
PUT news_v2
{
  "mappings": {
    "properties": {
      "date":     { "type": "date", "format": "yyyy-MM-dd" },
      "category": { "type": "keyword" },
      "headline": { "type": "text", "analyzer": "english" },
      "short_description": { "type": "text", "analyzer": "english" },
      "authors":  { "type": "keyword" },
      "link":     { "type": "keyword" }
    }
  }
}

POST _reindex
{
  "source": { "index": "news"    },
  "dest":   { "index": "news_v2" }
}

GET news_v2/_count
```

→ Le `_reindex` recopie tous les docs avec le nouveau mapping. Indispensable quand on **change** un type de champ (les mappings sont **immuables**).

---

## 14. Quiz corrigé

| Question                                                              | Réponse                                                  |
| --------------------------------------------------------------------- | -------------------------------------------------------- |
| Comment voir le **vrai** nombre de hits (> 10 000) ?                  | `"track_total_hits": true`                               |
| Pourquoi `term: category=POLITICS` retourne 0 ?                       | `category` est analysé → utiliser `category.keyword`     |
| Différence `match` (OR) vs `match` + `operator: and` ?                | OR = rappel max ; AND = précision max                    |
| Comment paginer au-delà de 10 000 résultats ?                         | `search_after` avec un sort sur 2 champs (date + _id)    |
| Comment gérer le compromis précision/rappel finement ?                | `minimum_should_match` (nombre ou pourcentage)           |
| Pourquoi mettre une condition exacte dans `filter` plutôt que `must` ?| `filter` ne calcule pas le score, il est cacheable       |
| Comment changer le type d'un champ après coup ?                       | Impossible directement → `_reindex` vers nouvel index    |
| Différence `terms` agg vs `significant_text` ?                        | `terms` = top par fréquence absolue ; `significant_text` = top par fréquence **anormale** dans le subset |

→ Si ces requêtes vous parlent, vous êtes prêt pour le [chapitre 16](../../16-requetes-avancees-kql-esql-dsl.md) (KQL vs ES|QL vs DSL) et le [Labo 2](./labo-2-solutions-rapport-dsl-news.md).

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
