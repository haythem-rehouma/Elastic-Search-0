<a id="top"></a>

# Chapitre 15 — Comprendre les requêtes Elasticsearch dans Kibana Dev Tools

## Objectif du chapitre

Dans ce chapitre, l’objectif est de comprendre **une par une** les requêtes Elasticsearch utilisées dans Kibana Dev Tools.

L’index utilisé s’appelle :

```http
news
```

Il contient des articles avec des champs comme :

```text
category
headline
authors
link
short_description
date
```

Chaque requête ci-dessous peut être copiée directement dans :

```text
Kibana → Dev Tools
```

---

## Table des matières

| #  | Requête                   | Objectif                       |
| -- | ------------------------- | ------------------------------ |
| 1  | `_count`                  | Compter les documents          |
| 2  | `match`                   | Comprendre précision vs rappel |
| 3  | `match_phrase`            | Chercher une phrase exacte     |
| 4  | `multi_match`             | Chercher dans plusieurs champs |
| 5  | `fuzzy`                   | Tolérer les fautes de frappe   |
| 6  | `term`, `terms`, `prefix` | Chercher des valeurs exactes   |
| 7  | `bool`                    | Combiner plusieurs conditions  |
| 8  | `range`                   | Filtrer par date               |
| 9  | `sort` + `search_after`   | Trier et paginer               |
| 10 | `highlight`               | Surligner les mots trouvés     |
| 11 | `aggs` + `top_hits`       | Grouper par catégorie          |
| 12 | `date_histogram`          | Grouper par jour               |
| 13 | `significant_text`        | Trouver les mots importants    |
| 14 | `cardinality`             | Compter les valeurs distinctes |
| 15 | `_update_by_query`        | Modifier plusieurs documents   |
| 16 | `_reindex`                | Copier vers un nouvel index    |

---

<details>
<summary><strong>1. Comptage exact avec <code>_count</code></strong></summary>

## Requête 1A — Compter tous les documents

```http
GET news/_count
```

## Explication vulgarisée

Cette requête demande simplement à Elasticsearch :

```text
Combien d’articles existe-t-il dans l’index news ?
```

Elle ne retourne pas les articles eux-mêmes.
Elle retourne seulement un nombre.

Exemple de résultat possible :

```json
{
  "count": 200853
}
```

Cela veut dire :

```text
Il y a 200 853 documents dans l’index news.
```

## À retenir

`_count` est utile quand on veut connaître rapidement le nombre total de documents sans afficher les données.

---

## Requête 1B — Compter avec `_search`

```http
GET news/_search
{
  "track_total_hits": true,
  "size": 0
}
```

## Explication vulgarisée

Cette requête fait presque la même chose que `_count`, mais avec le moteur de recherche `_search`.

La ligne :

```json
"size": 0
```

veut dire :

```text
Ne m’affiche aucun article.
Je veux seulement les statistiques.
```

La ligne :

```json
"track_total_hits": true
```

veut dire :

```text
Compte précisément tous les résultats.
```

## Pourquoi utiliser cette version ?

Parce que `_search` permet ensuite d’ajouter :

```text
des filtres,
des requêtes,
des agrégations,
des tris,
des conditions.
```

Donc `_search` est plus flexible que `_count`.

## Résumé simple

| Requête                  | Utilité                                               |
| ------------------------ | ----------------------------------------------------- |
| `_count`                 | Compter rapidement                                    |
| `_search` avec `size: 0` | Compter tout en préparant des filtres ou des analyses |

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>2. Précision vs rappel avec <code>match</code></strong></summary>

## Requête 2A — Match standard

