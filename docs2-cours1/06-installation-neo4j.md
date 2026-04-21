<a id="top"></a>

# 06 — Installation de Neo4j (Linux + Docker)

> **Type** : Pratique · **Pré-requis** : Une VM Ubuntu **OU** Docker installé

## Table des matières

- [1. Quelle méthode choisir ?](#1-quelle-méthode-choisir-)
- [2. Méthode A — Installation native sur Ubuntu (apt)](#2-méthode-a--installation-native-sur-ubuntu-apt)
- [3. Méthode B — Docker simple (`docker run`)](#3-méthode-b--docker-simple-docker-run)
- [4. Méthode C — Docker Compose (recommandée)](#4-méthode-c--docker-compose-recommandée)
- [5. Vérifier que tout fonctionne](#5-vérifier-que-tout-fonctionne)
- [6. Pourquoi éviter `apt + systemd` dans Docker](#6-pourquoi-éviter-apt--systemd-dans-docker)

---

## 1. Quelle méthode choisir ?

| Méthode      | Avantages                                       | Inconvénients                          | Recommandée pour     |
| ------------ | ----------------------------------------------- | -------------------------------------- | -------------------- |
| **A — apt**  | Service systemd "natif"                         | Conflits Java possibles, peu portable  | Production sur VM    |
| **B — `docker run`** | Rapide, isolé                           | Commande longue à mémoriser            | Démo / test ponctuel |
| **C — Compose** | Lisible, versionnable, multi-services        | Un fichier YAML à maintenir            | **Cours / projet**   |

> Dans tout le cours on utilisera la **méthode C** (Compose), car elle s'enchaîne naturellement avec Elasticsearch + Kibana au [chapitre 10](./10-installation-elasticsearch-kibana.md).

---

## 2. Méthode A — Installation native sur Ubuntu (apt)

<details>
<summary>Étapes détaillées (cliquer pour dérouler)</summary>

### Étape 1 — Mettre à jour APT

```bash
sudo apt update
```

### Étape 2 — Pré-requis

```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```

### Étape 3 — Clé GPG Neo4j

```bash
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
```

### Étape 4 — Dépôt Neo4j

```bash
sudo add-apt-repository "deb https://debian.neo4j.com stable 4.1"
```

### Étape 5 — Installation

```bash
sudo apt install neo4j
```

### Étape 6 — Service au démarrage

```bash
sudo systemctl enable neo4j.service
sudo systemctl start neo4j.service
sudo systemctl status neo4j.service
```

### Étape 7 — Première connexion (Cypher Shell)

```bash
cypher-shell
# user: neo4j  | password: neo4j  → vous serez forcé à le changer
```

### Étape 8 — Accès distant (optionnel)

```bash
sudo nano /etc/neo4j/neo4j.conf
# Décommenter et mettre :
# dbms.default_listen_address=0.0.0.0
sudo systemctl restart neo4j
```

</details>

---

## 3. Méthode B — Docker simple (`docker run`)

```bash
# (facultatif) supprimer ancienne install apt
sudo systemctl stop neo4j 2>/dev/null
sudo apt-get purge -y neo4j 2>/dev/null

# volumes persistants
docker volume create neo4j_data
docker volume create neo4j_logs
docker volume create neo4j_plugins
docker volume create neo4j_import

# lancement
docker run -d --name neo4j4 \
  --restart unless-stopped \
  -p 7474:7474 -p 7687:7687 \
  -v neo4j_data:/data \
  -v neo4j_logs:/logs \
  -v neo4j_plugins:/plugins \
  -v neo4j_import:/var/lib/neo4j/import \
  -e NEO4J_AUTH=neo4j/Neo4jStrongPass! \
  -e NEO4J_dbms_default__listen__address=0.0.0.0 \
  -e NEO4JLABS_PLUGINS='["apoc"]' \
  -e NEO4J_apoc_export_file_enabled=true \
  -e NEO4J_apoc_import_file_enabled=true \
  -e NEO4J_apoc_import_file_use__neo4j__config=true \
  neo4j:4.1
```

> Dans les variables d'environnement Neo4j 4.x, **les `.` du fichier `neo4j.conf` deviennent `__`** (double underscore).

---

## 4. Méthode C — Docker Compose (recommandée)

Créer un fichier `docker-compose.yml` :

```yaml
services:
  neo4j:
    image: neo4j:5.20-community
    container_name: spotify-neo4j
    restart: unless-stopped
    ports:
      - "7474:7474"   # HTTP / Browser
      - "7687:7687"   # Bolt
    environment:
      NEO4J_AUTH: neo4j/Neo4jStrongPass!
      NEO4J_PLUGINS: '["apoc","graph-data-science"]'
      NEO4J_dbms_security_procedures_unrestricted: "apoc.*,gds.*"
      NEO4J_apoc_import_file_enabled: "true"
      NEO4J_server_memory_heap_max__size: 2G
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
      - neo4j_plugins:/plugins
      - ./fichiers:/var/lib/neo4j/import   # pas de :ro

volumes:
  neo4j_data:
  neo4j_logs:
  neo4j_plugins:
```

Lancer :

```bash
docker compose up -d
docker compose logs -f neo4j
```

> **Piège vécu** : le flag `:ro` (read-only) sur le volume `import` fait planter Neo4j au démarrage (`chown: Read-only file system`). On le **laisse en read-write**.

---

## 5. Vérifier que tout fonctionne

| Vérification           | Commande / URL                                                 |
| ---------------------- | -------------------------------------------------------------- |
| Conteneur up           | `docker ps`                                                    |
| Logs                   | `docker logs -f spotify-neo4j`                                 |
| Port Bolt en écoute    | `ss -tuln \| grep 7687` (ou `netstat`)                         |
| Cypher Shell           | `docker exec -it spotify-neo4j cypher-shell -u neo4j -p ...`   |
| Browser                | http://localhost:7474                                          |
| Plugin APOC chargé     | dans le browser : `RETURN apoc.version();`                     |
| Plugin GDS chargé      | dans le browser : `RETURN gds.version();`                      |

---

## 6. Pourquoi éviter `apt + systemd` dans Docker

| Problème (apt+systemd dans un conteneur)     | Conséquence                              |
| -------------------------------------------- | ---------------------------------------- |
| Docker veut **un seul process** (PID 1)      | Conflit avec systemd                     |
| Conflit Java (image vs hôte)                 | Crash au démarrage                       |
| Pas de gestion propre des volumes            | Données perdues au `docker rm`           |

L'image officielle **embarque la bonne JVM** + démarre comme un process unique → **propre et reproductible**.

<p align="right"><a href="#top">↑ Retour en haut</a></p>
