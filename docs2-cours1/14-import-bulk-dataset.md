<a id="top"></a>

# 14 — Import d'un dataset volumineux (Bulk API)

> **Type** : Pratique · **Pré-requis** : [12 — Commandes ES](./12-commandes-base-elasticsearch.md), [13 — CRUD Kibana](./13-crud-pedagogique-kibana.md)
>
> **Dataset utilisé dans ce chapitre** : `News_Category_Dataset_v2.json` (~84 Mo, ~200 000 articles de presse) disponible dans [`assets-cours2/`](./assets-cours2/). Si vous avez les `.zip`, dézippez-les d'abord :
>
> ```bash
> cd assets-cours2/
> unzip archiveJSON.zip   # ou archiveCSV.zip
> ```

## Table des matières

- [1. Pourquoi l'API `_bulk` ?](#1-pourquoi-lapi-_bulk-)
- [2. Format NDJSON](#2-format-ndjson)
- [3. Préparer le fichier](#3-préparer-le-fichier)
- [4. Méthode A — `curl` direct](#4-méthode-a--curl-direct)
- [5. Méthode B — gzip streaming](#5-méthode-b--gzip-streaming)
- [6. Méthode C — Python](#6-méthode-c--python)
- [7. Méthode D — split + parallèle](#7-méthode-d--split--parallèle)
- [8. Optimisations pour gros volumes](#8-optimisations-pour-gros-volumes)
- [9. Erreurs fréquentes](#9-erreurs-fréquentes)
- [10. Checklist "import massif"](#10-checklist-import-massif)

---

## 1. Pourquoi l'API `_bulk` ?

Importer 200 000 documents un par un avec `POST /_doc` prendrait des heures (chaque requête HTTP a un overhead).

L'API **`_bulk`** permet d'envoyer des **paquets** de documents en une seule requête HTTP : on passe de **200 000 requêtes** à **~100 requêtes** de 2 000 docs chacune.

| Caractéristique | Valeur conseillée               |
| --------------- | ------------------------------- |
| Taille payload  | ~5–15 Mo par requête            |
| Nombre de docs  | 1 000 à 5 000 par lot           |
| Limite HTTP     | 100 Mo (`http.max_content_length`) — restez bien en dessous |

---

## 2. Format NDJSON

**NDJSON** = **N**ewline **D**elimited **JSON** : un objet JSON par ligne, **pas** de tableau `[…]`, **pas** de virgules entre objets.

```
{"id":1,"titre":"A"}
{"id":2,"titre":"B"}
{"id":3,"titre":"C"}
```

L'API `_bulk` exige un format particulier : **paires** de lignes alternant **action** et **document**.

```
{"index":{"_index":"news"}}
{"category":"POLITICS","headline":"Titre A","date":"2018-05-26"}
{"index":{"_index":"news"}}
{"category":"WORLD","headline":"Titre B","date":"2018-05-27"}
```

| Action courante  | Effet                                              |
| ---------------- | -------------------------------------------------- |
| `{"index": {…}}` | Indexe (crée ou écrase si même `_id`)              |
| `{"create": {…}}`| Crée seulement (échoue si `_id` existe déjà)       |
| `{"update": {…}}`| Mise à jour partielle                              |
| `{"delete": {…}}`| Suppression                                        |

> **Erreurs classiques** : crochets `[]` autour, virgules entre objets, JSON multilignes, oubli du newline final.

---

## 3. Préparer le fichier

### Source : `raw.jsonl` (un doc par ligne)

```bash
cat > raw.jsonl <<'JSON'
{"category":"POLITICS","headline":"Ryan Zinke...","date":"2018-05-26"}
{"category":"POLITICS","headline":"Trump's Scottish Golf...","date":"2018-05-26"}
JSON
```

### Vérifier le JSON ligne à ligne (`jq`)

```bash
nl -ba raw.jsonl | while IFS= read -r line; do
  num="${line%%$'\t'*}"; json="${line#*$'\t'}"
  echo "$json" | jq -e . >/dev/null 2>&1 || echo "Ligne $num invalide"
done
```

### Nettoyer les retours Windows

```bash
sed -i 's/\r$//' raw.jsonl
```

### Transformer en NDJSON pour `_bulk`

```bash
awk '{print "{\"index\":{\"_index\":\"news\"}}"; print}' raw.jsonl > news.bulk.ndjson
wc -l raw.jsonl news.bulk.ndjson   # le second doit avoir 2× plus de lignes
```

### Variante : avec `_id` déterministe (idempotent)

```bash
awk '
  {
    cmd = "printf %s \"" $0 "\" | sha1sum | cut -d\" \" -f1";
    cmd | getline h; close(cmd);
    print "{\"index\":{\"_index\":\"news\",\"_id\":\"" h "\"}}";
    print $0
  }
' raw.jsonl > news.bulk.withid.ndjson
```

---

## 4. Méthode A — `curl` direct

```bash
curl -s -H 'Content-Type: application/x-ndjson' \
     -X POST 'http://localhost:9200/_bulk?pretty' \
     --data-binary @news.bulk.ndjson | jq '.errors'
# → false attendu

curl -s 'http://localhost:9200/news/_count?pretty'
```

---

## 5. Méthode B — gzip streaming

```bash
gzip -c news.bulk.ndjson | \
curl -s -H 'Content-Type: application/x-ndjson' \
       -H 'Content-Encoding: gzip' \
       -X POST 'http://localhost:9200/_bulk?pretty' \
       --data-binary @- | jq '.errors'
```

> Sur de gros fichiers, **gzip réduit le temps réseau de 60–80 %**.

---

## 6. Méthode C — Python

```bash
pip install elasticsearch==8.* tqdm
```

```python
from elasticsearch import Elasticsearch, helpers
from tqdm import tqdm
import json

ES = Elasticsearch("http://localhost:9200")
INDEX = "news"

def gen_actions(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            yield {"_index": INDEX, "_source": json.loads(line)}

if __name__ == "__main__":
    helpers.bulk(ES, gen_actions("raw.jsonl"), chunk_size=2000, request_timeout=120)
```

> Avantages : barre de progression, gestion fine des erreurs, transformations à la volée.

---

## 7. Méthode D — split + parallèle

```bash
# Découper en morceaux de 5 000 lignes (= 2 500 docs)
mkdir -p chunks
split -l 5000 --numeric-suffixes=1 --additional-suffix=.ndjson \
      news.bulk.ndjson chunks/part_

# Import séquentiel
for f in chunks/part_*; do
  echo "Import: $f"
  curl -s -H 'Content-Type: application/x-ndjson' \
       -X POST 'http://localhost:9200/_bulk' \
       --data-binary @"$f" | jq '.errors'
done

# Variante parallèle (modeste : 2 jobs)
sudo apt-get install -y parallel
ls chunks/part_* | parallel -j2 '
  curl -s -H "Content-Type: application/x-ndjson" \
       -X POST "http://localhost:9200/_bulk" --data-binary @{} \
  | jq -r ".errors"
'
```

> Si vous voyez `429 Too Many Requests` → réduire `-j` ou la taille des chunks.

---

## 8. Optimisations pour gros volumes

### Avant l'import

```bash
curl -X PUT 'http://localhost:9200/news/_settings' -H 'Content-Type: application/json' -d '{
  "index": {
    "number_of_replicas": 0,
    "refresh_interval": "-1"
  }
}'
```

### Après l'import

```bash
curl -X PUT 'http://localhost:9200/news/_settings' -H 'Content-Type: application/json' -d '{
  "index": {
    "number_of_replicas": 1,
    "refresh_interval": "1s"
  }
}'
curl -X POST 'http://localhost:9200/news/_refresh'
```

### Optionnel : `_forcemerge` après import (hors charge)

```bash
curl -X POST 'http://localhost:9200/news/_forcemerge?max_num_segments=1&pretty'
```

### Suivi pendant l'import

```bash
curl -s 'http://localhost:9200/news/_count?pretty'
curl -s 'http://localhost:9200/_tasks?detailed=true&actions=*bulk*&pretty'
curl -s 'http://localhost:9200/_cat/thread_pool?v'
```

---

## 9. Erreurs fréquentes

| Symptôme                                  | Cause / Fix                                                  |
| ----------------------------------------- | ------------------------------------------------------------ |
| `"errors": true` dans la réponse          | Une ligne JSON invalide ou un champ `date` non conforme. Filtrer avec `jq` les erreurs. |
| `413 Request Entity Too Large`            | Payload > 100 Mo → split + chunks plus petits, ou gzip       |
| `429 Too Many Requests`                   | Trop de parallélisme → réduire `-j`                          |
| `Timeout`                                 | `?timeout=2m` ou réduire la taille des lots                  |
| Date refusée                              | Mapping attend `yyyy-MM-dd` → reformater avec `jq`           |
| Doublons                                  | Ajouter un `_id` déterministe (cf. §3)                       |

### Voir les erreurs `_bulk` rapidement

```bash
curl -s -H 'Content-Type: application/x-ndjson' \
     -X POST 'http://localhost:9200/_bulk' \
     --data-binary @news.bulk.ndjson \
| jq '.items[] | select(.index.error != null) | .index.error'
```

---

## 10. Checklist "import massif"

1. Créer l'index avec **mapping correct**.
2. Mettre `number_of_replicas: 0` et `refresh_interval: -1`.
3. Choisir une méthode (split + curl, gzip, Python, Logstash).
4. Tester sur **4 lignes** d'abord.
5. Lancer en **petits lots**, surveiller `_count` + `_tasks`.
6. Remettre `replicas: 1` + `refresh_interval: 1s` + `_refresh`.
7. (Option) `_forcemerge` hors charge.
8. **Snapshot** une fois le corpus chargé.

<p align="right"><a href="#top">↑ Retour en haut</a></p>
