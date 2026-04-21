<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Solutions — Chapitre 11 : Labo 1 ELK (livrable complet)

> **Lien chapitre source** : [`11-labo1-mise-en-place-elk.md`](../../11-labo1-mise-en-place-elk.md)
> **Pré-requis** : [Setup A à Z](./00-setup-complet-a-z.md) **ou** Docker installé seul (ce labo crée son propre `docker-compose.yml` autonome dans `~/elk-news/`).

## Table des matières

- [Pré-flight (5 min)](#pré-flight-5-min)
- [1. Créer le dossier de travail](#1-créer-le-dossier-de-travail)
- [2. Le `docker-compose.yml` du labo (autonome)](#2-le-docker-composeyml-du-labo-autonome)
- [3. Démarrer la stack](#3-démarrer-la-stack)
- [4. Vérifier la santé](#4-vérifier-la-santé)
- [5. Tester la persistance](#5-tester-la-persistance)
- [6. Sauvegarder le volume](#6-sauvegarder-le-volume)
- [7. Restaurer une sauvegarde](#7-restaurer-une-sauvegarde)
- [8. Cloner vers un nouveau volume](#8-cloner-vers-un-nouveau-volume)
- [9. Captures d'écran à fournir](#9-captures-décran-à-fournir)
- [10. Petit rapport (modèle)](#10-petit-rapport-modèle)
- [11. Critères d'évaluation](#11-critères-dévaluation)

---

## Pré-flight (5 min)

```bash
docker --version
docker compose version
```

Si erreur → revenir au [Setup A à Z § 1-2](./00-setup-complet-a-z.md#1-installer-docker-desktop).

```bash
# Vérifier que les ports ne sont PAS occupés
# Linux/macOS :
ss -lnt | grep -E ':9200|:5601' || echo "OK ports libres"

# Windows (PowerShell) :
netstat -ano | Select-String ':9200|:5601'   # ne doit rien retourner
```

Sur Linux uniquement :

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

---

## 1. Créer le dossier de travail

### Linux / macOS

```bash
mkdir -p ~/elk-news/backup
cd ~/elk-news
```

### Windows (PowerShell)

```powershell
mkdir C:\elk-news\backup -Force
cd C:\elk-news
```

Arborescence cible :

```
elk-news/
├── docker-compose.yml      <- créé à l'étape 2
└── backup/                  <- snapshots .tar.gz
```

---

## 2. Le `docker-compose.yml` du labo (autonome)

Créez `docker-compose.yml` dans `elk-news/` :

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.14.3
    container_name: es-news
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports: ["9200:9200"]
    volumes:
      - esdata:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL","curl -fsS http://localhost:9200 >/dev/null || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 60
    restart: unless-stopped

  kibana:
    image: docker.elastic.co/kibana/kibana:8.14.3
    container_name: kb-news
    depends_on:
      elasticsearch:
        condition: service_healthy
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - XPACK_SECURITY_ENABLED=false
    ports: ["5601:5601"]
    restart: unless-stopped

volumes:
  esdata:
    name: elk_esdata
```

> **Différence avec la stack du cours** : ici on a **uniquement** ES + Kibana (pas de Neo4j/Jupyter), et on **nomme explicitement** le volume `elk_esdata` pour faciliter sauvegarde/restauration.

---

## 3. Démarrer la stack

```bash
docker compose up -d
```

Sortie attendue :

```
[+] Running 3/3
 ✓ Network elk-news_default     Created
 ✓ Container es-news            Started
 ✓ Container kb-news            Started
```

Premier démarrage : 5 à 10 min (téléchargement des images ES + Kibana ~2 Go).

```bash
docker compose ps
```

```
NAME       STATUS                   PORTS
es-news    Up 30 seconds (healthy)  0.0.0.0:9200->9200/tcp
kb-news    Up 25 seconds            0.0.0.0:5601->5601/tcp
```

---

## 4. Vérifier la santé

### 4.1 Cluster Elasticsearch

```bash
curl -s http://localhost:9200 | jq
```

Sortie attendue :

```json
{
  "name": "es-news",
  "cluster_name": "docker-cluster",
  "version": { "number": "8.14.3", ... },
  "tagline": "You Know, for Search"
}
```

```bash
curl -s 'http://localhost:9200/_cluster/health?pretty'
```

```json
{
  "cluster_name": "docker-cluster",
  "status": "green",
  "number_of_nodes": 1,
  ...
}
```

### 4.2 Liste des nœuds

```bash
curl -s 'http://localhost:9200/_nodes?pretty' | jq '.nodes | keys'
```

→ une seule clé (l'unique nœud du cluster single-node).

### 4.3 Kibana UI

Ouvrez http://localhost:5601 → page d'accueil de Kibana s'affiche (pas de login, sécurité désactivée).

---

## 5. Tester la persistance

### 5.1 Indexer un document témoin

```bash
curl -X POST 'http://localhost:9200/temoin/_doc' \
     -H 'Content-Type: application/json' \
     -d '{"message":"avant arrêt","date":"2026-04-19"}'

curl -s 'http://localhost:9200/temoin/_search?pretty'
```

→ doit retourner 1 hit.

### 5.2 Arrêter, redémarrer, vérifier

```bash
docker compose down              # supprime les conteneurs (PAS le volume)
docker compose up -d
sleep 30                          # attendre que ES soit healthy
curl -s 'http://localhost:9200/temoin/_search?pretty'
```

→ **le hit est toujours là**. Persistance OK.

### 5.3 Cas inverse — perte volontaire

```bash
docker compose down -v           # -v = supprime AUSSI les volumes
docker compose up -d
sleep 30
curl -s 'http://localhost:9200/temoin/_search?pretty'
```

→ erreur `index_not_found_exception` : les données ont été effacées comme attendu.

> **Leçon clé** : `down` conserve, `down -v` détruit. **Toujours** réfléchir avant un `-v`.

---

## 6. Sauvegarder le volume

```bash
mkdir -p ~/elk-news/backup
docker run --rm \
  -v elk_esdata:/vol \
  -v ~/elk-news/backup:/backup \
  alpine sh -c "cd /vol && tar czf /backup/elk_esdata_$(date +%F_%H%M).tar.gz ."

ls -lh ~/elk-news/backup
```

Windows PowerShell équivalent :

```powershell
docker run --rm `
  -v elk_esdata:/vol `
  -v C:\elk-news\backup:/backup `
  alpine sh -c "cd /vol && tar czf /backup/elk_esdata_$(date +%F_%H%M).tar.gz ."

dir C:\elk-news\backup
```

→ vous obtenez un fichier `.tar.gz` daté (typiquement 50–500 Mo selon ce qui a été indexé).

---

## 7. Restaurer une sauvegarde

```bash
docker compose down

# Vider le volume actuel
docker run --rm -v elk_esdata:/vol alpine sh -c "rm -rf /vol/*"

# Restaurer (remplacer YYYY-MM-DD_HHMM par votre fichier)
docker run --rm \
  -v elk_esdata:/vol \
  -v ~/elk-news/backup:/backup \
  alpine sh -c "cd /vol && tar xzf /backup/elk_esdata_YYYY-MM-DD_HHMM.tar.gz"

docker compose up -d
sleep 30
curl -s 'http://localhost:9200/temoin/_search?pretty'
```

→ le document `temoin` doit réapparaître.

---

## 8. Cloner vers un nouveau volume

```bash
docker volume create elk_esdata_clone
docker run --rm \
  -v elk_esdata_clone:/vol \
  -v ~/elk-news/backup:/backup \
  alpine sh -c "cd /vol && tar xzf /backup/elk_esdata_YYYY-MM-DD_HHMM.tar.gz"

docker volume ls | grep elk_esdata
```

> Utile pour **tester une migration** sans toucher au volume de prod.

---

## 9. Captures d'écran à fournir

| # | Capture                                                              | Commande qui la produit                                |
| - | -------------------------------------------------------------------- | ------------------------------------------------------ |
| 1 | `docker compose ps` montrant les 2 services healthy                  | `docker compose ps`                                    |
| 2 | Réponse `curl -s http://localhost:9200 \| jq`                        | terminal                                               |
| 3 | Réponse `curl -s 'http://localhost:9200/_cluster/health?pretty'` avec status green | terminal                                |
| 4 | Page d'accueil Kibana ouverte dans le navigateur                     | http://localhost:5601                                  |
| 5 | `ls -lh ~/elk-news/backup` montrant le `.tar.gz`                     | terminal                                               |
| 6 | Test de persistance après `down/up` : `_search` qui retrouve le doc  | terminal                                               |

---

## 10. Petit rapport (modèle)

```markdown
# Rapport Labo 1 — Mise en place ELK avec persistance

## Objectifs atteints
- Déploiement d'un cluster ES single-node + Kibana via Docker Compose.
- Healthcheck configuré sur Elasticsearch ; Kibana attend ES via `service_healthy`.
- Persistance des données via le volume nommé `elk_esdata`.
- Sauvegarde / restauration testée par tar streaming.

## Architecture déployée
[insérer un diagramme Mermaid ou capture]

## Pourquoi un volume nommé > bind-mount ?
- **Portabilité** : le volume est géré par Docker, pas dépendant d'un chemin hôte précis.
- **Permissions** : le user UID 1000 du conteneur ES écrit sans souci dans un volume nommé ;
  un bind-mount nécessite souvent `chown -R 1000:1000` côté hôte.
- **Sauvegarde** : un volume nommé est facile à dumper via un container alpine (cf. § 6).
- **Sécurité** : moins de risque d'effacer accidentellement un dossier hôte sensible
  (un `down -v` n'efface que le volume Docker, pas votre `~/`).

## Tests effectués
| Test                                  | Résultat |
| ------------------------------------- | -------- |
| Cluster health = green                | OK       |
| Indexation d'un document `temoin`     | OK       |
| Document survit à `down` / `up`       | OK       |
| Document est perdu après `down -v`    | OK (attendu) |
| Restauration depuis tar.gz            | OK       |

## Difficultés rencontrées
- (Exemple) Port 9200 occupé par un autre process ; résolu via `docker stop <conteneur>` / `taskkill`.
- (Exemple) ES restait en `unhealthy` ; cause : `vm.max_map_count` trop bas sur Linux.

## Annexe : commandes utilisées
[copier les commandes-clés]
```

---

## 11. Critères d'évaluation

| Critère                                                              | Poids |
| -------------------------------------------------------------------- | :---: |
| `docker-compose.yml` correct (healthcheck, volumes, depends_on)      |  25%  |
| Stack démarre proprement (services healthy)                          |  20%  |
| Test de persistance documenté (down/up + down -v)                    |  20%  |
| Sauvegarde + restauration validées avec captures                     |  20%  |
| Rapport synthétique (justification volume nommé vs bind-mount)       |  15%  |

> Pour aller plus loin : passez au [Setup A à Z](./00-setup-complet-a-z.md) qui ajoute Neo4j + Jupyter, puis au [chapitre 14](../../14-import-bulk-dataset.md) pour charger un vrai dataset.

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
