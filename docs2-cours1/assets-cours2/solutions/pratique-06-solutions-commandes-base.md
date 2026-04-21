<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Solutions — Chapitre 12 : commandes de base d'Elasticsearch

> **Lien chapitre source** : [`12-commandes-base-elasticsearch.md`](../../12-commandes-base-elasticsearch.md)
> **Pré-requis** : [Setup A à Z](./00-setup-complet-a-z.md) — `spotify-elasticsearch` et `spotify-kibana` healthy.

## Table des matières

- [0. Vérifications](#0-vérifications)
- [1. Session shell complète (copier-coller)](#1-session-shell-complète-copier-coller)
- [2. Équivalents dans Kibana Dev Tools](#2-équivalents-dans-kibana-dev-tools)
- [3. Sorties attendues clés](#3-sorties-attendues-clés)
- [4. Variantes Windows PowerShell](#4-variantes-windows-powershell)
- [5. Cas erreurs résolus](#5-cas-erreurs-résolus)

---

## 0. Vérifications

```bash
docker compose ps spotify-elasticsearch spotify-kibana
curl -s http://localhost:9200/ | jq -r '.cluster_name + " · v" + .version.number'
# → docker-cluster · v8.13.4
```

Si `jq` n'est pas installé :
- Linux/macOS : `sudo apt install jq` ou `brew install jq`
- Windows : `winget install jqlang.jq`
- Sinon enlevez `| jq` ; la sortie sera juste moins jolie.

---

## 1. Session shell complète (copier-coller)

Cette session reproduit **toutes** les commandes du chapitre 12, dans l'ordre, avec vérifications.

```bash
# ============================================================
# SECTION 2 : INSPECTER LE CLUSTER
# ============================================================

# 2.1 Infos générales
curl -s http://localhost:9200/ | jq

# 2.2 Santé
curl -s http://localhost:9200/_cluster/health?pretty
# Statut attendu : "green" ou "yellow" (jamais "red")

# 2.3 Liste des nœuds
curl -s "http://localhost:9200/_cat/nodes?v"

# 2.4 Liste des indices
curl -s "http://localhost:9200/_cat/indices?v"

# 2.5 Statistiques globales
curl -s "http://localhost:9200/_stats" | jq '._all.primaries.docs'


# ============================================================
# SECTION 3 : INDICES
# ============================================================

# 3.1 Nettoyer (au cas où)
curl -s -X DELETE "http://localhost:9200/produits"

# 3.2 Créer un index minimal
curl -s -X PUT "http://localhost:9200/produits"

# 3.3 Le supprimer pour le recréer avec mapping
curl -s -X DELETE "http://localhost:9200/produits"

# 3.4 Créer avec mapping
curl -s -X PUT "http://localhost:9200/produits" \
  -H 'Content-Type: application/json' \
  -d '{
    "mappings": {
      "properties": {
        "nom":   { "type": "text" },
        "prix":  { "type": "float" },
        "stock": { "type": "integer" }
      }
    }
  }'

# 3.5 Voir le mapping
curl -s "http://localhost:9200/produits/_mapping?pretty"

# 3.6 Compter (devrait retourner 0)
curl -s "http://localhost:9200/produits/_count?pretty"


# ============================================================
# SECTION 4 : CRUD DOCUMENTS
# ============================================================

# 4.1 Créer avec ID 1
curl -s -X POST "http://localhost:9200/produits/_doc/1" \
  -H 'Content-Type: application/json' \
  -d '{
    "nom":   "Casque Bluetooth",
    "prix":  89.90,
    "stock": 12
  }'

# 4.2 Créer un autre avec ID 2
curl -s -X POST "http://localhost:9200/produits/_doc/2" \
  -H 'Content-Type: application/json' \
  -d '{
    "nom":   "Clavier mécanique",
    "prix":  129.00,
    "stock": 5
  }'

# 4.3 Créer en auto-ID (Elasticsearch génère un id aléatoire de 20 caractères)
curl -s -X POST "http://localhost:9200/produits/_doc" \
  -H 'Content-Type: application/json' \
  -d '{
    "nom":  "Souris sans fil",
    "prix": 29.90
  }'

# 4.4 Refresh manuel pour voir les docs immédiatement (par défaut, refresh = 1s)
curl -s -X POST "http://localhost:9200/produits/_refresh"

# 4.5 Lire le doc 1
curl -s "http://localhost:9200/produits/_doc/1?pretty"

# 4.6 Update partiel (ne touche QUE le champ stock)
curl -s -X POST "http://localhost:9200/produits/_update/1" \
  -H 'Content-Type: application/json' \
  -d '{ "doc": { "stock": 8 } }'

# 4.7 Vérifier le résultat
curl -s "http://localhost:9200/produits/_doc/1?pretty"

# 4.8 Supprimer le doc 2
curl -s -X DELETE "http://localhost:9200/produits/_doc/2"

# 4.9 Vérifier le compte (devrait être 2 : doc 1 + doc auto-id)
curl -s "http://localhost:9200/produits/_count?pretty"


# ============================================================
# SECTION 5 : RECHERCHE SIMPLE
# ============================================================

# 5.1 Tout
curl -s "http://localhost:9200/produits/_search?pretty"

# 5.2 Recherche par URL
curl -s "http://localhost:9200/produits/_search?q=nom:casque&pretty"

# 5.3 Recherche par body JSON
curl -s "http://localhost:9200/produits/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{ "query": { "match": { "nom": "casque" } } }'


# ============================================================
# NETTOYAGE
# ============================================================

curl -s -X DELETE "http://localhost:9200/produits"
curl -s "http://localhost:9200/_cat/indices?v"
# → l'index "produits" doit avoir disparu
```

---

## 2. Équivalents dans Kibana Dev Tools

Mêmes opérations, plus lisibles, à coller dans **Kibana → Dev Tools → Console** (http://localhost:5601/app/dev_tools#/console) :

```
DELETE produits

PUT produits
{
  "mappings": {
    "properties": {
      "nom":   { "type": "text" },
      "prix":  { "type": "float" },
      "stock": { "type": "integer" }
    }
  }
}

GET produits/_mapping

POST produits/_doc/1
{ "nom": "Casque Bluetooth", "prix": 89.90, "stock": 12 }

POST produits/_doc/2
{ "nom": "Clavier mécanique", "prix": 129.00, "stock": 5 }

POST produits/_doc
{ "nom": "Souris sans fil", "prix": 29.90 }

POST produits/_refresh

GET produits/_doc/1

POST produits/_update/1
{ "doc": { "stock": 8 } }

GET produits/_doc/1

DELETE produits/_doc/2

GET produits/_count

GET produits/_search

GET produits/_search?q=nom:casque

GET produits/_search
{
  "query": { "match": { "nom": "casque" } }
}

DELETE produits
```

> Pour exécuter une commande : placez le curseur dessus → triangle ▶ à droite, ou `Ctrl + Entrée`.

---

## 3. Sorties attendues clés

### `GET /` (infos cluster)

```json
{
  "name": "<container-id>",
  "cluster_name": "docker-cluster",
  "cluster_uuid": "...",
  "version": { "number": "8.13.4", "build_flavor": "default", ... },
  "tagline": "You Know, for Search"
}
```

### `_cluster/health`

```json
{
  "cluster_name": "docker-cluster",
  "status": "green",
  "number_of_nodes": 1,
  "active_primary_shards": <N>,
  ...
}
```

### Création d'index

```json
{ "acknowledged": true, "shards_acknowledged": true, "index": "produits" }
```

### Indexation d'un document

```json
{
  "_index": "produits",
  "_id":    "1",
  "_version": 1,
  "result": "created",
  "_shards": { "total": 2, "successful": 1, "failed": 0 },
  "_seq_no": 0,
  "_primary_term": 1
}
```

### Lecture d'un document

```json
{
  "_index": "produits",
  "_id":    "1",
  "_version": 2,
  "_seq_no": 3,
  "_primary_term": 1,
  "found":  true,
  "_source": { "nom": "Casque Bluetooth", "prix": 89.90, "stock": 8 }
}
```

### `_search` simple

```json
{
  "took": 4,
  "timed_out": false,
  "hits": {
    "total": { "value": 2, "relation": "eq" },
    "max_score": 1.0,
    "hits": [ { "_index": "produits", "_id": "1", "_source": { ... } }, ... ]
  }
}
```

### Suppression d'index

```json
{ "acknowledged": true }
```

---

## 4. Variantes Windows PowerShell

Les `curl` Linux ne fonctionnent pas tels quels en PowerShell (qui aliase `curl` à `Invoke-WebRequest`). Deux options :

### Option A — Forcer le vrai `curl.exe`

```powershell
curl.exe -X PUT "http://localhost:9200/produits"

curl.exe -X POST "http://localhost:9200/produits/_doc/1" `
  -H "Content-Type: application/json" `
  -d '{ "nom": "Casque Bluetooth", "prix": 89.90, "stock": 12 }'
```

### Option B — `Invoke-RestMethod` (PowerShell natif)

```powershell
$body = @{ nom = "Casque Bluetooth"; prix = 89.90; stock = 12 } | ConvertTo-Json
Invoke-RestMethod -Method Put `
  -Uri 'http://localhost:9200/produits/_doc/1' `
  -ContentType 'application/json' `
  -Body $body

Invoke-RestMethod -Uri 'http://localhost:9200/produits/_doc/1'
```

> **Conseil** : pour ce cours, **utilisez Kibana Dev Tools** : c'est la même API, sans le casse-tête multi-plateforme du shell.

---

## 5. Cas erreurs résolus

| Symptôme                                      | Cause                                                  | Solution                                                                |
| --------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------- |
| `Could not resolve host: localhost`           | ES n'est pas démarré, ou pas sur 9200                  | `docker compose ps` ; `docker compose logs elasticsearch`               |
| `{"error":"Incorrect HTTP method..."}`        | Mauvais verbe (ex `GET` au lieu de `PUT` pour créer)   | Vérifier la commande                                                     |
| `mapper_parsing_exception`                    | Type de champ différent du mapping (ex string sur int) | Conformer le JSON au mapping, ou recréer l'index                        |
| `index_not_found_exception`                   | Index supprimé / jamais créé                           | `PUT <index>` d'abord                                                   |
| Doc apparaît pas dans `_search` après insert  | Refresh interval = 1s par défaut                       | `POST <index>/_refresh` immédiatement après                             |
| `q=POLITICS` ne renvoie rien                  | Champ `text` indexé en minuscules                      | Utiliser `q=politics`, ou cibler `category.keyword`                     |
| `409 version_conflict_engine_exception`       | Update concurrent / `_create` sur id existant          | Utiliser `_doc/<id>` (overwrite) ou retry                               |

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
