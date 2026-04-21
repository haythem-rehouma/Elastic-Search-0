<a id="top"></a>

# Projet ch15 — Requêtes Elasticsearch intermédiaires

Toutes les requêtes du chapitre 15 prêtes à exécuter, en deux formats :
- **fichiers JSON** isolés dans `queries/` (pour `curl` ou clients programmatiques) ;
- **snippet Kibana Dev Tools** complet dans `console/all-queries.txt`.

## Pré-requis : index `news` chargé

Le plus simple : utiliser la stack du **projet ch14** (qui charge les 200 853 docs) :

```bash
cd ../pratique-08-ch14-bulk-import
bash scripts/run-all.sh                # ou run-all.ps1
```

Puis revenir ici pour les requêtes. (Les ports sont identiques : 9200/5601.)

## Exécuter une requête

### Via Kibana Dev Tools (recommandé)

1. http://localhost:5601/app/dev_tools#/console
2. Ouvrir [`console/all-queries.txt`](./console/all-queries.txt), copier-coller dans la console
3. Placer le curseur sur **une** requête → `Ctrl + Entrée`

### Via curl

```bash
bash run-query.sh 02-precision-vs-rappel.json
```

(La sortie JSON est imprimée à l'écran.)

## Catalogue des requêtes JSON

| Fichier                                     | Démontre                                            |
| ------------------------------------------- | --------------------------------------------------- |
| `queries/01-count-track-total.json`         | Compter exactement (>10 000) avec `track_total_hits`|
| `queries/02-precision-vs-rappel.json`       | OR vs AND vs `minimum_should_match` (3 variantes)   |
| `queries/03-bool-complet.json`              | `bool` avec must / filter / must_not / should       |
| `queries/04-aggs-categories.json`           | `terms` agg + sous-`top_hits`                       |
| `queries/05-date-histogram.json`            | `date_histogram` avec sous-aggregation              |
| `queries/06-significant-text.json`          | Termes saillants pour POLITICS                      |

→ Le snippet console ajoute fuzzy, range, search_after, highlight, cardinality, `_update_by_query`, `_reindex`.

## Documentation détaillée

[`../pratique-09-solutions-requetes-intermediaires.md`](../pratique-09-solutions-requetes-intermediaires.md)

<p align="right"><a href="#top">Retour en haut</a></p>
