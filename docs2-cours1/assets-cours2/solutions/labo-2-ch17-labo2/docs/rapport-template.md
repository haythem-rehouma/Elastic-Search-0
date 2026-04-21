<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Rapport Labo 2 — Plateforme de recherche d'actualités

## 1. Objectif et contexte

Mini-plateforme de recherche full-text sur **200 853** articles de presse (News Category Dataset v2, HuffPost, 2012-2018) avec Elasticsearch + Kibana.
Contrainte : utilisation **exclusive** du Query DSL.

## 2. Architecture déployée

```
Docker Compose (ch17-labo2)
├── ES 8.13.4  (single-node, sans sécurité, 1 Go heap)
└── Kibana 8.13.4
```

| Composant     | Version  | Rôle                                  |
| ------------- | -------- | ------------------------------------- |
| Elasticsearch | 8.13.4   | Stockage + moteur de recherche        |
| Kibana        | 8.13.4   | UI + Dev Tools + Dashboards           |
| Docker        | 27.x     | Orchestration locale                  |

## 3. Modélisation (mapping)

| Choix                                  | Justification                                         |
| -------------------------------------- | ----------------------------------------------------- |
| `date` typé `date`                      | Active `range`, `date_histogram`, time picker        |
| `text` + sous-champ `.keyword`          | Full-text + agrégations exactes                      |
| `category.keyword_lower` (normalizer)   | Recherche term insensible à la casse                 |
| `link` typé `keyword`                   | URL = identifiant exact, pas de full-text inutile    |
| `replicas: 0` + `refresh_interval: -1` à l'import | Performance (×3 à ×5)                      |

Mapping complet : [`mappings/news.mapping.json`](../mappings/news.mapping.json).

## 4. Pipeline d'ingestion

| Étape                   | Détail                                                  |
| ----------------------- | ------------------------------------------------------- |
| Format source           | JSONL (1 article par ligne)                             |
| Conversion → NDJSON     | `awk` qui prépend `{"index":{"_index":"news"}}`         |
| Découpage               | `split -l 5000` → ~81 chunks                            |
| Boucle                  | Bash `for` sur les chunks, `--data-binary`              |
| Settings post-import    | `replicas: 1`, `refresh_interval: 1s`, `_refresh`       |
| Compte final            | **200 853 documents**, `_cluster/health: green`         |

Script complet : [`scripts/01-up-and-import.sh`](../scripts/01-up-and-import.sh).

## 5. Les 10 requêtes DSL (synthèse)

| #   | Objectif                  | Outil DSL utilisé                          | Fichier                                                      |
| --- | ------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| R1  | Derniers articles         | `sort` + `_source`                         | [`R01-tri-date.json`](../queries/R01-tri-date.json)          |
| R2  | Pagination scalable       | `search_after` + sort à 2 clés             | [`R02-search-after.json`](../queries/R02-search-after.json)  |
| R3  | Plein texte multi-champ   | `multi_match` + boost `headline^3`         | [`R03-multi-match-boost.json`](../queries/R03-multi-match-boost.json) |
| R4  | Phrase exacte             | `match_phrase`                             | [`R04-match-phrase.json`](../queries/R04-match-phrase.json)  |
| R5  | Tolérance aux fautes      | `match` + `fuzziness: AUTO`                | [`R05-fuzzy.json`](../queries/R05-fuzzy.json)                |
| R6  | Filtres complexes         | `bool` (must / filter / must_not)          | [`R06-bool-trump.json`](../queries/R06-bool-trump.json)      |
| R7  | Boost catégoriel          | `function_score` + weight                  | [`R07-function-score.json`](../queries/R07-function-score.json)|
| R8  | Highlight                 | `highlight` + `pre_tags`/`post_tags`       | [`R08-highlight.json`](../queries/R08-highlight.json)        |
| R9  | KPI catégories            | `terms` agg + sub-`top_hits`               | [`R09-aggs-top-hits.json`](../queries/R09-aggs-top-hits.json)|
| R10 | Série temporelle          | `date_histogram` + sub-`terms`             | [`R10-date-histogram.json`](../queries/R10-date-histogram.json)|

Toutes exécutables d'un coup : `bash scripts/02-run-all-queries.sh` → résultats dans `results/`.

## 6. Dashboard Kibana

[Insérer ici une capture du dashboard]

4 visualisations :
1. **Pie** : Top 10 catégories (`terms` sur `category.keyword`)
2. **Bar vertical** : Articles par jour (`date_histogram`), splittés par catégorie
3. **Tag cloud** : Mots saillants des titres
4. **Data table** : Top auteurs par catégorie (sub-`top_hits`)

## 7. Difficultés rencontrées

| Difficulté                                  | Solution                              |
| ------------------------------------------- | ------------------------------------- |
| Limite 10 000 hits dans `_search`           | `track_total_hits: true` ou `_count`  |
| Aggrégation vide sur `category`             | Cibler `category.keyword`             |
| Payload `_bulk` > 100 Mo                    | Split en chunks de 5000 lignes        |
| (autre…)                                    |                                       |

## 8. Conclusion

Le pipeline est entièrement reproductible : un `bash scripts/01-up-and-import.sh`
suffit à recréer toute l'infrastructure et l'index, à partir d'un poste vierge ayant uniquement Docker.

Les 10 requêtes couvrent tous les patterns DSL essentiels : **tri**, **filtres bool**, **boost**, **agrégations imbriquées**, **highlight**, **search_after**.

Prochaines étapes : analyzers FR/EN, `completion suggester` (autocomplétion), snapshot/restore, alias d'index.


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