```http
GET news/_search
{
  "size": 0,
  "track_total_hits": true,
  "query": {
    "match": {
      "headline": {
        "query": "obama trump clinton"
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche dans le champ :

```text
headline
```

les articles dont le titre contient :

```text
obama
trump
clinton
```

Par défaut, Elasticsearch comprend cela comme :

```text
Cherche les articles qui contiennent au moins un de ces mots.
```

Donc un article avec seulement :

```text
Obama speaks at event
```

peut être trouvé.

Un article avec seulement :

```text
Trump announces campaign
```

peut aussi être trouvé.

## Résultat attendu

Cette requête retourne généralement **beaucoup de résultats**.

Pourquoi ?

Parce qu’elle accepte les documents qui contiennent seulement une partie des mots.

## Concept important

Cette requête favorise le **rappel**.

Le rappel signifie :

```text
Ramener beaucoup de résultats, même si certains sont moins précis.
```

---

## Requête 2B — Match avec `operator: and`

```http
GET news/_search
{
  "size": 0,
  "track_total_hits": true,
  "query": {
    "match": {
      "headline": {
        "query": "obama trump clinton",
        "operator": "and"
      }
    }
  }
}
```

## Explication vulgarisée

Ici, Elasticsearch devient beaucoup plus strict.

La ligne :

```json
"operator": "and"
```

veut dire :

```text
Le titre doit contenir obama ET trump ET clinton.
```

Donc l’article doit contenir les trois mots.

## Résultat attendu

Cette requête retourne normalement **moins de résultats**.

Pourquoi ?

Parce que la condition est plus difficile à respecter.

## Concept important

Cette requête favorise la **précision**.

La précision signifie :

```text
Ramener moins de résultats, mais plus ciblés.
```

---

## Requête 2C — Match avec `minimum_should_match`

```http
GET news/_search
{
  "size": 0,
  "track_total_hits": true,
  "query": {
    "match": {
      "headline": {
        "query": "obama trump clinton",
        "minimum_should_match": 2
      }
    }
  }
}
```

## Explication vulgarisée

Ici, Elasticsearch demande :

```text
Le titre doit contenir au moins 2 mots parmi les 3.
```

Donc ces combinaisons peuvent marcher :

```text
obama + trump
obama + clinton
trump + clinton
```

Mais un titre avec seulement :

```text
obama
```

ne suffit pas.

## Pourquoi c’est intéressant ?

C’est un compromis entre les deux requêtes précédentes.

| Version                   | Condition       | Nombre de résultats |
| ------------------------- | --------------- | ------------------- |
| Match standard            | Au moins 1 mot  | Beaucoup            |
| `minimum_should_match: 2` | Au moins 2 mots | Moyen               |
| `operator: and`           | Tous les mots   | Peu                 |

## Résumé simple

```text
match simple = large
operator and = strict
minimum_should_match = équilibre
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>3. Recherche d’une phrase avec <code>match_phrase</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 5,
  "_source": ["headline", "date"],
  "query": {
    "match_phrase": {
      "headline": "President Obama"
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche la phrase exacte :

```text
President Obama
```

dans le champ :

```text
headline
```

La différence avec `match`, c’est que `match_phrase` respecte l’ordre des mots.

Donc Elasticsearch cherche :

```text
President Obama
```

et non simplement :

```text
President
Obama
```

séparés n’importe où dans le titre.

## Exemple

Un titre comme celui-ci peut être trouvé :

```text
President Obama Addresses The Nation
```

Mais un titre comme celui-ci peut ne pas être trouvé :

```text
Obama Was The Former President
```

Pourquoi ?

Parce que les mots ne sont pas dans le même ordre.

## Rôle de `_source`

```json
"_source": ["headline", "date"]
```

veut dire :

```text
Affiche seulement le titre et la date.
Ne retourne pas tous les champs.
```

## Rôle de `size`

```json
"size": 5
```

veut dire :

```text
Affiche seulement 5 résultats.
```

## Résumé simple

`match_phrase` est utile quand l’ordre des mots est important.

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>4. Recherche dans plusieurs champs avec <code>multi_match</code> et boost</strong></summary>

## Requête

```http
GET news/_search
{
  "size": 5,
  "_source": ["headline", "short_description", "authors"],
  "query": {
    "multi_match": {
      "query": "President Obama",
      "fields": ["headline^3", "short_description", "authors"]
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche :

```text
President Obama
```

dans plusieurs champs :

```text
headline
short_description
authors
```

Cela veut dire :

```text
Cherche cette expression dans le titre, dans la description courte et dans les auteurs.
```

## Le rôle du boost `^3`

Le champ :

```json
"headline^3"
```

veut dire :

```text
Si les mots sont trouvés dans le titre, donne plus d’importance à ce résultat.
```

Le titre est donc considéré comme **3 fois plus important** que les autres champs.

## Exemple simple

Imagine deux articles :

| Article   | Où le mot est trouvé ?   | Score probable |
| --------- | ------------------------ | -------------- |
| Article A | Dans `headline`          | Plus élevé     |
| Article B | Dans `short_description` | Moins élevé    |

Même si les deux parlent de President Obama, celui qui l’a dans le titre est considéré comme plus pertinent.

## Pourquoi utiliser `multi_match` ?

Parce qu’un utilisateur ne sait pas toujours où l’information se trouve.

Elle peut être dans :

```text
le titre,
la description,
le nom de l’auteur,
un autre champ.
```

## Résumé simple

```text
multi_match = chercher dans plusieurs colonnes
boost = donner plus d’importance à certaines colonnes
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>5. Recherche approximative avec <code>fuzziness</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 3,
  "_source": ["headline"],
  "query": {
    "match": {
      "headline": {
        "query": "presdent obmaa",
        "fuzziness": "AUTO"
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche dans les titres :

```text
presdent obmaa
```

Mais ces mots contiennent des fautes.

La bonne écriture serait probablement :

```text
president obama
```

Grâce à :

```json
"fuzziness": "AUTO"
```

Elasticsearch accepte les petites erreurs de frappe.

## À quoi sert `fuzzy` ?

Cela sert quand l’utilisateur écrit mal un mot.

Exemples :

```text
obmaa → obama
presdent → president
goverment → government
```

Elasticsearch essaie de trouver les mots les plus proches.

## Attention

La recherche approximative peut être pratique, mais elle peut aussi ramener des résultats moins précis.

Pourquoi ?

Parce qu’elle accepte des mots qui ressemblent, mais qui ne sont pas exactement les mêmes.

## Résumé simple

```text
fuzziness = tolérance aux fautes de frappe
AUTO = Elasticsearch décide automatiquement le niveau de tolérance
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>6. Requêtes exactes avec <code>term</code>, <code>terms</code> et <code>prefix</code></strong></summary>

## Requête 6A — `term`

```http
GET news/_search
{
  "query": {
    "term": {
      "category.keyword": "POLITICS"
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche les articles dont la catégorie est exactement :

```text
POLITICS
```

Elle utilise :

```text
category.keyword
```

et non :

```text
category
```

Pourquoi ?

Parce que `.keyword` permet de chercher une valeur exacte.

## Différence importante

| Champ              | Utilisation                  |
| ------------------ | ---------------------------- |
| `category`         | Recherche textuelle analysée |
| `category.keyword` | Recherche exacte             |

## Exemple

Avec `term`, Elasticsearch ne cherche pas une ressemblance.

Il demande :

```text
La catégorie est-elle exactement POLITICS ?
```

---

## Requête 6B — `terms`

```http
GET news/_search
{
  "query": {
    "terms": {
      "category.keyword": ["POLITICS", "WORLD NEWS", "CRIME"]
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche les articles dont la catégorie est l’une des valeurs suivantes :

```text
POLITICS
WORLD NEWS
CRIME
```

C’est comme dire :

```text
Donne-moi les articles qui appartiennent à l’une de ces trois catégories.
```

## Différence entre `term` et `terms`

| Requête | Sens                                |
| ------- | ----------------------------------- |
| `term`  | Une seule valeur exacte             |
| `terms` | Plusieurs valeurs exactes possibles |

---

## Requête 6C — `prefix`

```http
GET news/_search
{
  "size": 5,
  "query": {
    "prefix": {
      "authors.keyword": "Mary"
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche les auteurs dont le nom commence par :

```text
Mary
```

Elle peut trouver par exemple :

```text
Mary Smith
Mary Johnson
Mary Papenfuss
```

## Attention

`prefix` cherche le début exact d’un champ.

Si le champ contient :

```text
John Mary
```

il ne sera pas forcément trouvé, car le champ ne commence pas par `Mary`.

## Résumé simple

```text
term = valeur exacte
terms = plusieurs valeurs exactes
prefix = commence par
.keyword = champ non découpé, utile pour les recherches exactes
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>7. Requête complète avec <code>bool</code></strong></summary>

## Requête

```http
GET news/_search
{
  "_source": ["date", "category", "headline"],
  "query": {
    "bool": {
      "must": [
        { "match": { "headline": "Trump" } }
      ],
      "filter": [
        { "terms": { "category.keyword": ["POLITICS", "WORLD NEWS"] } },
        { "range": { "date": { "gte": "2018-05-01", "lte": "2018-05-31" } } }
      ],
      "must_not": [
        { "match_phrase": { "short_description": "joke" } }
      ],
      "should": [
        { "match": { "short_description": "summit" } }
      ]
    }
  }
}
```

## Explication vulgarisée

La requête `bool` permet de construire une recherche avec plusieurs conditions.

Elle ressemble à une recherche avancée avec :

```text
obligatoire,
filtre,
exclusion,
bonus.
```

---

## Partie 1 — `must`

```json
"must": [
  { "match": { "headline": "Trump" } }
]
```

Cela veut dire :

```text
Le titre doit contenir le mot Trump.
```

C’est une condition obligatoire.

---

## Partie 2 — `filter`

```json
"filter": [
  { "terms": { "category.keyword": ["POLITICS", "WORLD NEWS"] } },
  { "range": { "date": { "gte": "2018-05-01", "lte": "2018-05-31" } } }
]
```

Cela veut dire :

```text
La catégorie doit être POLITICS ou WORLD NEWS.
La date doit être entre le 1er mai 2018 et le 31 mai 2018.
```

Le `filter` sert à limiter les résultats sans influencer le score de pertinence.

## Différence entre `must` et `filter`

| Élément  | Rôle                                         |
| -------- | -------------------------------------------- |
| `must`   | Condition obligatoire qui influence le score |
| `filter` | Condition obligatoire qui filtre seulement   |

---

## Partie 3 — `must_not`

```json
"must_not": [
  { "match_phrase": { "short_description": "joke" } }
]
```

Cela veut dire :

```text
Exclure les articles dont la description contient la phrase joke.
```

C’est une condition négative.

---

## Partie 4 — `should`

```json
"should": [
  { "match": { "short_description": "summit" } }
]
```

Cela veut dire :

```text
Si la description contient summit, c’est mieux.
```

Ce n’est pas forcément obligatoire.
C’est plutôt un bonus de pertinence.

## Résumé simple

| Bloc       | Sens vulgarisé                 |
| ---------- | ------------------------------ |
| `must`     | Doit contenir                  |
| `filter`   | Doit respecter                 |
| `must_not` | Ne doit pas contenir           |
| `should`   | Ce serait mieux si ça contient |

## Phrase complète

Cette requête signifie :

```text
Trouve les articles dont le titre parle de Trump,
dans les catégories POLITICS ou WORLD NEWS,
publiés en mai 2018,
mais exclue ceux dont la description contient joke.
Si la description contient summit, fais remonter ces résultats plus haut.
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>8. Filtrer une période avec <code>range</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 0,
  "query": {
    "range": {
      "date": {
        "gte": "2018-01-01",
        "lt": "2019-01-01"
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche les articles publiés entre :

```text
2018-01-01
```

et :

```text
2019-01-01
```

Mais attention :

```json
"lt": "2019-01-01"
```

veut dire :

```text
strictement avant le 1er janvier 2019
```

Donc la requête couvre toute l’année 2018.

## Signification des opérateurs

| Opérateur | Sens                                      |
| --------- | ----------------------------------------- |
| `gte`     | Greater Than or Equal = supérieur ou égal |
| `gt`      | Greater Than = strictement supérieur      |
| `lte`     | Less Than or Equal = inférieur ou égal    |
| `lt`      | Less Than = strictement inférieur         |

## Pourquoi `size: 0` ?

Parce qu’ici on veut compter ou analyser les résultats, pas afficher les articles.

## Résumé simple

```text
range = chercher dans un intervalle
gte = à partir de
lt = avant
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>9. Trier les résultats avec <code>sort</code> et continuer avec <code>search_after</code></strong></summary>

## Requête 9A — Premier lot de résultats

```http
GET news/_search
{
  "size": 5,
  "_source": ["date", "headline"],
  "sort": [
    { "date": "desc" },
    { "_id": "desc" }
  ]
}
```

## Explication vulgarisée

Cette requête affiche 5 articles, avec seulement :

```text
date
headline
```

Les résultats sont triés par :

```text
date décroissante
```

Donc les articles les plus récents apparaissent en premier.

## Pourquoi ajouter `_id` dans le tri ?

```json
{ "_id": "desc" }
```

sert à départager deux articles qui auraient la même date.

C’est comme dire :

```text
Si deux documents ont la même date, utilise leur identifiant pour garder un ordre stable.
```

---

## Requête 9B — Page suivante avec `search_after`

```http
GET news/_search
{
  "size": 5,
  "_source": ["date", "headline"],
  "sort": [
    { "date": "desc" },
    { "_id": "desc" }
  ],
  "search_after": ["2018-05-26", "<ID_DERNIER_HIT>"]
}
```

## Explication vulgarisée

`search_after` sert à continuer la recherche après le dernier résultat déjà affiché.

C’est une forme de pagination.

Au lieu de dire :

```text
Donne-moi la page 2
```

on dit :

```text
Continue après ce dernier article.
```

## Pourquoi utiliser `search_after` ?

Parce que pour de grands volumes de données, `search_after` est souvent plus performant que la pagination classique avec `from` et `size`.

## Étapes pratiques

1. Lancer la première requête.
2. Regarder le dernier résultat.
3. Copier sa valeur `sort`.
4. La mettre dans `search_after`.
5. Relancer pour obtenir la suite.

## Résumé simple

```text
sort = ordre des résultats
search_after = continuer après le dernier résultat affiché
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>10. Surligner les mots trouvés avec <code>highlight</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 3,
  "_source": ["headline", "short_description", "date"],
  "query": {
    "match": {
      "short_description": "North Korea summit"
    }
  },
  "highlight": {
    "fields": {
      "headline": {},
      "short_description": {}
    },
    "pre_tags": ["<mark>"],
    "post_tags": ["</mark>"]
  }
}
```

## Explication vulgarisée

Cette requête cherche :

```text
North Korea summit
```

dans le champ :

```text
short_description
```

Ensuite, elle demande à Elasticsearch de surligner les mots trouvés dans :

```text
headline
short_description
```

## Rôle de `highlight`

Le bloc :

```json
"highlight": {
  "fields": {
    "headline": {},
    "short_description": {}
  }
}
```

veut dire :

```text
Montre-moi où les mots recherchés apparaissent.
```

## Rôle de `pre_tags` et `post_tags`

```json
"pre_tags": ["<mark>"],
"post_tags": ["</mark>"]
```

Cela veut dire :

```text
Entoure les mots trouvés avec la balise HTML <mark>.
```

Exemple :

```html
<mark>North Korea</mark> summit
```

Dans une interface web, `<mark>` affiche généralement le texte surligné.

## Pourquoi c’est utile ?

C’est utile dans un moteur de recherche, car l’utilisateur voit directement pourquoi un résultat a été retourné.

## Résumé simple

```text
highlight = montrer visuellement les mots trouvés
<mark> = balise HTML de surlignage
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>11. Agrégation par catégorie avec <code>terms</code> et <code>top_hits</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": {
        "field": "category.keyword",
        "size": 10
      },
      "aggs": {
        "latest": {
          "top_hits": {
            "size": 1,
            "sort": [
              { "date": "desc" }
            ],
            "_source": ["date", "headline", "authors"]
          }
        }
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête ne cherche pas à afficher tous les articles.

Elle veut faire une analyse :

```text
Quelles sont les principales catégories ?
Et quel est le dernier article dans chaque catégorie ?
```

## Rôle de `size: 0`

```json
"size": 0
```

veut dire :

```text
N’affiche pas les articles dans la section principale.
Je veux seulement les résultats de l’agrégation.
```

## Rôle de `terms`

```json
"terms": {
  "field": "category.keyword",
  "size": 10
}
```

Cela veut dire :

```text
Regroupe les articles par catégorie.
Affiche les 10 catégories les plus fréquentes.
```

## Rôle de `top_hits`

```json
"top_hits": {
  "size": 1,
  "sort": [
    { "date": "desc" }
  ]
}
```

Cela veut dire :

```text
Dans chaque catégorie, affiche le document le plus récent.
```

## Exemple vulgarisé

Imagine cette question :

```text
Montre-moi les 10 catégories les plus présentes dans les données.
Pour chaque catégorie, donne-moi le dernier article publié.
```

C’est exactement ce que fait cette requête.

## Résumé simple

```text
terms = regrouper par catégorie
top_hits = afficher un exemple de document dans chaque groupe
sort date desc = prendre le plus récent
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>12. Nombre d’articles par jour avec <code>date_histogram</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 0,
  "aggs": {
    "per_day": {
      "date_histogram": {
        "field": "date",
        "calendar_interval": "day"
      },
      "aggs": {
        "by_cat": {
          "terms": {
            "field": "category.keyword",
            "size": 5
          }
        }
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête sert à analyser les articles dans le temps.

Elle demande :

```text
Combien d’articles sont publiés chaque jour ?
Et pour chaque jour, quelles sont les principales catégories ?
```

## Rôle de `date_histogram`

```json
"date_histogram": {
  "field": "date",
  "calendar_interval": "day"
}
```

Cela veut dire :

```text
Regroupe les articles par jour.
```

## Rôle de `by_cat`

```json
"by_cat": {
  "terms": {
    "field": "category.keyword",
    "size": 5
  }
}
```

Cela veut dire :

```text
Pour chaque jour, donne les 5 catégories les plus fréquentes.
```

## Exemple de logique

Elasticsearch peut produire une analyse du genre :

```text
2018-05-01
  POLITICS: 120 articles
  ENTERTAINMENT: 80 articles
  WORLD NEWS: 60 articles

2018-05-02
  POLITICS: 110 articles
  CRIME: 40 articles
  SPORTS: 30 articles
```

## Pourquoi c’est utile ?

C’est utile pour construire :

```text
des graphiques temporels,
des tableaux de bord,
des analyses d’évolution,
des histogrammes dans Kibana.
```

## Résumé simple

```text
date_histogram = regrouper par période
calendar_interval day = un groupe par jour
sub-terms = sous-groupe par catégorie
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>13. Trouver les mots importants avec <code>significant_text</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 0,
  "query": {
    "term": {
      "category.keyword": "POLITICS"
    }
  },
  "aggs": {
    "hot_terms": {
      "significant_text": {
        "field": "headline",
        "size": 10
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête cherche d’abord les articles de la catégorie :

```text
POLITICS
```

Ensuite, elle analyse les titres de ces articles pour trouver les mots qui ressortent le plus.

## Attention importante

`significant_text` ne donne pas simplement les mots les plus fréquents.

Il cherche les mots qui sont particulièrement importants dans un sous-ensemble.

Ici, le sous-ensemble est :

```text
les articles de catégorie POLITICS
```

## Exemple simple

Supposons que dans tout l’index, le mot :

```text
news
```

apparaisse partout.

Il n’est pas très significatif.

Mais si dans la catégorie `POLITICS`, les mots suivants apparaissent beaucoup plus que dans les autres catégories :

```text
senate
election
trump
congress
```

alors ils peuvent ressortir comme mots significatifs.

## Différence avec un simple compteur

| Méthode            | Ce qu’elle montre                                 |
| ------------------ | ------------------------------------------------- |
| `terms`            | Les mots les plus fréquents                       |
| `significant_text` | Les mots anormalement importants dans un contexte |

## Résumé simple

```text
significant_text = trouver les mots caractéristiques d’un groupe
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>14. Compter les auteurs distincts avec <code>cardinality</code></strong></summary>

## Requête

```http
GET news/_search
{
  "size": 0,
  "aggs": {
    "authors_count": {
      "cardinality": {
        "field": "authors.keyword"
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête demande :

```text
Combien d’auteurs différents existe-t-il dans l’index ?
```

Elle utilise le champ :

```text
authors.keyword
```

car on veut compter des valeurs exactes.

## Rôle de `cardinality`

`cardinality` sert à compter le nombre de valeurs distinctes.

Exemple :

```text
Mary
John
Mary
Alice
John
```

Il y a 5 valeurs au total, mais seulement 3 valeurs distinctes :

```text
Mary
John
Alice
```

## Attention

Dans Elasticsearch, `cardinality` peut être une estimation, surtout sur de très grands volumes de données.

Mais dans la plupart des cas, elle est très utile pour une analyse rapide.

## Résumé simple

```text
cardinality = nombre de valeurs différentes
authors.keyword = auteurs exacts, non découpés
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>15. Modifier plusieurs documents avec <code>_update_by_query</code></strong></summary>

## Requête

```http
POST news/_update_by_query
{
  "script": {
    "source": "ctx._source.category = ctx._source.category.toUpperCase();",
    "lang": "painless"
  },
  "query": {
    "match_all": {}
  }
}
```

## Explication vulgarisée

Cette requête modifie tous les documents de l’index `news`.

Elle transforme le champ :

```text
category
```

en majuscules.

Exemple :

```text
Politics
```

devient :

```text
POLITICS
```

## Rôle de `_update_by_query`

`_update_by_query` veut dire :

```text
Mets à jour tous les documents qui correspondent à une requête.
```

Ici, la requête est :

```json
"match_all": {}
```

Cela veut dire :

```text
Tous les documents.
```

## Rôle du script

```json
"source": "ctx._source.category = ctx._source.category.toUpperCase();"
```

Cela veut dire :

```text
Prends la catégorie actuelle et remplace-la par sa version en majuscules.
```

## Rôle de `painless`

```json
"lang": "painless"
```

`Painless` est le langage de script utilisé par Elasticsearch.

Il permet de faire des transformations directement dans les documents.

## Attention importante

Cette requête est destructive dans le sens où elle modifie les documents existants.

Avant de l’exécuter, il faut être sûr que c’est voulu.

## Version plus prudente

Avant de modifier, on peut tester avec une recherche :

```http
GET news/_search
{
  "size": 5,
  "_source": ["category"],
  "query": {
    "match_all": {}
  }
}
```

Puis seulement après, exécuter `_update_by_query`.

## Résumé simple

```text
_update_by_query = modifier plusieurs documents
match_all = tous les documents
script = règle de modification
toUpperCase = convertir en majuscules
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

<details>
<summary><strong>16. Copier les données vers un nouvel index avec <code>_reindex</code></strong></summary>

## Étape 1 — Créer le nouvel index `news_v2`

```http
PUT news_v2
{
  "mappings": {
    "properties": {
      "date": {
        "type": "date",
        "format": "yyyy-MM-dd"
      },
      "category": {
        "type": "keyword"
      },
      "headline": {
        "type": "text",
        "analyzer": "english"
      },
      "short_description": {
        "type": "text",
        "analyzer": "english"
      },
      "authors": {
        "type": "keyword"
      },
      "link": {
        "type": "keyword"
      }
    }
  }
}
```

## Explication vulgarisée

Cette requête crée un nouvel index appelé :

```text
news_v2
```

Un index, c’est comme une nouvelle table ou une nouvelle collection de documents.

Ici, on définit aussi le type de chaque champ.

## Mapping expliqué simplement

| Champ               | Type      | Explication                     |
| ------------------- | --------- | ------------------------------- |
| `date`              | `date`    | Date de publication             |
| `category`          | `keyword` | Catégorie exacte                |
| `headline`          | `text`    | Titre analysé pour la recherche |
| `short_description` | `text`    | Description analysée            |
| `authors`           | `keyword` | Auteur exact                    |
| `link`              | `keyword` | Lien exact                      |

## Différence entre `text` et `keyword`

| Type      | Utilisation                            |
| --------- | -------------------------------------- |
| `text`    | Recherche textuelle intelligente       |
| `keyword` | Valeur exacte, filtre, tri, agrégation |

## Exemple

Pour un titre :

```text
President Obama speaks today
```

Avec `text`, Elasticsearch peut chercher :

```text
obama
president
speaks
```

Avec `keyword`, il considérerait toute la phrase comme une seule valeur exacte.

---

## Étape 2 — Copier les données de `news` vers `news_v2`

```http
POST _reindex
{
  "source": {
    "index": "news"
  },
  "dest": {
    "index": "news_v2"
  }
}
```

## Explication vulgarisée

Cette requête copie les documents de :

```text
news
```

vers :

```text
news_v2
```

C’est comme faire une copie de table.

## Pourquoi utiliser `_reindex` ?

Parce qu’on ne peut pas toujours modifier facilement le mapping d’un index existant.

Donc la méthode propre est souvent :

```text
1. Créer un nouvel index avec le bon mapping.
2. Copier les données dedans.
3. Utiliser le nouvel index.
```

---

## Étape 3 — Vérifier le nombre de documents

```http
GET news_v2/_count
```

## Explication vulgarisée

Cette requête vérifie combien de documents ont été copiés dans `news_v2`.

On peut comparer avec :

```http
GET news/_count
```

Si les deux nombres sont identiques, la copie s’est probablement bien déroulée.

## Résumé simple

```text
PUT news_v2 = créer un nouvel index
mappings = définir les types des champs
_reindex = copier les documents
_count = vérifier la copie
```

<p align="right"><a href="#top">↑ Retour en haut</a></p>

</details>

---

# Résumé général du chapitre

| Concept             | Explication simple                            |
| ------------------- | --------------------------------------------- |
| `_count`            | Compter les documents                         |
| `_search`           | Chercher ou analyser les documents            |
| `match`             | Recherche textuelle souple                    |
| `match_phrase`      | Recherche d’une phrase exacte                 |
| `multi_match`       | Recherche dans plusieurs champs               |
| `boost ^3`          | Donner plus d’importance à un champ           |
| `fuzziness`         | Accepter les fautes de frappe                 |
| `term`              | Chercher une valeur exacte                    |
| `terms`             | Chercher plusieurs valeurs exactes            |
| `prefix`            | Chercher ce qui commence par une valeur       |
| `bool`              | Combiner plusieurs conditions                 |
| `range`             | Chercher dans un intervalle                   |
| `sort`              | Trier les résultats                           |
| `search_after`      | Continuer après un résultat                   |
| `highlight`         | Surligner les mots trouvés                    |
| `aggs`              | Faire des statistiques                        |
| `terms aggregation` | Grouper par valeur                            |
| `top_hits`          | Afficher un document représentatif par groupe |
| `date_histogram`    | Grouper par date                              |
| `significant_text`  | Trouver les mots caractéristiques             |
| `cardinality`       | Compter les valeurs distinctes                |
| `_update_by_query`  | Modifier plusieurs documents                  |
| `_reindex`          | Copier vers un nouvel index                   |

---

# Mini conclusion

Dans ce chapitre, les requêtes ne servent pas seulement à chercher des articles. Elles montrent les grandes familles d’opérations dans Elasticsearch :

```text
chercher,
compter,
filtrer,
trier,
surligner,
analyser,
modifier,
copier.
```

La logique générale est la suivante :

```text
match / match_phrase / multi_match → rechercher du texte
term / terms / prefix → rechercher des valeurs exactes
bool / range → contrôler les conditions
aggs → produire des statistiques
update / reindex → modifier ou restructurer les données
```

<p align="center">
  <strong>Fin du chapitre 15 — Requêtes Elasticsearch dans Kibana Dev Tools</strong><br/>
  <a href="#top">↑ Retour en haut</a>
</p>
