<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# 11 — Labo 1 : Mise en place complète d'ELK avec persistance

> **Type** : Laboratoire · **Pré-requis** : [10 — Installation ES + Kibana](./10-installation-elasticsearch-kibana.md) · **Durée** : ~2 h

## Table des matières

- [1. Objectifs du labo](#1-objectifs-du-labo)
- [2. Pré-requis & vérifications](#2-pré-requis--vérifications)
- [3. Arborescence de travail](#3-arborescence-de-travail)
- [4. `docker-compose.yml` avec persistance](#4-docker-composeyml-avec-persistance)
- [5. Lancement et tests rapides](#5-lancement-et-tests-rapides)
- [6. Persistance des données](#6-persistance-des-données)
- [7. Sauvegarde / restauration de volume](#7-sauvegarde--restauration-de-volume)
- [8. Dépannage express](#8-dépannage-express)
- [9. Livrables](#9-livrables)

---

## 1. Objectifs du labo

À l'issue de ce labo vous saurez :

- **Déployer** Elasticsearch + Kibana via Docker Compose ;
- vérifier la **santé** des services (healthcheck, `_cluster/health`) ;
- **persister** les données via un volume nommé ;
- **sauvegarder/restaurer** ce volume ;
- **dépanner** les erreurs courantes (ports occupés, permissions, etc.).

---

## 2. Pré-requis & vérifications

```bash
docker --version
docker compose version

ss -lnt | grep -E ':9200|:5601' || echo "OK: ports libres"
```

Si un port est occupé :

```bash
sudo ss -ltnp | grep -E ':9200|:5601'
sudo kill -9 <PID>
# ou si c'est un container
docker ps | grep -E '9200|5601'
docker stop <CONTAINER>
```

Optionnel mais recommandé :

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

---

## 3. Arborescence de travail

```bash
mkdir -p ~/elk-news && cd ~/elk-news
```

```
~/elk-news/
├── docker-compose.yml
├── backup/        ← snapshots
└── (raw.jsonl, etc. à venir)
```

---

## 4. `docker-compose.yml` avec persistance

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

> La sécurité est **désactivée** ici (lab uniquement). En prod, voir la configuration "service token" du chapitre 10.

---

## 5. Lancement et tests rapides

```bash
docker compose up -d
docker compose ps
docker compose logs -f elasticsearch
```

### Tests API

```bash
curl -s http://localhost:9200 | jq '.'
curl -s http://localhost:9200/_cluster/health?pretty
curl -s http://localhost:9200/_nodes?pretty | jq '.nodes | keys'
```

### UI Kibana

→ http://localhost:5601 (pas de login dans cette config).

---

## 6. Persistance des données

```bash
# Redémarrage normal → données conservées
docker compose down
docker compose up -d

# Cette commande SUPPRIME les données
docker compose down -v
```

### Inspecter physiquement le volume

```bash
docker volume inspect elk_esdata | jq -r '.[0].Mountpoint'
sudo ls -lah /var/lib/docker/volumes/elk_esdata/_data
```

---

## 7. Sauvegarde / restauration de volume

### Sauvegarder

```bash
mkdir -p ~/elk-news/backup
docker run --rm \
  -v elk_esdata:/vol \
  -v ~/elk-news/backup:/backup \
  alpine sh -c "cd /vol && tar czf /backup/elk_esdata_$(date +%F_%H%M).tar.gz ."
ls -lh ~/elk-news/backup
```

### Restaurer

```bash
docker compose down
docker run --rm -v elk_esdata:/vol alpine sh -c "rm -rf /vol/*"
docker run --rm \
  -v elk_esdata:/vol \
  -v ~/elk-news/backup:/backup \
  alpine sh -c "cd /vol && tar xzf /backup/elk_esdata_YYYY-MM-DD_HHMM.tar.gz"
docker compose up -d
```

### Cloner vers un nouveau volume

```bash
docker volume create elk_esdata_clone
docker run --rm \
  -v elk_esdata_clone:/vol \
  -v ~/elk-news/backup:/backup \
  alpine sh -c "cd /vol && tar xzf /backup/elk_esdata_YYYY-MM-DD_HHMM.tar.gz"
```

---

## 8. Dépannage express

| Symptôme                         | Cause probable / Fix                                                       |
| -------------------------------- | -------------------------------------------------------------------------- |
| Ports 9200/5601 occupés          | `ss/kill` ou changer les mappings (ex `19200:9200`)                        |
| Permissions en bind-mount        | Préférer volumes nommés. Sinon `sudo chown -R 1000:1000 /srv/elk/esdata`   |
| ES jamais "healthy"              | Voir `docker compose logs -f elasticsearch`. Vérifier RAM, `vm.max_map_count` |
| Données disparues                | Probablement `down -v` ou nom de volume changé. `docker volume ls`         |

---

## 9. Livrables

À rendre dans un dossier zip ou repo Git :

1. `docker-compose.yml` final.
2. Captures de :
   - `docker compose ps` (services healthy)
   - `curl -s http://localhost:9200 | jq` (réponse cluster)
   - http://localhost:5601 (UI Kibana ouverte)
3. Une **sauvegarde** `.tar.gz` du volume.
4. Un court rapport (1 page) expliquant **pourquoi** un volume nommé > bind-mount.

<p align="right"><a href="#top">↑ Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
