<a id="top"></a>

# Projet ch17 — Labo 2 (livrable complet)

Tout pour livrer le Labo 2 : compose isolé, mapping, ingestion automatisée, **10 requêtes DSL** versionnées, runner qui les exécute toutes, et **template de rapport** prérempli.

## En 2 commandes

```bash
bash scripts/01-up-and-import.sh        # ~5 min : stack + import 200 853 docs
bash scripts/02-run-all-queries.sh      # joue R01..R10, écrit results/*.json
```

→ Index `news` opérationnel sur http://localhost:9200, Kibana sur http://localhost:5601.

Sous Windows pur, version PowerShell pour les requêtes :
```powershell
.\scripts\02-run-all-queries.ps1
```

## Arborescence

```
ch17-labo2/
├── docker-compose.yml
├── mappings/
│   ├── news.mapping.json           <- mapping initial (replicas:0, refresh:-1)
│   └── news.post-import.json        <- réactivation post-ingestion
├── data/                            <- créé par scripts/01 (ignoré .git)
├── queries/
│   ├── R01-tri-date.json
│   ├── R02-search-after.json
│   ├── R03-multi-match-boost.json
│   ├── R04-match-phrase.json
│   ├── R05-fuzzy.json
│   ├── R06-bool-trump.json
│   ├── R07-function-score.json
│   ├── R08-highlight.json
│   ├── R09-aggs-top-hits.json
│   └── R10-date-histogram.json
├── scripts/
│   ├── 01-up-and-import.sh          <- pipeline complet
│   ├── 02-run-all-queries.sh
│   └── 02-run-all-queries.ps1
├── results/                         <- créé par scripts/02 (sorties JSON)
├── docs/
│   └── rapport-template.md          <- canevas de rapport prérempli
└── README.md
```

## Les 10 requêtes — vue d'ensemble

| # | Requête                  | Fichier                                  | Démontre                          |
| - | ------------------------ | ---------------------------------------- | --------------------------------- |
| 1 | Derniers articles        | `R01-tri-date.json`                      | `sort` + `_source`                |
| 2 | Pagination scalable      | `R02-search-after.json`                  | `search_after` (+ sort 2 clés)    |
| 3 | Plein texte boosté       | `R03-multi-match-boost.json`             | `multi_match` + `headline^3`      |
| 4 | Phrase exacte            | `R04-match-phrase.json`                  | `match_phrase`                    |
| 5 | Tolérance fautes         | `R05-fuzzy.json`                         | `fuzziness: AUTO`                 |
| 6 | Filtres complexes        | `R06-bool-trump.json`                    | `bool`: must/filter/must_not      |
| 7 | Boost catégoriel         | `R07-function-score.json`                | `function_score`                  |
| 8 | Highlight                | `R08-highlight.json`                     | `<mark>` autour des termes        |
| 9 | KPI catégories           | `R09-aggs-top-hits.json`                 | terms agg + top_hits              |
| 10| Série temporelle         | `R10-date-histogram.json`                | `date_histogram` + sub-terms      |

## Livrable

1. **Code** : ce dossier complet (compose + mapping + scripts + queries).
2. **Sorties** : `results/R*.json` après `02-run-all-queries.sh`.
3. **Dashboard** : 4 visualisations Kibana (à créer manuellement, captures dans le rapport).
4. **Rapport** : compléter [`docs/rapport-template.md`](./docs/rapport-template.md), exporter en PDF.

## Cleanup

```bash
docker compose down -v
rm -rf data/news.bulk.ndjson data/chunks results
```

## Documentation détaillée

[`../solutions-17-labo2.md`](../solutions-17-labo2.md)

<p align="right"><a href="#top">Retour en haut</a></p>
