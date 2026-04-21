<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Projet ch16 — KQL vs ES|QL vs Query DSL (côte à côte)

Mêmes besoins, **3 langages** : on voit immédiatement quand utiliser quoi.

## Pré-requis

Index `news` chargé avec 200 853 docs → utilisez la stack **ch14** ou jouez `bash ../pratique-08-ch14-bulk-import/scripts/run-all.sh` après avoir démarré la stack ci-dessous.

## Démarrage

```bash
docker compose up -d
```

→ Kibana : http://localhost:5601

## Snippets côte-à-côte

| Fichier                                                       | Où l'exécuter                          |
| ------------------------------------------------------------- | -------------------------------------- |
| [`console/01-kql-discover.txt`](./console/01-kql-discover.txt)| Kibana → **Discover** (barre de recherche) |
| [`console/02-esql-devtools.txt`](./console/02-esql-devtools.txt)| Kibana → **Dev Tools** (`POST _query`)|
| [`console/03-dsl-devtools.txt`](./console/03-dsl-devtools.txt)| Kibana → **Dev Tools** (`GET news/_search`) |

## Quand utiliser quoi ?

| Critère                                | Recommandation               |
| -------------------------------------- | ---------------------------- |
| Filtre/exploration interactif (Discover) | **KQL**                    |
| Rapport tabulaire SQL-like             | **ES\|QL**                   |
| Application backend (Python, Node)     | **DSL** via client officiel  |
| Boost, highlight, function_score, search_after | **DSL** uniquement   |
| Aggrégations imbriquées profondes      | **DSL** principalement       |

## Documentation détaillée

[`../pratique-10-solutions-kql-esql-dsl.md`](../pratique-10-solutions-kql-esql-dsl.md)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
