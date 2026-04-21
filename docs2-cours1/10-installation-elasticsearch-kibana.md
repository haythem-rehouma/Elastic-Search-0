<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# 10 — Installation d'Elasticsearch + Kibana

> **Type** : Pratique · **Pré-requis** : Docker + Docker Compose

## Table des matières

- [1. Deux modes d'installation](#1-deux-modes-dinstallation)
- [2. Méthode A — Linux/Ubuntu via apt (apprentissage)](#2-méthode-a--linuxubuntu-via-apt-apprentissage)
- [3. Méthode B — Docker Compose (recommandée)](#3-méthode-b--docker-compose-recommandée)
- [4. Pré-requis Docker Compose](#4-pré-requis-docker-compose)
- [5. Service token Kibana ↔ Elasticsearch](#5-service-token-kibana--elasticsearch)
- [6. Vérifications](#6-vérifications)
- [7. Bonnes pratiques de sécurité](#7-bonnes-pratiques-de-sécurité)

---

## 1. Deux modes d'installation

| Méthode      | Quand choisir                              |
| ------------ | ------------------------------------------ |
| **A — apt**  | Comprendre la stack "à la dure" sur une VM |
| **B — Compose** | Production / projet / cours              |

> La méthode **Compose** s'aligne avec les chapitres suivants du cours.

---

## 2. Méthode A — Linux/Ubuntu via apt (apprentissage)

<details>
<summary>Étapes complètes</summary>

```bash
sudo apt update
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" \
  | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update

sudo apt install elasticsearch kibana
sudo systemctl enable --now elasticsearch
sudo systemctl enable --now kibana
sudo systemctl status elasticsearch kibana
```

### Configurer Kibana

```bash
sudo nano /etc/kibana/kibana.yml
```

```yaml
server.port: 5601
server.host: "localhost"
elasticsearch.hosts: ["http://localhost:9200"]
```

### Première connexion (Enrollment Token)

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
sudo /usr/share/kibana/bin/kibana-verification-code
```

→ Copier le token + le code à 6 chiffres dans Kibana (http://localhost:5601).

### Réinitialiser le mot de passe `elastic`

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

> Veillez à utiliser **la même version majeure** pour Elasticsearch et Kibana (ex : 8.13 + 8.13).

</details>

---

## 3. Méthode B — Docker Compose (recommandée)

### Le `docker-compose.yml` minimal et propre

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    container_name: es01
    restart: unless-stopped
    environment:
      - node.name=es01
      - discovery.type=single-node
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=false
      - xpack.security.transport.ssl.enabled=false
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - ES_JAVA_OPTS=${ES_JAVA_OPTS}
      - cluster.routing.allocation.disk.threshold_enabled=false
    ports: ["9200:9200"]
    volumes: [es-data:/usr/share/elasticsearch/data]
    healthcheck:
      test: ["CMD-SHELL", "curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200 >/dev/null"]
      interval: 10s
      timeout: 5s
      retries: 30

  kibana:
    image: docker.elastic.co/kibana/kibana:${STACK_VERSION}
    container_name: kib01
    restart: unless-stopped
    depends_on:
      elasticsearch:
        condition: service_healthy
    environment:
      - SERVER_NAME=kibana
      - SERVER_HOST=0.0.0.0
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - ELASTICSEARCH_SERVICEACCOUNTTOKEN=${ELASTICSEARCH_SERVICEACCOUNTTOKEN}
      - XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY=${KIBANA_ENCRYPTION_KEY1}
      - XPACK_REPORTING_ENCRYPTIONKEY=${KIBANA_ENCRYPTION_KEY2}
      - XPACK_SECURITY_ENCRYPTIONKEY=${KIBANA_ENCRYPTION_KEY3}
    ports: ["5601:5601"]

volumes:
  es-data:
```

### Le fichier `.env` associé

```bash
STACK_VERSION=8.19.5
ELASTIC_PASSWORD=changeme123!
# Les guillemets simples sont OBLIGATOIRES sinon "-Xmx1g: command not found"
ES_JAVA_OPTS='-Xms1g -Xmx1g'
KIBANA_ENCRYPTION_KEY1=change_me_to_a_very_long_random_string_key_1_________
KIBANA_ENCRYPTION_KEY2=change_me_to_a_very_long_random_string_key_2_________
KIBANA_ENCRYPTION_KEY3=change_me_to_a_very_long_random_string_key_3_________
ELASTICSEARCH_SERVICEACCOUNTTOKEN=
```

> **3 pièges classiques** :
> 1. `ES_JAVA_OPTS` non quoté → erreur `-Xmx1g: command not found`.
> 2. Disque presque plein → ES passe en read-only → 401 partout. On désactive `disk.threshold_enabled`.
> 3. Kibana ne doit **pas** utiliser le compte `elastic` mais un **service token** (cf. §5).

---

## 4. Pré-requis Docker Compose

### Sur Ubuntu

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git
# Suivez le script officiel Docker
```

### Libérer les ports 9200 / 5601

```bash
sudo systemctl stop elasticsearch kibana 2>/dev/null
docker compose down 2>/dev/null
sudo ss -ltnp | grep -E ':(9200|5601)\b' || echo "OK: ports libres"
sudo fuser -k -n tcp 5601 2>/dev/null
```

### Sur Linux : `vm.max_map_count`

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

---

## 5. Service token Kibana ↔ Elasticsearch

```bash
# Démarrer ES seul
docker compose up -d elasticsearch
until [ "$(docker inspect -f '{{.State.Health.Status}}' es01)" = "healthy" ]; do sleep 2; done

# Générer le service token
NEW_TOKEN=$(docker exec es01 bash -lc \
  "/usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana kibana-$(date +%s)" \
  | awk -F'= ' '/= /{print $2}' | tr -d '\r')

# Vérifier
curl -s -H "Authorization: Bearer $NEW_TOKEN" \
  http://localhost:9200/_security/_authenticate?pretty
# → "username" : "elastic/kibana"

# Stocker dans .env
sed -i "s|^ELASTICSEARCH_SERVICEACCOUNTTOKEN=.*|ELASTICSEARCH_SERVICEACCOUNTTOKEN=$NEW_TOKEN|" .env
set -a; source .env; set +a

# Démarrer Kibana
docker compose up -d kibana
```

---

## 6. Vérifications

| Test                         | Commande                                                                |
| ---------------------------- | ----------------------------------------------------------------------- |
| Conteneurs sains             | `docker compose ps`                                                     |
| Ping Elasticsearch           | `curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200/`              |
| Liste des indices            | `curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/_cat/indices?v"` |
| Statut Kibana                | `curl -s http://localhost:5601/api/status \| jq -r '.status.overall.level'` |
| UI Kibana                    | http://localhost:5601 → user `elastic` / mot de passe du `.env`         |

---

## 7. Bonnes pratiques de sécurité

| Bonne pratique                               | Pourquoi                                          |
| -------------------------------------------- | ------------------------------------------------- |
| **Quoter** `ES_JAVA_OPTS` dans le `.env`     | Évite que le shell interprète `-Xmx1g`            |
| **Service token** plutôt que user `elastic`  | `elastic` ne peut pas écrire dans `.security`     |
| **Désactiver le seuil disque** en dev        | Sinon flood-stage → indices read-only → 401       |
| **Recharger `.env`** dans chaque shell       | `set -a; source .env; set +a`                     |
| Ne **jamais** committer `.env`               | Mots de passe en clair                            |

<p align="right"><a href="#top">↑ Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
