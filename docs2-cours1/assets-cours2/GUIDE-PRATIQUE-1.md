<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Guide étudiant — Pratique 1 : CRUD avec Elasticsearch via Kibana

> **Énoncé officiel du prof :** [`Kibana - Pratique 1.docx`](./Kibana%20-%20Pratique%201.docx) (dans ce dossier)
>
> Ce guide vous accompagne **étape par étape**, du démarrage de la stack jusqu'à la livraison. Vous n'avez **pas besoin** d'avoir lu tout le cours avant — les concepts sont rappelés au fur et à mesure.

## Table des matières

- [Objectif pédagogique](#objectif-pédagogique)
- [Ce que vous saurez faire à la fin](#ce-que-vous-saurez-faire-à-la-fin)
- [Pré-requis (15 min)](#pré-requis-15-min)
- [Plan de la séance (90 min)](#plan-de-la-séance-90-min)
- [Étape 1 — Démarrer la stack ELK](#étape-1--démarrer-la-stack-elk)
- [Étape 2 — Comprendre POST vs PUT vs `_create`](#étape-2--comprendre-post-vs-put-vs-_create)
- [Étape 3 — Mettre à jour un document](#étape-3--mettre-à-jour-un-document)
- [Étape 4 — Le piège : `PUT _doc` remplace tout](#étape-4--le-piège--put-_doc-remplace-tout)
- [Étape 5 — Supprimer un document, puis l'index](#étape-5--supprimer-un-document-puis-lindex)
- [Étape 6 — Exercice à rendre](#étape-6--exercice-à-rendre)
- [Livrable et critères d'évaluation](#livrable-et-critères-dévaluation)
- [Aide rapide / FAQ étudiants](#aide-rapide--faq-étudiants)

---

## Objectif pédagogique

Maîtriser les **opérations CRUD** (Create, Read, Update, Delete) sur des documents Elasticsearch **directement depuis l'interface Kibana → Dev Tools**, sans écrire la moindre ligne de code Python ou de `curl`.

À l'issue de la pratique, vous distinguerez sans hésitation :

| Concept                   | Quand l'utiliser ?                                            |
| ------------------------- | ------------------------------------------------------------- |
| `POST index/_doc`         | Insérer un document **sans choisir l'id** (Elasticsearch en génère un) |
| `PUT index/_doc/<id>`     | Insérer ou **remplacer entièrement** un document avec un id précis |
| `PUT index/_create/<id>`  | Insérer **uniquement si l'id n'existe pas** (refus si déjà présent) |
| `POST index/_update/<id>` | Modifier **partiellement** un document (les autres champs sont préservés) |
| `DELETE index/_doc/<id>`  | Supprimer un document précis                                  |
| `DELETE index`            | Supprimer **tout l'index** (irréversible)                     |

## Ce que vous saurez faire à la fin

- Démarrer Elasticsearch + Kibana en local avec **une seule commande Docker**
- Naviguer dans **Kibana → Dev Tools → Console**
- Créer un index avec un **mapping** explicite
- Insérer / lire / modifier / supprimer des documents
- Reconnaître et **éviter le piège** du `PUT _doc/<id>` qui écrase tout
- Diagnostiquer les codes de réponse Elasticsearch (201 created, 200 OK, 404, 409 conflict)

## Pré-requis (15 min)

| # | Pré-requis                                  | Vérification rapide                                |
| - | ------------------------------------------- | -------------------------------------------------- |
| 1 | Docker Desktop installé et en cours d'exécution | `docker ps` ne renvoie pas d'erreur               |
| 2 | 4 Go de RAM libre                            | Fermer Chrome / Teams si nécessaire                |
| 3 | Avoir cloné le dépôt du cours                | `cd C:\chemin\vers\elasticsearch-1` fonctionne     |
| 4 | (Optionnel) Avoir parcouru le chapitre 13   | [`13-crud-pedagogique-kibana.md`](../13-crud-pedagogique-kibana.md) — ~15 min de lecture |

> **Pas de Docker installé ?** Suivre le **Setup A à Z** : [`solutions/00-setup-complet-a-z.md`](./solutions/00-setup-complet-a-z.md).

## Plan de la séance (90 min)

```mermaid
flowchart LR
    A["1. Demarrer la stack<br/>5 min"] --> B["2. POST vs PUT vs _create<br/>20 min"]
    B --> C["3. Update partiel<br/>15 min"]
    C --> D["4. Piege PUT _doc<br/>15 min"]
    D --> E["5. DELETE doc + index<br/>10 min"]
    E --> F["6. Exercice a rendre<br/>25 min"]
```

---

## Étape 1 — Démarrer la stack ELK

**Projet runnable dédié à cette pratique :** [`solutions/pratique-07-ch13-crud-kibana/`](./solutions/pratique-07-ch13-crud-kibana/)

```bash
cd docs2-cours1/assets-cours2/solutions/pratique-07-ch13-crud-kibana
docker compose up -d
```

Attendre ~30 secondes puis ouvrir Kibana : http://localhost:5601/app/dev_tools#/console

Vous devez voir une **console divisée en deux** : à gauche vos requêtes, à droite les réponses d'Elasticsearch.

> Tout ce qui suit se fait **dans cette console** (pas dans un terminal).

---

## Étape 2 — Comprendre POST vs PUT vs `_create`

Snippet prêt à copier-coller : [`solutions/pratique-07-ch13-crud-kibana/console/01-liste-cours.txt`](./solutions/pratique-07-ch13-crud-kibana/console/01-liste-cours.txt)

### 2.1. Préparer un index propre

```
DELETE liste_cours
PUT liste_cours
GET liste_cours
```

| Requête         | Réponse attendue                                          |
| --------------- | --------------------------------------------------------- |
| `DELETE`        | 404 si l'index n'existait pas (normal au 1er lancement) — sinon `acknowledged: true` |
| `PUT`           | `acknowledged: true, index: "liste_cours"`                |
| `GET`           | Affichage du mapping vide (pas encore de documents)       |

### 2.2. Insérer trois professeurs (3 façons différentes)

```
POST liste_cours/_doc
{ "nom_professeur": "Jean Dupon", "sigle_cours": "ABC123" }

PUT liste_cours/_doc/1
{ "nom_professeur": "Robert", "sigle_cours": "ABC456" }

POST liste_cours/_doc/2
{ "nom_professeur": "Fred Cote", "sigle_cours": "DEF123" }
```

Observez les `_id` retournés : le premier est généré automatiquement, les deux autres valent `1` et `2`.

### 2.3. Test du `_create` (refus d'écrasement)

```
PUT liste_cours/_create/1
{ "nom_professeur": "Sam Cote", "sigle_cours": "ZZZ999" }

PUT liste_cours/_create/3
{ "nom_professeur": "Albert Beau-séjour", "sigle_cours": "ABC324" }
```

| Requête | Code | Pourquoi ?                                  |
| ------- | :--: | ------------------------------------------- |
| `_create/1` | 409 | id 1 existe déjà → conflit                 |
| `_create/3` | 201 | id 3 n'existait pas → créé                 |

> **À retenir :** `_create` est l'outil idéal pour éviter d'écraser involontairement un document existant.

---

## Étape 3 — Mettre à jour un document

```
POST liste_cours/_update/1
{ "doc": { "nom_professeur": "Robert Tremblay" } }

GET liste_cours/_doc/1
```

→ Le `sigle_cours` est **préservé**, seul le nom a changé. C'est la mise à jour **partielle**.

```
POST liste_cours/_update/1
{ "doc": { "salle_cours": "salle1" } }

GET liste_cours/_doc/1
```

→ Le document a maintenant **3 champs** : `nom_professeur`, `sigle_cours` et `salle_cours`.

---

## Étape 4 — Le piège : `PUT _doc` remplace tout

```
PUT liste_cours/_doc/1
{ "nom_professeur": "Robert Tremblay" }

GET liste_cours/_doc/1
```

→ **Catastrophe** : `sigle_cours` et `salle_cours` ont **disparu** !

| Verbe pour modifier            | Comportement              |
| ------------------------------ | ------------------------- |
| `POST index/_update/<id>` + `{"doc":{...}}` | **Patch partiel**, autres champs préservés |
| `PUT index/_doc/<id>`          | **Remplacement total**, autres champs effacés |

> **Règle d'or :** dès qu'on veut juste « ajouter ou modifier un champ », on utilise **`_update`**, jamais `PUT _doc`.

---

## Étape 5 — Supprimer un document, puis l'index

```
DELETE liste_cours/_doc/1
GET liste_cours/_doc/1

DELETE liste_cours
GET liste_cours
```

| Étape                   | Réponse                                  |
| ----------------------- | ---------------------------------------- |
| `DELETE _doc/1`         | `result: "deleted"`                      |
| `GET _doc/1` après      | `"found": false`                         |
| `DELETE liste_cours`    | `acknowledged: true`                     |
| `GET liste_cours` après | `index_not_found_exception` (404)        |

---

## Étape 6 — Exercice à rendre

> Énoncé complet : voir [`Kibana - Pratique 1.docx`](./Kibana%20-%20Pratique%201.docx) — ces étapes en sont la **résolution guidée**.

### Q1 — Créer l'index `bibliotheque` et insérer un livre

```
DELETE bibliotheque
PUT bibliotheque
PUT bibliotheque/_doc/42
{ "titre": "1984", "auteur": "Orwell" }
```

### Q2 — Tenter de réinsérer le même id avec `_create`

```
PUT bibliotheque/_create/42
{ "titre": "1984", "auteur": "Orwell" }
```

**Question :** quel code de retour obtenez-vous et pourquoi ?

### Q3 — Ajouter un champ `annee: 1949` SANS écraser titre/auteur

```
POST bibliotheque/_update/42
{ "doc": { "annee": 1949 } }

GET bibliotheque/_doc/42
```

### Q4 — Insérer 3 livres sans préciser d'id

```
POST bibliotheque/_doc
{ "titre": "Le Petit Prince", "auteur": "Saint-Exupéry" }

POST bibliotheque/_doc
{ "titre": "Candide", "auteur": "Voltaire" }

POST bibliotheque/_doc
{ "titre": "Germinal", "auteur": "Zola" }
```

### Q5 — Récupérer tous les livres (titre + auteur uniquement)

```
POST bibliotheque/_refresh

GET bibliotheque/_search
{ "_source": ["titre","auteur"], "size": 100 }
```

### Q6 — Nettoyer : supprimer le doc 42 puis l'index

```
DELETE bibliotheque/_doc/42
DELETE bibliotheque
```

> **Solution complète à comparer** : [`solutions/pratique-07-ch13-crud-kibana/console/02-bibliotheque-exercices.txt`](./solutions/pratique-07-ch13-crud-kibana/console/02-bibliotheque-exercices.txt)

---

## Livrable et critères d'évaluation

### Quoi remettre

| Élément                                              | Format                                   | Pondération |
| ---------------------------------------------------- | ---------------------------------------- | :---------: |
| **Captures d'écran de la console Kibana** pour les 6 questions | PDF ou ZIP d'images                  |    60 %     |
| **Court rapport** (1 page) : ce que vous avez compris sur PUT vs POST vs `_create` vs `_update` | PDF                                      |    25 %     |
| **Section piège** : reproduisez le piège du `PUT _doc/1` et expliquez en 3 lignes pourquoi c'est dangereux en production | Inclus dans le rapport                |    15 %     |

### Grille rapide

| Critère                                          | Points |
| ------------------------------------------------ | :----: |
| Index `bibliotheque` créé correctement (Q1)      |   2    |
| `_create` correctement testé et expliqué (Q2)    |   3    |
| Update partiel sans écrasement (Q3)              |   3    |
| 3 docs sans id, tous lisibles (Q4-Q5)            |   3    |
| Cleanup propre (Q6)                              |   1    |
| Explication du piège PUT _doc                    |   3    |
| Soin du rapport (capture, ortho, structure)      |   5    |
| **Total**                                        | **20** |

---

## Aide rapide / FAQ étudiants

<details>
<summary><strong>Kibana est très lent ou ne répond pas (page blanche)</strong></summary>

Patienter 30-60 s après `docker compose up -d`. Kibana est plus lent à démarrer que ES.

```bash
docker compose logs -f kibana
```

Si toujours bloqué après 2 min : `docker compose down -v && docker compose up -d`.

</details>

<details>
<summary><strong>Erreur 405 « Method Not Allowed » sur PUT _doc</strong></summary>

Vous avez tenté `PUT liste_cours/_doc` **sans préciser l'id**. C'est interdit. Utilisez :
- `POST liste_cours/_doc` (auto-id), ou
- `PUT liste_cours/_doc/<un_id>`.

</details>

<details>
<summary><strong>409 Conflict sur _create</strong></summary>

C'est le comportement attendu : `_create` refuse d'écraser. Utiliser `PUT _doc/<id>` si vous voulez vraiment remplacer.

</details>

<details>
<summary><strong>Mon GET ne renvoie pas les docs juste insérés</strong></summary>

Faire `POST <index>/_refresh` avant le `_search`. Par défaut, Elasticsearch ne « publie » les nouveaux documents que toutes les 1 s.

</details>

<details>
<summary><strong>J'ai supprimé l'index par erreur</strong></summary>

Pas de panique : tout est local et reproductible. Recréez l'index, réinsérez les docs en 30 s. **C'est exactement pour ça qu'on apprend ces commandes en local et pas en production.**

</details>

---

## Pour aller plus loin

| Ressource                                                                                | Quand l'utiliser                            |
| ---------------------------------------------------------------------------------------- | ------------------------------------------- |
| [Cours chapitre 13 — CRUD pédagogique](../13-crud-pedagogique-kibana.md)                 | Lecture théorique posée, schémas, analogies SQL |
| [Solution détaillée Markdown](./solutions/pratique-07-solutions-crud-pedagogique.md)              | Toutes les variantes, plus de pièges, scripts |
| [Projet runnable `pratique-07-ch13-crud-kibana/`](./solutions/pratique-07-ch13-crud-kibana/)                     | Compose + 3 fichiers `console/*.txt` prêts à coller |
| [Énoncé officiel du prof (.docx)](./Kibana%20-%20Pratique%201.docx)                       | Référence d'autorité pour la notation       |

> **Vous avez fini la Pratique 1 ?** Enchaînez avec le [**Guide Pratique 2**](./GUIDE-PRATIQUE-2.md) (Search API + DSL).

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
