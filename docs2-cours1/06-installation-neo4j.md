<a id="top"></a>

# 06 — Installation de Neo4j (Linux + Docker)

> **Type** : Pratique · **Pré-requis** : Une VM Ubuntu **OU** Docker installé

## Table des matières

- [0. Pré-requis système](#0-pré-requis-système)
- [1. Quelle méthode choisir ?](#1-quelle-méthode-choisir-)
- [2. Méthode A — Installation native sur Ubuntu (apt)](#2-méthode-a--installation-native-sur-ubuntu-apt)
- [3. Méthode B — Docker simple (`docker run`)](#3-méthode-b--docker-simple-docker-run)
- [4. Méthode C — Docker Compose (recommandée)](#4-méthode-c--docker-compose-recommandée)
- [5. Vérifier que tout fonctionne](#5-vérifier-que-tout-fonctionne)
- [6. Pourquoi éviter `apt + systemd` dans Docker](#6-pourquoi-éviter-apt--systemd-dans-docker)
- [Annexe A — Installation de Docker Desktop (Windows / macOS / Linux)](#annexe-a--installation-de-docker-desktop-windows--macos--linux)

---

## 0. Pré-requis système

### Compatibilité OS pour ce cours

| OS                    | Versions supportées                    | Recommandé ? | Solution Docker                      |
| --------------------- | -------------------------------------- | :----------: | ------------------------------------ |
| **Ubuntu**            | 22.04 LTS, 24.04 LTS                   | Oui          | Docker Engine (natif) ou Docker Desktop |
| Ubuntu                | 20.04 LTS                              | Acceptable   | Docker Engine                        |
| Ubuntu                | 18.04 et antérieures                   | **Non**      | EOL, pas supporté                    |
| **Windows 10**        | 22H2 (build 19045) édition Pro/Home/Édu | Oui         | **Docker Desktop avec WSL2**         |
| **Windows 11**        | 23H2 ou 24H2                           | Oui          | **Docker Desktop avec WSL2**         |
| Windows               | 8.1 et antérieures                     | **Non**      | Pas de WSL2                          |
| **macOS**             | Sonoma 14, Sequoia 15                  | Oui          | Docker Desktop (Apple Silicon ou Intel) |
| macOS                 | Ventura 13                             | Acceptable   | Docker Desktop                       |
| macOS                 | Monterey 12 et antérieurs              | **Non**      | Versions récentes de Docker Desktop refusent |
| **Debian**            | 12 (Bookworm), 11 (Bullseye)           | Oui          | Docker Engine                        |
| **Fedora**            | 40, 41                                 | Oui          | Docker Engine ou Docker Desktop      |

### Ressources matérielles minimales

| Ressource    | Minimum | Recommandé                                                     |
| ------------ | :-----: | -------------------------------------------------------------- |
| **RAM totale** | 8 Go  | **16 Go** (Neo4j + Elasticsearch + Kibana + OS hôte)           |
| **RAM allouée à Docker** | 4 Go | **6 à 8 Go** (réglé dans Docker Desktop → Settings → Resources) |
| **CPU**      | 2 cœurs | 4 cœurs                                                       |
| **Disque libre** | 10 Go | 20 Go (images Docker + dataset News 200 853 articles)        |
| **Connexion Internet** | requise | pour télécharger les images au premier `compose up`     |

> **Pas de Docker installé ?** Aller directement à l'**[Annexe A — Installation de Docker Desktop](#annexe-a--installation-de-docker-desktop-windows--macos--linux)** en bas de cette page. C'est l'étape **zéro** avant tout le reste du cours.

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

---

## Annexe A — Installation de Docker Desktop (Windows / macOS / Linux)

> Cette annexe couvre l'installation **complète** de Docker Desktop, de zéro jusqu'au premier `docker run hello-world` qui répond. Elle s'applique aux **trois OS** et aux trois architectures CPU (Intel/AMD x86_64 et Apple Silicon arm64).

### A.0. Comprendre Docker Desktop vs Docker Engine

| Produit               | Sur quel OS ?                  | Interface graphique ? | Recommandé pour ce cours ?    |
| --------------------- | ------------------------------ | :-------------------: | ----------------------------- |
| **Docker Desktop**    | Windows, macOS, Linux          | Oui                   | **Oui** sur Windows et macOS  |
| **Docker Engine**     | Linux uniquement               | Non (CLI seulement)   | Acceptable sur Ubuntu/Debian  |
| Docker Toolbox (legacy) | Windows 7/8                  | Oui                   | **Non** (obsolète, abandonné) |

> **Sur Windows et macOS**, Docker tourne dans une **VM légère** gérée pour vous (WSL2 sur Windows, virtualization framework sur macOS). Vous **devez** passer par Docker Desktop.
> **Sur Linux**, Docker tourne nativement (pas de VM). Docker Desktop reste possible mais Docker Engine + Docker Compose suffit largement.

### A.1. Installation sur Windows 10 / 11

<details>
<summary><b>Étapes complètes Windows (cliquer pour dérouler)</b></summary>

#### A.1.1. Vérifier les pré-requis Windows

Ouvrir **PowerShell** (touche Windows → taper `powershell`) :

```powershell
# Version de Windows
winver

# Build (doit etre >= 19045 sur Win10 ou >= 22000 sur Win11)
[System.Environment]::OSVersion.Version
```

| Composant requis                          | Comment vérifier / activer                                          |
| ----------------------------------------- | ------------------------------------------------------------------- |
| Windows 10 22H2 build ≥ 19045 OU Windows 11 | `winver`                                                          |
| **Virtualisation CPU activée dans le BIOS** | `Get-ComputerInfo -Property HyperVRequirementVirtualizationFirmwareEnabled` doit retourner `True` |
| **WSL2** installé                         | `wsl --status` doit afficher version 2 par défaut                   |
| Hyper-V ou Windows Hypervisor Platform   | activé automatiquement par WSL2                                     |
| ≥ 4 Go de RAM libre                       | `Get-CimInstance Win32_OperatingSystem \| Select FreePhysicalMemory` |

Si **WSL2 n'est pas installé** :

```powershell
wsl --install
# redemarrer Windows
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04
```

> Si la virtualisation CPU n'est pas activée : redémarrer dans le **BIOS/UEFI** (touche F2/Suppr/F10 selon le constructeur), section **CPU / Advanced**, activer `Intel VT-x` (Intel) ou `SVM Mode` (AMD), sauvegarder, redémarrer.

#### A.1.2. Télécharger Docker Desktop

1. Aller sur https://www.docker.com/products/docker-desktop/
2. Cliquer sur **« Download for Windows — AMD64 »** (ou ARM64 si Surface ARM).
3. Le fichier téléchargé s'appelle `Docker Desktop Installer.exe` (≈ 800 Mo).

> **Méthode alternative via `winget`** (Windows Package Manager, installé d'office sur Win11) :
> ```powershell
> winget install --id Docker.DockerDesktop -e
> ```

#### A.1.3. Lancer l'installeur

1. Double-cliquer sur `Docker Desktop Installer.exe`.
2. Cocher **« Use WSL 2 instead of Hyper-V »** (par défaut sur les versions récentes).
3. Cocher **« Add shortcut to desktop »**.
4. Cliquer **OK**.
5. Attendre 3 à 5 minutes.
6. Cliquer **« Close and restart »** → **redémarrage de Windows obligatoire**.

#### A.1.4. Premier lancement

1. Au redémarrage, Docker Desktop se lance automatiquement.
2. Accepter le **Service Agreement** (la version perso est gratuite pour étudiants).
3. **Skip sign-in** (pas besoin de compte Docker Hub pour ce cours).
4. La baleine bleue dans la barre des tâches doit afficher **« Docker Desktop is running »**.

#### A.1.5. Configuration recommandée pour ce cours

Docker Desktop → engrenage **Settings** :

| Onglet                    | Réglage                                                | Valeur recommandée |
| ------------------------- | ------------------------------------------------------ | :----------------: |
| **General**               | Start Docker Desktop when you sign in                  | Coché              |
| **General**               | Use Docker Compose V2                                  | Coché              |
| **Resources → Advanced**  | CPUs                                                   | 4                  |
| **Resources → Advanced**  | Memory                                                 | **6 GB**           |
| **Resources → Advanced**  | Swap                                                   | 1 GB               |
| **Resources → Advanced**  | Disk image size                                        | 64 GB              |
| **Resources → WSL Integration** | Enable integration with my default WSL distro    | Coché              |

> **Sans 6 GB de RAM allouée**, Elasticsearch et Neo4j ne tourneront pas en parallèle (OOM kill).

#### A.1.6. Vérification finale (PowerShell ou WSL)

```powershell
docker --version
# Docker version 27.x ou superieur

docker compose version
# Docker Compose version v2.x

docker run --rm hello-world
# doit afficher "Hello from Docker!"
```

</details>

### A.2. Installation sur macOS (Intel et Apple Silicon)

<details>
<summary><b>Étapes complètes macOS (cliquer pour dérouler)</b></summary>

#### A.2.1. Vérifier l'architecture du Mac

```bash
uname -m
# arm64  -> Apple Silicon (M1, M2, M3, M4)
# x86_64 -> Intel
```

Cette information détermine **quel installeur télécharger**.

#### A.2.2. Pré-requis macOS

| Composant                                | Vérification                                |
| ---------------------------------------- | ------------------------------------------- |
| macOS Ventura 13.5 minimum (Sonoma/Sequoia recommandé) | menu Pomme → À propos de ce Mac |
| 4 Go de RAM libre                        | `vm_stat \| head`                           |
| 10 Go de disque libre                    | `df -h /`                                   |
| Rosetta 2 (Apple Silicon uniquement)     | `softwareupdate --install-rosetta --agree-to-license` |

#### A.2.3. Télécharger Docker Desktop

1. Aller sur https://www.docker.com/products/docker-desktop/
2. Cliquer sur le **bon installeur** :
   - **« Download for Mac — Apple Silicon »** si `arm64`
   - **« Download for Mac — Intel chip »** si `x86_64`
3. Le fichier `.dmg` fait ≈ 600 Mo.

> **Méthode alternative via Homebrew** :
> ```bash
> brew install --cask docker
> ```

#### A.2.4. Installation

1. Ouvrir le `.dmg` téléchargé.
2. **Glisser** l'icône Docker dans le dossier **Applications**.
3. Ouvrir **Applications → Docker** (premier lancement plus long).
4. macOS demande la permission d'exécuter une app téléchargée → **Ouvrir**.
5. Docker installe son **helper privilégié** (saisir le mot de passe macOS).

#### A.2.5. Configuration recommandée

Docker Desktop → **Settings** (engrenage en haut à droite) :

| Onglet                    | Réglage                              | Valeur recommandée |
| ------------------------- | ------------------------------------ | :----------------: |
| **General**               | Start Docker Desktop when you log in | Coché              |
| **General**               | Use Virtualization framework         | Coché (par défaut sur récents macOS) |
| **General**               | Use Rosetta for x86_64 emulation     | Coché (Apple Silicon uniquement) |
| **Resources**             | CPUs                                 | 4                  |
| **Resources**             | Memory                               | **6 GB**           |
| **Resources**             | Swap                                 | 1 GB               |
| **Resources**             | Virtual disk limit                   | 64 GB              |

#### A.2.6. Vérification finale (Terminal)

```bash
docker --version
docker compose version
docker run --rm hello-world
```

</details>

### A.3. Installation sur Ubuntu / Debian

<details>
<summary><b>Étapes complètes Linux (cliquer pour dérouler)</b></summary>

> Sur Linux, deux choix : **Docker Engine** (CLI uniquement, plus léger) **OU** **Docker Desktop pour Linux** (interface graphique). Pour un cours, Docker Engine suffit.

#### A.3.1. Désinstaller toute version ancienne

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg 2>/dev/null
done
```

#### A.3.2. Ajouter le dépôt officiel Docker

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

> Pour Debian, remplacer `ubuntu` par `debian` dans les deux URLs.

#### A.3.3. Installer Docker Engine + Compose

```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
                        docker-buildx-plugin docker-compose-plugin
```

#### A.3.4. Permettre à votre utilisateur d'utiliser Docker sans `sudo`

```bash
sudo groupadd docker 2>/dev/null
sudo usermod -aG docker $USER
newgrp docker          # appliquer le groupe sans deconnexion
```

#### A.3.5. Activer le démarrage automatique

```bash
sudo systemctl enable docker
sudo systemctl enable containerd
sudo systemctl start docker
```

#### A.3.6. Vérification finale

```bash
docker --version
docker compose version
docker run --rm hello-world
```

#### A.3.7. (Optionnel) Docker Desktop pour Linux

Si vous voulez l'**interface graphique** comme sur Windows/Mac :

1. https://www.docker.com/products/docker-desktop/ → **Download for Linux** (paquet `.deb` pour Ubuntu/Debian, `.rpm` pour Fedora).
2. Installer :
   ```bash
   sudo apt-get install -y ./docker-desktop-*-amd64.deb
   ```
3. Lancer via le menu Applications.

> **Attention :** Docker Desktop sur Linux fait tourner Docker dans une **VM** (comme sur Mac/Windows). Cela double l'usage RAM et complique l'accès aux volumes. Pour ce cours, **Docker Engine seul est plus simple**.

</details>

### A.4. Composition de la stack du cours

Au fur et à mesure des chapitres, vous lancerez ces services Docker. Voici le **récapitulatif global** pour dimensionner votre installation :

| Chapitre / Pratique         | Image Docker                                  | Port   | RAM    | Volume nommé          |
| --------------------------- | --------------------------------------------- | :----: | :----: | --------------------- |
| **Pratique 1-4** (chap. 06-09) | `neo4j:5.20-community`                     | 7474, 7687 | 2 Go | `neo4j_data`, `neo4j_logs`, `neo4j_plugins` |
| **Pratique 5** (chap. 10)   | `docker.elastic.co/elasticsearch/elasticsearch:8.x` | 9200, 9300 | 1-2 Go | `esdata` |
| **Pratique 5** (chap. 10)   | `docker.elastic.co/kibana/kibana:8.x`         | 5601   | 1 Go   | (pas de volume requis) |
| **Labo 1** (chap. 11)       | ES + Kibana                                   | 9200, 5601 | 2 Go | `ch11_esdata`         |
| **Pratique 6-7** (chap. 12-13) | ES + Kibana                                | 9200, 5601 | 1.5 Go | `ch12_esdata`, `ch13_esdata` |
| **Pratique 8-10** (chap. 14-16) | ES + Kibana                                | 9200, 5601 | **2.5 Go** (heap ES = 1 Go) | `ch14_esdata` (réutilisé) |
| **Labo 2** (chap. 17)       | ES + Kibana                                   | 9200, 5601 | **2.5 Go** | `ch17_esdata`         |

> **Important :** chaque projet runnable de `assets-cours2/solutions/chXX-*/` a son **propre volume nommé**, donc vous pouvez **détruire et recréer** un projet sans impacter les autres. C'est volontaire.

### A.5. Commandes utiles à connaître

```bash
# Voir tous les conteneurs (en cours et arretes)
docker ps -a

# Voir tous les volumes
docker volume ls

# Liberer de l'espace (images et conteneurs inutilises)
docker system prune

# Liberer de l'espace AGRESSIF (inclut les volumes orphelins)
docker system prune --volumes

# Logs en direct d'un conteneur
docker logs -f <nom>

# Entrer dans un conteneur
docker exec -it <nom> bash
```

### A.6. Diagnostics si quelque chose ne marche pas

<details>
<summary><b>« Cannot connect to the Docker daemon »</b></summary>

- **Windows/Mac** : Docker Desktop n'est pas démarré. Lancer l'app, attendre que la baleine devienne stable.
- **Linux** : `sudo systemctl start docker` puis vérifier `sudo systemctl status docker`.
- **Linux, sans `sudo` ne marche pas** : vérifier que vous êtes dans le groupe : `groups | grep docker`. Si non : `newgrp docker` ou se déconnecter/reconnecter.

</details>

<details>
<summary><b>« WSL 2 installation is incomplete » (Windows)</b></summary>

```powershell
wsl --update
wsl --shutdown
```

Puis redémarrer Docker Desktop. Si toujours bloqué :

```powershell
wsl --install --no-distribution
```

et redémarrer Windows.

</details>

<details>
<summary><b>Le conteneur Elasticsearch redémarre en boucle (« exit code 137 »)</b></summary>

Code 137 = OOM kill (Docker manque de RAM). Aller dans Docker Desktop → Settings → Resources → augmenter **Memory à 6 Go minimum**, puis appliquer/restart.

</details>

<details>
<summary><b>Erreur « max virtual memory areas vm.max_map_count [65530] is too low » (Elasticsearch)</b></summary>

ES exige `vm.max_map_count >= 262144`.

- **Linux** :
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
  ```
- **Windows / Mac** : Docker Desktop le règle automatiquement dans sa VM. Si ça plante quand même, redémarrer Docker Desktop.

</details>

<details>
<summary><b>Port déjà utilisé (5601, 9200, 7474…)</b></summary>

```bash
# Linux/Mac
sudo lsof -i :5601

# Windows
netstat -ano | findstr :5601
```

Tuer le process qui occupe le port, ou changer le mapping dans le `docker-compose.yml` (ex. `5602:5601`).

</details>

<p align="right"><a href="#top">↑ Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
