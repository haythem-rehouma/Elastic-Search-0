<a id="top"></a>

# Solutions — Chapitre 14 : Import du dataset News (`_bulk`) de A à Z

> **Lien chapitre source** : [`14-import-bulk-dataset.md`](../../14-import-bulk-dataset.md)
> **Pré-requis** : [Setup A à Z](./00-setup-complet-a-z.md) — Elasticsearch healthy sur http://localhost:9200.
> **Dataset** : [`News_Category_Dataset_v2.json`](../News_Category_Dataset_v2.json) — ~84 Mo, **200 853 articles**.

## Table des matières

- [0. Pré-flight](#0-pré-flight)
- [1. Localiser le dataset (et le décompresser si besoin)](#1-localiser-le-dataset-et-le-décompresser-si-besoin)
- [2. Inspecter et nettoyer le fichier brut](#2-inspecter-et-nettoyer-le-fichier-brut)
- [3. Créer l'index `news` avec mapping correct](#3-créer-lindex-news-avec-mapping-correct)
- [4. Optimisations AVANT import](#4-optimisations-avant-import)
- [5. Convertir le JSON en NDJSON pour `_bulk`](#5-convertir-le-json-en-ndjson-pour-_bulk)
- [6. Méthode A — `curl` direct (petits volumes)](#6-méthode-a--curl-direct-petits-volumes)
- [7. Méthode B — split + boucle (recommandée pour 84 Mo)](#7-méthode-b--split--boucle-recommandée-pour-84-mo)
- [8. Méthode C — gzip streaming](#8-méthode-c--gzip-streaming)
- [9. Méthode D — Python `helpers.bulk`](#9-méthode-d--python-helpersbulk)
- [10. Réactiver les paramètres APRÈS import](#10-réactiver-les-paramètres-après-import)
- [11. Vérifications de cohérence](#11-vérifications-de-cohérence)
- [12. Cas d'erreurs résolus](#12-cas-derreurs-résolus)
- [13. Variante Windows (sans WSL)](#13-variante-windows-sans-wsl)

---

## 0. Pré-flight

```bash
docker compose ps spotify-elasticsearch
curl -s 'http://localhost:9200/_cluster/health?pretty'
# status doit être green ou yellow

# Outils utiles
which jq awk sed split    # Linux/macOS
# Sur Windows : préférez WSL Ubuntu, ou utiliser PowerShell (cf. § 13)
```

---

## 1. Localiser le dataset (et le décompresser si besoin)

```bash
cd docs2-cours1/assets-cours2/
ls -lh
# News_Category_Dataset_v2.json    ~84M
# archiveJSON.zip                  ~27M
# archiveCSV.zip                   ~22M
```

Si vous n'avez que les `.zip` :

```bash
unzip archiveJSON.zip                       # → News_Category_Dataset_v2.json
# (ou)
unzip archiveCSV.zip
```

> Pour la suite, on travaille dans un dossier de travail séparé pour ne pas polluer `assets-cours2/` :

```bash
mkdir -p ~/news-import && cp News_Category_Dataset_v2.json ~/news-import/raw.jsonl
cd ~/news-import
```

---

## 2. Inspecter et nettoyer le fichier brut

```bash
# Aperçu des premières lignes
head -n 2 raw.jsonl

# Nombre de lignes (= nombre d'articles attendu : ~200 853)
wc -l raw.jsonl

# Vérifier que c'est bien de l'UTF-8
file -bi raw.jsonl
# → application/json; charset=utf-8

# Nettoyer les CRLF Windows si nécessaire
sed -i 's/\r$//' raw.jsonl

# Validation ligne à ligne (cherche les lignes JSON invalides)
nl -ba raw.jsonl | while IFS= read -r line; do
  num="${line%%$'\t'*}"; json="${line#*$'\t'}"
  echo "$json" | jq -e . >/dev/null 2>&1 || echo "Ligne $num INVALIDE"
done
```

> Sur ce dataset officiel : 0 ligne invalide. Si vous en trouvez : ouvrez la ligne avec `sed -n '<num>p' raw.jsonl` pour corriger.

---

## 3. Créer l'index `news` avec mapping correct

```bash
# Nettoyer si déjà existant
curl -s -X DELETE 'http://localhost:9200/news'

# Créer avec mapping
curl -s -X PUT 'http://localhost:9200/news' \
  -H 'Content-Type: application/json' -d '{
  "mappings": {
    "properties": {
      "date":     { "type": "date", "format": "yyyy-MM-dd" },
      "category": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword" } }
      },
      "headline":          { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } } },
      "authors":           { "type": "text", "fields": { "keyword": { "type": "keyword" } } },
      "short_description": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } } },
      "link":              { "type": "keyword" }
    }
  }
}'

# Vérifier
curl -s 'http://localhost:9200/news/_mapping?pretty'
```

| Choix de mapping       | Pourquoi                                                                |
| ---------------------- | ----------------------------------------------------------------------- |
| `date` typé `date`     | Active `range`, `date_histogram`, et le time picker Kibana              |
| `text` + `keyword`     | `text` pour la recherche full-text, `.keyword` pour `term`/`aggs`/`sort`|
| `ignore_above: 256`    | Évite que des titres trop longs explosent l'index                       |
| `link` en `keyword`    | URL = identifiant exact, jamais de full-text dessus                     |

---

## 4. Optimisations AVANT import

```bash
curl -s -X PUT 'http://localhost:9200/news/_settings' \
  -H 'Content-Type: application/json' -d '{
  "index": {
    "number_of_replicas": 0,
    "refresh_interval":   "-1"
  }
}'
```

| Setting                      | Effet pendant l'import                                  |
| ---------------------------- | ------------------------------------------------------- |
| `number_of_replicas: 0`      | Pas de double écriture pour la réplique                 |
| `refresh_interval: -1`       | Pas de refresh forcé toutes les secondes                |

> Combinés, ces deux settings **divisent le temps d'import par 3 à 5**.

---

## 5. Convertir le JSON en NDJSON pour `_bulk`

L'API `_bulk` exige des **paires** de lignes : `{action}` puis `{document}`.

```bash
awk '{ print "{\"index\":{\"_index\":\"news\"}}"; print }' raw.jsonl > news.bulk.ndjson

wc -l raw.jsonl news.bulk.ndjson
# raw.jsonl       : 200853
# news.bulk.ndjson: 401706    (= 2 × 200853)

head -n 4 news.bulk.ndjson
```

Sortie attendue :

```
{"index":{"_index":"news"}}
{"category":"CRIME","headline":"There Were 2 Mass Shootings ...","authors":"Melissa Jeltsen", ...}
{"index":{"_index":"news"}}
{"category":"ENTERTAINMENT","headline":"Will Smith Joins Diplo And Nicky Jam ...", ...}
```

### Variante : `_id` déterministe (rejouer l'import = idempotent)

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

→ rejouer l'import 2 fois ne crée **aucun doublon** (le hash sert d'id stable).

---

## 6. Méthode A — `curl` direct (petits volumes)

```bash
# Test sur 4 lignes (= 2 docs)
head -n 4 news.bulk.ndjson > test.bulk.ndjson

curl -s -H 'Content-Type: application/x-ndjson' \
     -X POST 'http://localhost:9200/_bulk?pretty' \
     --data-binary @test.bulk.ndjson | jq '.errors'
# Attendu : false
```

**Tout d'un coup** (84 Mo, possible mais à la limite — préférez § 7) :

```bash
curl -s -H 'Content-Type: application/x-ndjson' \
     -X POST 'http://localhost:9200/_bulk?pretty' \
     --data-binary @news.bulk.ndjson > /tmp/bulk_response.json

jq '.errors, .took' /tmp/bulk_response.json
# Attendu : false, <ms>
```

> Si vous obtenez `413 Request Entity Too Large` → passez à la méthode B.

---

## 7. Méthode B — split + boucle (recommandée pour 84 Mo)

```bash
mkdir -p chunks
split -l 5000 --numeric-suffixes=1 --additional-suffix=.ndjson \
      news.bulk.ndjson chunks/part_

ls chunks/ | wc -l
# Environ 81 chunks (401706 / 5000 ≈ 81)
```

Boucle séquentielle avec progression :

```bash
total=$(ls chunks/part_*.ndjson | wc -l)
i=0
for f in chunks/part_*.ndjson; do
  i=$((i+1))
  errors=$(curl -s -H 'Content-Type: application/x-ndjson' \
       -X POST 'http://localhost:9200/_bulk' \
       --data-binary @"$f" | jq -r '.errors')
  echo "[$i/$total] $f → errors: $errors"
done
```

Sortie attendue :

```
[1/81]  chunks/part_01.ndjson → errors: false
[2/81]  chunks/part_02.ndjson → errors: false
...
[81/81] chunks/part_81.ndjson → errors: false
```

> Comptez **3 à 8 minutes** sur une machine moyenne (selon RAM allouée à ES).

### Suivre l'import en parallèle (autre terminal)

```bash
watch -n 5 "curl -s 'http://localhost:9200/news/_count?pretty' | jq '.count'"
```

---

## 8. Méthode C — gzip streaming

Très utile sur connexion lente / API distante : compresse à la volée (~70 % de gain réseau).

```bash
gzip -c news.bulk.ndjson | \
  curl -s -H 'Content-Type: application/x-ndjson' \
       -H 'Content-Encoding: gzip' \
       -X POST 'http://localhost:9200/_bulk?pretty' \
       --data-binary @- | jq '.errors, .took'
```

---

## 9. Méthode D — Python `helpers.bulk`

```bash
pip install elasticsearch==8.13.0 tqdm==4.66.4
```

`bulk_import.py` :

```python
import json
from elasticsearch import Elasticsearch, helpers
from tqdm import tqdm

ES_URL = "http://localhost:9200"
INDEX  = "news"
PATH   = "raw.jsonl"
CHUNK  = 2000

es = Elasticsearch(ES_URL, request_timeout=120)

def gen_actions(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            yield {"_index": INDEX, "_source": json.loads(line)}

if __name__ == "__main__":
    success, errors = 0, 0
    pbar = tqdm(unit=" docs")
    for ok, item in helpers.streaming_bulk(es, gen_actions(PATH),
                                            chunk_size=CHUNK,
                                            request_timeout=120,
                                            raise_on_error=False):
        if ok:
            success += 1
        else:
            errors += 1
        pbar.update(1)
    pbar.close()
    print(f"\nTotal : {success} OK, {errors} erreurs")
```

```bash
python bulk_import.py
```

> Avantages : barre de progression, gestion fine des erreurs, transformations à la volée si besoin.

---

## 10. Réactiver les paramètres APRÈS import

```bash
curl -s -X PUT 'http://localhost:9200/news/_settings' \
  -H 'Content-Type: application/json' -d '{
  "index": {
    "number_of_replicas": 1,
    "refresh_interval":   "1s"
  }
}'

curl -s -X POST 'http://localhost:9200/news/_refresh'

# Optionnel : compacter les segments hors charge (long, à faire la nuit)
curl -s -X POST 'http://localhost:9200/news/_forcemerge?max_num_segments=1&pretty'
```

---

## 11. Vérifications de cohérence

```bash
# Compte total
curl -s 'http://localhost:9200/news/_count?pretty'
# Attendu : "count": 200853

# Idem via Kibana DSL :
#   GET news/_search { "track_total_hits": true }
#   → "total": { "value": 200853, "relation": "eq" }

# Top 5 catégories
curl -s 'http://localhost:9200/news/_search?pretty' \
  -H 'Content-Type: application/json' -d '{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": { "field": "category.keyword", "size": 5 }
    }
  }
}'

# Plage de dates
curl -s 'http://localhost:9200/news/_search?pretty' \
  -H 'Content-Type: application/json' -d '{
  "size": 0,
  "aggs": {
    "min_date": { "min": { "field": "date" } },
    "max_date": { "max": { "field": "date" } }
  }
}'
# Attendu : 2012 → 2018 environ
```

Sortie agrégation attendue (top 5 typique) :

| category       | doc_count |
| -------------- | --------: |
| POLITICS       |    32 739 |
| WELLNESS       |    17 827 |
| ENTERTAINMENT  |    16 058 |
| TRAVEL         |     9 887 |
| STYLE & BEAUTY |     9 649 |

---

## 12. Cas d'erreurs résolus

| Symptôme                                        | Cause                                                | Correctif                                                    |
| ----------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| `"errors": true` dans `_bulk`                   | Format date refusé / champ inattendu                 | `jq '.items[] \| select(.index.error != null) \| .index.error'` pour voir, puis corriger |
| `413 Request Entity Too Large`                  | Payload > `http.max_content_length` (100 Mo)         | `split -l 5000` puis boucle                                  |
| `429 Too Many Requests`                         | Trop de parallélisme                                 | Réduire `-j` (parallel) ou augmenter `chunk_size`            |
| `mapper_parsing_exception` sur `date`           | Format ≠ mapping                                     | Conformer ou `"format":"yyyy-MM-dd\|\|strict_date_optional_time"` |
| `aggs` retourne 0 buckets                       | `terms` sur champ `text` non-keyword                 | Cibler `category.keyword`, pas `category`                    |
| Doublons après second import                    | `_id` non spécifié                                   | Utiliser la variante `_id` déterministe (§ 5)                |
| Compte stagne à 10 000 dans `_search`           | Limite `track_total_hits` par défaut                 | Ajouter `"track_total_hits": true` ou `_count` à la place    |

### Voir les détails d'erreur `_bulk`

```bash
curl -s -H 'Content-Type: application/x-ndjson' \
     -X POST 'http://localhost:9200/_bulk' \
     --data-binary @news.bulk.ndjson \
| jq '.items[] | select(.index.error != null) | .index.error' | head -20
```

---

## 13. Variante Windows (sans WSL)

PowerShell n'a ni `awk` ni `sed`, on remplace par du PowerShell natif :

```powershell
$src = "C:\elasticsearch-1\docs2-cours1\assets-cours2\News_Category_Dataset_v2.json"
$dst = "C:\elasticsearch-1\news.bulk.ndjson"
$sw  = [System.IO.StreamWriter]::new($dst, $false, [System.Text.UTF8Encoding]::new($false))
$action = '{"index":{"_index":"news"}}'
Get-Content $src | ForEach-Object {
  $sw.WriteLine($action)
  $sw.WriteLine($_)
}
$sw.Close()

# Vérifier (doit être 2 × 200853 ≈ 401706)
(Get-Content $dst | Measure-Object -Line).Lines

# Découper en chunks de 5000 lignes
$chunkDir = "C:\elasticsearch-1\chunks"
New-Item -ItemType Directory -Force -Path $chunkDir | Out-Null
$i = 0; $part = 1
$out = $null
Get-Content $dst | ForEach-Object {
  if ($i % 5000 -eq 0) {
    if ($out) { $out.Close() }
    $f = Join-Path $chunkDir ("part_{0:D3}.ndjson" -f $part)
    $out = [System.IO.StreamWriter]::new($f, $false, [System.Text.UTF8Encoding]::new($false))
    $part++
  }
  $out.WriteLine($_); $i++
}
$out.Close()

# Boucle d'import
Get-ChildItem "$chunkDir\part_*.ndjson" | ForEach-Object {
  $resp = Invoke-RestMethod -Method Post `
            -Uri 'http://localhost:9200/_bulk' `
            -ContentType 'application/x-ndjson' `
            -InFile $_.FullName
  Write-Host "$($_.Name) → errors: $($resp.errors)"
}
```

> **Conseil** : sur Windows, l'expérience est nettement meilleure dans **WSL Ubuntu** (toutes les commandes Linux ci-dessus marchent telles quelles).

<p align="right"><a href="#top">Retour en haut</a></p>
